-- ============================================================================
-- SevaSetu: Hyperlocal Services Marketplace
-- Seed Data for Supabase (PostgreSQL)
-- ============================================================================
-- NOTE:
-- All profiles below are demo sample profiles mirroring index.html.
-- NO real personal data is stored (no real names, addresses, or phone numbers).
-- No entries are placed in worker_private.
-- ============================================================================

INSERT INTO workers (
    id,
    name,
    category,
    locality,
    experience_years,
    hourly_rate,
    travel_charge,
    is_available,
    skills,
    rating,
    review_count,
    verification_status,
    is_demo,
    is_hidden
)
VALUES
    ('w1', 'Ravi Kumar', 'Electrician', 'North Colony', 8, 300, 40, true, 'Fan, wiring, switchboards', 4.60, 31, 'Demo profile', true, false),
    ('w2', 'Selvi Devi', 'Cleaner', 'Lake View', 5, 180, 30, true, 'Deep cleaning, kitchens, bathrooms', 4.80, 52, 'Demo profile', true, false),
    ('w3', 'Imran Shaikh', 'Plumber', 'Market Road', 11, 350, 50, true, 'Leaks, taps, tank fittings', 4.40, 27, 'Demo profile', true, false),
    ('w4', 'Mohan Das', 'Painter', 'Station Area', 14, 400, 60, false, 'Interior walls, waterproofing', 4.50, 19, 'Demo profile', true, false),
    ('w5', 'Anita Joseph', 'Carpenter', 'North Colony', 9, 380, 40, true, 'Doors, shelves, furniture repair', 4.70, 23, 'Demo profile', true, false),
    ('w6', 'Karthik R', 'Appliance repair', 'Lake View', 6, 320, 40, true, 'Washing machine, fridge, mixer', 4.30, 35, 'Demo profile', true, false),
    ('w7', 'Latha Sundar', 'Electrician', 'Station Area', 3, 260, 30, true, 'Lights, inverter wiring', 4.10, 8, 'Demo profile', true, false),
    ('w8', 'Faizal Ahmed', 'Plumber', 'North Colony', 2, 280, 30, true, 'Basic plumbing, bathroom fittings', 0.00, 0, 'Unverified', false, false),
    ('w9', 'Meena Kumari', 'Maid', 'Lake View', 7, 120, 20, true, 'Daily cleaning, utensils, laundry', 4.50, 14, 'Demo profile', true, false),
    ('w10', 'Suresh Babu', 'Cook', 'Market Road', 10, 200, 20, true, 'Home-style meals, tiffin prep', 4.60, 12, 'Demo profile', true, false)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    locality = EXCLUDED.locality,
    experience_years = EXCLUDED.experience_years,
    hourly_rate = EXCLUDED.hourly_rate,
    travel_charge = EXCLUDED.travel_charge,
    is_available = EXCLUDED.is_available,
    skills = EXCLUDED.skills,
    rating = EXCLUDED.rating,
    review_count = EXCLUDED.review_count,
    verification_status = EXCLUDED.verification_status,
    is_demo = EXCLUDED.is_demo,
    is_hidden = EXCLUDED.is_hidden;
