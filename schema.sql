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
CREATE SEQUENCE IF NOT EXISTS booking_id_seq START WITH 1;


-- ============================================================================
-- 2. CREATE TABLE STATEMENTS
-- (Order: workers -> worker_private -> bookings -> quotes -> reviews -> reports)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 Workers Table (Public Profiles)
-- Stores non-sensitive, publicly browsable worker details.
-- Supports Phase 1-2 features:
--   - 'House help' category (alongside Electrician, Plumber, Painter, Carpenter, Appliance repair)
--   - Base rate with customizable rate unit (per_hour, per_visit, per_day)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS workers (
    id TEXT PRIMARY KEY,                           -- Unique ID (e.g. 'w1', 'w2', or generated)
    name TEXT NOT NULL,                            -- Full name displayed to customers
    category TEXT NOT NULL,                        -- Service category (House help, Electrician, Plumber, etc.)
    locality TEXT NOT NULL,                        -- Area served (e.g. North Colony, Lake View)
    experience_years INT NOT NULL DEFAULT 0,       -- Years of experience
    base_rate NUMERIC NOT NULL CHECK (base_rate >= 50), -- Base labour rate in INR (min ₹50)
    rate_unit TEXT NOT NULL DEFAULT 'per_hour'
        CHECK (rate_unit IN ('per_hour', 'per_visit', 'per_day')), -- Unit: /hour, /visit, /day
    hourly_rate NUMERIC NOT NULL DEFAULT 50 CHECK (hourly_rate >= 50), -- Backward compatibility field
    travel_charge NUMERIC NOT NULL DEFAULT 30 CHECK (travel_charge >= 0), -- Base travel fee in INR
    is_available BOOLEAN NOT NULL DEFAULT true,    -- Toggle for worker availability
    skills TEXT NOT NULL,                          -- Summary of skills / services offered
    rating NUMERIC(3, 2) NOT NULL DEFAULT 0.00,    -- Running average rating (e.g. 4.60)
    review_count INT NOT NULL DEFAULT 0,           -- Count of reviews received
    verification_status TEXT NOT NULL DEFAULT 'Unverified'
        CHECK (verification_status IN ('Demo profile', 'Demo verified', 'Unverified')),
    is_demo BOOLEAN NOT NULL DEFAULT false,        -- Flag indicating sample / demo profile
    is_hidden BOOLEAN NOT NULL DEFAULT false,      -- Admin flag to hide profile from search
    -- Task F: tasks offered by this worker (House help category uses a checklist)
    tasks TEXT[] NOT NULL DEFAULT '{}',            -- Array of task labels, e.g. '{"Sweeping and mopping","Cooking"}'
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Task F: safe migration for databases that were created before this column was added
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='workers' AND column_name='tasks'
  ) THEN
    ALTER TABLE workers ADD COLUMN tasks TEXT[] NOT NULL DEFAULT '{}';
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_workers_cat_loc ON workers (category, locality) WHERE is_hidden = false;
CREATE INDEX IF NOT EXISTS idx_workers_avail ON workers (is_available) WHERE is_hidden = false;

