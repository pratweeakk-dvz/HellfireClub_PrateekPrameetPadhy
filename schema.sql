-- ============================================================================
-- SevaSetu: Hyperlocal Services Marketplace
-- Database Schema for Supabase (PostgreSQL)
-- ============================================================================
-- NOTE: This schema is designed for a hackathon prototype / demo.
-- No real secrets, real identity verification, or real payments are used.
-- The Aadhaar verification flow is strictly simulated ("Sample verification (demo)").
-- ============================================================================

-- ============================================================================
-- 1. EXTENSIONS, CLEANUP, SEQUENCES & HELPER FUNCTIONS (NO TABLE REFERENCES)
-- ============================================================================

-- Enable pgcrypto extension if needed for UUIDs or cryptographic helpers
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Safe re-run cleanup:
-- Drop tables with CASCADE first. In PostgreSQL, dropping a table CASCADE
-- automatically removes all triggers, policies, and foreign keys on that table,
-- without failing if the table does not exist on a fresh database.
DROP TABLE IF EXISTS reports CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS quotes CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS worker_private CASCADE;
DROP TABLE IF EXISTS workers CASCADE;

-- Drop standalone functions and sequences safely
DROP FUNCTION IF EXISTS validate_booking_status_transition() CASCADE;
DROP FUNCTION IF EXISTS update_worker_rating_on_review() CASCADE;
DROP SEQUENCE IF EXISTS booking_id_seq CASCADE;

-- Human-readable booking ID sequence (e.g. SS-2026-000001)
CREATE SEQUENCE booking_id_seq START WITH 1;