-- ----------------------------------------------------------------------------
-- 2.2 Worker Private Table (Sensitive Details)
-- CRITICAL PRIVACY RULE:
-- A worker's home address and mobile number must NEVER be readable by customers.
-- Full Aadhaar is NEVER stored; only the last 4 digits are saved for verification reference.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS worker_private (
    worker_id TEXT PRIMARY KEY REFERENCES workers(id) ON DELETE CASCADE,
    home_address TEXT NOT NULL,                    -- Worker's private residential address
    aadhaar_last4 CHAR(4) NOT NULL CHECK (aadhaar_last4 ~ '^[0-9]{4}$'), -- ONLY last 4 digits
    mobile_number VARCHAR(15) NOT NULL CHECK (mobile_number ~ '^[0-9]{10}$'), -- Private mobile number
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- 2.3 Bookings Table
-- Tracks the customer booking lifecycle with a human-readable identifier.
-- Supports Phase 2 agreed price locking (agreed_total, agreed_breakdown).
-- Valid statuses:
--   - requested:   Initial request sent by customer
--   - accepted:    Worker accepted the job request
--   - quoted:      Worker submitted an itemised price quote
--   - negotiating: Customer or worker submitted a counter-offer (up to 3 rounds)
--   - approved:    Agreed price locked and approved
--   - completed:   Worker completed the job (demo)
--   - rejected:    Worker declined the request or counter-offer
--   - cancelled:   Customer cancelled the booking
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bookings (
    id TEXT PRIMARY KEY DEFAULT ('SS-2026-' || LPAD(nextval('booking_id_seq')::TEXT, 6, '0')),
    worker_id TEXT NOT NULL REFERENCES workers(id) ON DELETE RESTRICT,
    category TEXT NOT NULL,
    description TEXT NOT NULL CHECK (length(description) >= 10),
    locality TEXT NOT NULL,
    booking_time TEXT NOT NULL,                    -- 'ASAP' or ISO timestamp string
    status TEXT NOT NULL DEFAULT 'requested'
        CHECK (status IN ('requested', 'accepted', 'quoted', 'negotiating', 'approved', 'completed', 'rejected', 'cancelled')),
    agreed_total NUMERIC CHECK (agreed_total IS NULL OR agreed_total > 0), -- Final agreed price locked in INR
    agreed_breakdown JSONB,                        -- Itemised locked breakdown {labor, mat, travel, agreedAt}
    -- Task F: tasks requested by customer at booking time (House help)
    tasks_requested TEXT[] NOT NULL DEFAULT '{}', -- Array of task labels from the checklist
    frequency TEXT NOT NULL DEFAULT 'one-time'
        CHECK (frequency IN ('one-time', 'daily', 'weekly')), -- Recurrence for House help bookings
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Task F: safe migration for databases that were created before these columns were added
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='bookings' AND column_name='tasks_requested'
  ) THEN
    ALTER TABLE bookings ADD COLUMN tasks_requested TEXT[] NOT NULL DEFAULT '{}';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='bookings' AND column_name='frequency'
  ) THEN
    ALTER TABLE bookings ADD COLUMN frequency TEXT NOT NULL DEFAULT 'one-time'
      CHECK (frequency IN ('one-time','daily','weekly'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_bookings_worker ON bookings (worker_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings (status);

-- ----------------------------------------------------------------------------
-- 2.4 Quotes Table (Versioned & Negotiable)
-- Provides full price transparency with itemised labour, materials, and travel.
-- Supports Phase 2 bargaining rounds (up to 3 rounds) and counter-offers.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS quotes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id TEXT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    version INT NOT NULL DEFAULT 1 CHECK (version >= 1),
    round_number INT NOT NULL DEFAULT 1 CHECK (round_number >= 1 AND round_number <= 3), -- Max 3 negotiation rounds
    offered_by TEXT NOT NULL DEFAULT 'worker' CHECK (offered_by IN ('worker', 'customer')),
    labour_charge NUMERIC NOT NULL CHECK (labour_charge > 0),
    materials_charge NUMERIC NOT NULL DEFAULT 0 CHECK (materials_charge >= 0),
    travel_charge NUMERIC NOT NULL DEFAULT 0 CHECK (travel_charge >= 0),
    total_estimate NUMERIC NOT NULL DEFAULT 0 CHECK (total_estimate >= 0),
    note TEXT,                                     -- Explanation of materials or scope
    revision_request TEXT,                         -- Note attached to counter-offer
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_booking_quote_version UNIQUE (booking_id, version)
);

CREATE INDEX IF NOT EXISTS idx_quotes_booking ON quotes (booking_id);

-- ----------------------------------------------------------------------------
-- 2.5 Reviews Table
-- Ratings and feedback submitted by customers after job completion.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reviews (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id TEXT NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    worker_id TEXT NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL CHECK (length(comment) >= 3),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reviews_worker ON reviews (worker_id);

-- ----------------------------------------------------------------------------
-- 2.6 Reports Table (Complaints & Safety)
-- Safety mechanism: Customers or workers can report issues.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS reports (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    booking_id TEXT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    issue_text TEXT NOT NULL CHECK (length(issue_text) >= 10),
    status TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open', 'Resolved')),
    resolution_note TEXT,                          -- Admin note when resolving issue
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON reports (status);


-- ============================================================================
-- 3. TRIGGERS AND FUNCTIONS THAT USE THOSE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Trigger 1: Status Transition Validator
-- Enforces the SevaSetu booking lifecycle state machine (including Phase 2 bargaining):
--   requested   -> accepted / rejected / cancelled
--   accepted    -> quoted / cancelled
--   quoted      -> approved / negotiating / cancelled
--   negotiating -> approved (accept counter) / quoted (counter back) / rejected / cancelled
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
        ELSIF OLD.status = 'negotiating' AND NEW.status IN ('approved', 'quoted', 'rejected', 'cancelled') THEN
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
-- Enable RLS on every table to guarantee data security at the database engine level.
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE worker_private ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;


-- ============================================================================
-- 5. CREATE POLICY STATEMENTS (ROW LEVEL SECURITY)
-- ============================================================================
-- ROW LEVEL SECURITY ARCHITECTURAL NOTES:
-- 1. In this hackathon demo, the frontend uses the publishable anon key.
-- 2. CRITICAL PRIVACY GUARANTEE:
--    - worker_private: Only INSERT is granted to the public/anon role (for registration).
--      NO SELECT policy is granted on worker_private. Thus, NO customer, anonymous client,
--      or normal user can ever read full addresses, phone numbers, or Aadhaar numbers.
-- 3. Public read transparency:
--    - workers: public reads allowed where is_hidden = false.
--    - bookings, quotes, reviews, reports: open for demo testing, with strict state machine
--      triggers preventing invalid status tampering.
-- 4. Production migration:
--    - When Supabase Auth is enabled, replace open USING (true) with auth.uid() checks:
--      workers (auth.uid() = id), worker_private (auth.uid() = worker_id),
--      bookings (auth.uid() = customer_id OR auth.uid() = worker_id).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 5.1 Workers Table Policies
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

-- Explicit security guarantee: NO SELECT policy created for worker_private.
-- Any client attempt to query `SELECT * FROM worker_private` returns 0 rows.

-- ----------------------------------------------------------------------------
-- 5.3 Bookings Table Policies
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
-- ----------------------------------------------------------------------------
CREATE POLICY "Demo: anyone can read reviews"
    ON reviews FOR SELECT
    USING (true);

CREATE POLICY "Demo: anyone can submit reviews"
    ON reviews FOR INSERT
    WITH CHECK (true);

-- ----------------------------------------------------------------------------
-- 5.6 Reports Table Policies
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