-- ============================================================================
-- 2. CREATE TABLE STATEMENTS
-- (Order: workers -> worker_private -> bookings -> quotes -> reviews -> reports)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 Workers Table (Public Profiles)
-- Stores non-sensitive, publicly browsable worker details.
-- ----------------------------------------------------------------------------
CREATE TABLE workers (
    id TEXT PRIMARY KEY,                           -- Unique ID (e.g. 'w1', 'w2', or generated)
    name TEXT NOT NULL,                            -- Full name displayed to customers
    category TEXT NOT NULL,                        -- Service category (e.g. Electrician, Plumber)
    locality TEXT NOT NULL,                        -- Area served (e.g. North Colony, Lake View)
    experience_years INT NOT NULL DEFAULT 0,       -- Years of experience
    hourly_rate NUMERIC NOT NULL CHECK (hourly_rate >= 50), -- Labour rate per hour in INR (min ₹50)
    travel_charge NUMERIC NOT NULL DEFAULT 30 CHECK (travel_charge >= 0), -- Base travel fee in INR
    is_available BOOLEAN NOT NULL DEFAULT true,    -- Toggle for worker availability
    skills TEXT NOT NULL,                          -- Summary of skills / services offered
    rating NUMERIC(3, 2) NOT NULL DEFAULT 0.00,    -- Running average rating (e.g. 4.60)
    review_count INT NOT NULL DEFAULT 0,           -- Count of reviews received
    verification_status TEXT NOT NULL DEFAULT 'Unverified'
        CHECK (verification_status IN ('Demo profile', 'Demo verified', 'Unverified')),
    is_demo BOOLEAN NOT NULL DEFAULT false,        -- Flag indicating sample / demo profile
    is_hidden BOOLEAN NOT NULL DEFAULT false,      -- Admin flag to hide profile from search
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_workers_cat_loc ON workers (category, locality) WHERE is_hidden = false;
CREATE INDEX idx_workers_avail ON workers (is_available) WHERE is_hidden = false;

-- ----------------------------------------------------------------------------
-- 2.2 Worker Private Table (Sensitive Details)
-- CRITICAL PRIVACY RULE:
-- A worker's home address and mobile number must NEVER be readable by customers.
-- Full Aadhaar is NEVER stored; only the last 4 digits are saved for verification reference.
-- ----------------------------------------------------------------------------
CREATE TABLE worker_private (
    worker_id TEXT PRIMARY KEY REFERENCES workers(id) ON DELETE CASCADE,
    home_address TEXT NOT NULL,                    -- Worker's private residential address
    aadhaar_last4 CHAR(4) NOT NULL CHECK (aadhaar_last4 ~ '^[0-9]{4}$'), -- ONLY last 4 digits
    mobile_number VARCHAR(15) NOT NULL CHECK (mobile_number ~ '^[0-9]{10}$'), -- Private mobile number
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 2.3 Bookings Table
-- Tracks the customer booking lifecycle with a human-readable identifier.
-- Valid statuses:
--   - requested:   Initial request sent by customer
--   - accepted:    Worker accepted the job request
--   - quoted:      Worker submitted an itemised price quote
--   - negotiating: Customer requested a revised quote
--   - approved:    Customer accepted the quote; job can commence
--   - completed:   Worker completed the job (demo)
--   - rejected:    Worker declined the initial request
--   - cancelled:   Customer cancelled the booking
-- ----------------------------------------------------------------------------
CREATE TABLE bookings (
    id TEXT PRIMARY KEY DEFAULT ('SS-2026-' || LPAD(nextval('booking_id_seq')::TEXT, 6, '0')),
    worker_id TEXT NOT NULL REFERENCES workers(id) ON DELETE RESTRICT,
    category TEXT NOT NULL,
    description TEXT NOT NULL CHECK (length(description) >= 10),
    locality TEXT NOT NULL,
    booking_time TEXT NOT NULL,                    -- 'ASAP' or ISO timestamp string
    status TEXT NOT NULL DEFAULT 'requested'
        CHECK (status IN ('requested', 'accepted', 'quoted', 'negotiating', 'approved', 'completed', 'rejected', 'cancelled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_bookings_worker ON bookings (worker_id);
CREATE INDEX idx_bookings_status ON bookings (status);

-- ----------------------------------------------------------------------------
-- 2.4 Quotes Table (Versioned)
-- Provides full price transparency with itemised labour, materials, and travel.
-- Each revision increments the version number.
-- ----------------------------------------------------------------------------
CREATE TABLE quotes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id TEXT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    version INT NOT NULL DEFAULT 1 CHECK (version >= 1),
    labour_charge NUMERIC NOT NULL CHECK (labour_charge > 0),
    materials_charge NUMERIC NOT NULL DEFAULT 0 CHECK (materials_charge >= 0),
    travel_charge NUMERIC NOT NULL DEFAULT 0 CHECK (travel_charge >= 0),
    note TEXT,                                     -- Worker explanation of materials or work
    revision_request TEXT,                         -- Customer's ask if negotiating revision
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_booking_quote_version UNIQUE (booking_id, version)
);

CREATE INDEX idx_quotes_booking ON quotes (booking_id);

-- ----------------------------------------------------------------------------
-- 2.5 Reviews Table
-- Ratings and feedback submitted by customers after job completion.
-- ----------------------------------------------------------------------------
CREATE TABLE reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id TEXT NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    worker_id TEXT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL CHECK (length(comment) >= 3),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reviews_worker ON reviews (worker_id);

-- ----------------------------------------------------------------------------
-- 2.6 Reports Table (Complaints & Safety)
-- Safety mechanism: Customers or workers can report issues.
-- ----------------------------------------------------------------------------
CREATE TABLE reports (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id TEXT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    issue_text TEXT NOT NULL CHECK (length(issue_text) >= 10),
    status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'Resolved')),
    resolution_note TEXT,                          -- Admin note when resolving issue
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_reports_status ON reports (status);


-- ============================================================================
-- 3. TRIGGERS AND FUNCTIONS THAT USE THOSE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Trigger 1: Status Transition Validator
-- Enforces the SevaSetu booking lifecycle state machine:
--   requested   -> accepted / rejected / cancelled
--   accepted    -> quoted / cancelled
--   quoted      -> approved / negotiating / cancelled
--   negotiating -> quoted / cancelled
--   approved    -> completed
-- Any other status change is strictly rejected with a database exception.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_booking_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- Only evaluate when the status value is actually being modified
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        IF OLD.status = 'requested' AND NEW.status IN ('accepted', 'rejected', 'cancelled') THEN
            NEW.updated_at = now();
            RETURN NEW;
        ELSIF OLD.status = 'accepted' AND NEW.status IN ('quoted', 'cancelled') THEN
            NEW.updated_at = now();
            RETURN NEW;
        ELSIF OLD.status = 'quoted' AND NEW.status IN ('approved', 'negotiating', 'cancelled') THEN
            NEW.updated_at = now();
            RETURN NEW;
        ELSIF OLD.status = 'negotiating' AND NEW.status IN ('quoted', 'cancelled') THEN
            NEW.updated_at = now();
            RETURN NEW;
        ELSIF OLD.status = 'approved' AND NEW.status = 'completed' THEN
            NEW.updated_at = now();
            RETURN NEW;
        ELSE
            RAISE EXCEPTION 'Invalid booking status transition: cannot change status from "%" to "%"', OLD.status, NEW.status
                USING ERRCODE = 'check_violation';
        END IF;
    END IF;

    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_booking_status
BEFORE UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION validate_booking_status_transition();

-- ----------------------------------------------------------------------------
-- Trigger 2: Automatic Worker Rating Recalculation
-- Keeps worker rating and review count synchronized upon new review submission.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_worker_rating_on_review()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE workers
    SET rating = ROUND(((rating * review_count) + NEW.rating)::NUMERIC / (review_count + 1), 2),
        review_count = review_count + 1
    WHERE id = NEW.worker_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_worker_rating
AFTER INSERT ON reviews
FOR EACH ROW
EXECUTE FUNCTION update_worker_rating_on_review();


-- ============================================================================
-- 4. ALTER TABLE ... ENABLE ROW LEVEL SECURITY
-- ============================================================================
-- Enable RLS on every table
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE worker_private ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;


-- ============================================================================
-- 5. CREATE POLICY STATEMENTS
-- ============================================================================
-- ARCHITECTURAL NOTE:
-- In this hackathon demo, the frontend has no real user authentication (no login).
-- Demo policies allow the public anonymous role (`anon`) to perform demo actions
-- while keeping worker_private locked down.
--
-- PRODUCTION REQUIREMENT:
-- In production, Supabase Auth (e.g. Phone OTP or Email Magic Link) MUST be enabled.
-- Policies must then restrict reads and writes based on `auth.uid()`:
--   - workers: editable only by the authenticated worker matching auth.uid()
--   - worker_private: SELECT and UPDATE restricted strictly to auth.uid() = worker_id
--     or authorized administrative service roles. Customers must NEVER have SELECT.
--   - bookings: visible only to customer_id = auth.uid() OR worker_id = auth.uid().
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 5.1 Workers Table Policies
-- Anyone can browse active workers that are not marked as hidden.
-- Anyone can register or toggle availability in demo mode.
-- ----------------------------------------------------------------------------
CREATE POLICY "Demo: anyone can read non-hidden workers"
    ON workers FOR SELECT
    USING (is_hidden = false);

CREATE POLICY "Demo: anyone can register worker profile"
    ON workers FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Demo: anyone can update worker profile in demo"
    ON workers FOR UPDATE
    USING (true);

-- ----------------------------------------------------------------------------
-- 5.2 Worker Private Table Policies
-- PRIVACY ENFORCEMENT:
-- - Allows INSERT only (so self-registration can store verification details).
-- - NO SELECT policy is defined: anonymous and regular clients can NEVER read
--   another worker's mobile number, home address, or Aadhaar last 4.
-- - NO UPDATE or DELETE policies are granted to the public role.
-- ----------------------------------------------------------------------------
CREATE POLICY "Demo: allow insert of private worker details on registration"
    ON worker_private FOR INSERT
    WITH CHECK (true);

-- Explicit note: NO SELECT policy created for worker_private.
-- Any attempt by the client to query `SELECT * FROM worker_private` returns 0 rows.

-- ----------------------------------------------------------------------------
-- 5.3 Bookings Table Policies
-- In demo mode, anyone can create, view, and transition bookings.
-- ----------------------------------------------------------------------------
CREATE POLICY "Demo: anyone can view bookings"
    ON bookings FOR SELECT
    USING (true);

CREATE POLICY "Demo: anyone can create bookings"
    ON bookings FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Demo: anyone can update bookings"
    ON bookings FOR UPDATE
    USING (true);

-- ----------------------------------------------------------------------------
-- 5.4 Quotes Table Policies
-- Versioned quotes are readable and creatable by demo users.
-- ----------------------------------------------------------------------------
CREATE POLICY "Demo: anyone can view quotes"
    ON quotes FOR SELECT
    USING (true);

CREATE POLICY "Demo: anyone can create quotes"
    ON quotes FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Demo: anyone can update quotes"
    ON quotes FOR UPDATE
    USING (true);

-- ----------------------------------------------------------------------------
-- 5.5 Reviews Table Policies
-- Completed job reviews are public for transparency.
-- ----------------------------------------------------------------------------
CREATE POLICY "Demo: anyone can read reviews"
    ON reviews FOR SELECT
    USING (true);

CREATE POLICY "Demo: anyone can submit reviews"
    ON reviews FOR INSERT
    WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- 5.6 Reports Table Policies
-- Customers can submit reports; admin dashboard can review and resolve them.
-- ----------------------------------------------------------------------------
CREATE POLICY "Demo: anyone can view reports"
    ON reports FOR SELECT
    USING (true);

CREATE POLICY "Demo: anyone can create reports"
    ON reports FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Demo: anyone can update reports (admin resolution)"
    ON reports FOR UPDATE
    USING (true);
