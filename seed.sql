-- ============================================================================
-- SevaSetu: Hyperlocal Services Marketplace
-- Seed Data for Supabase (PostgreSQL)
-- ============================================================================
-- NOTE:
-- All profiles below are demo sample profiles mirroring index.html.
-- NO real personal data is stored (no real names, addresses, or phone numbers).
-- No entries are placed in worker_private.
-- Re-run safe with ON CONFLICT (id) DO UPDATE.
-- Task F: seed now includes the tasks[] column for House help workers.
-- Task E: 10 House help workers with varied tasks (2 senior care, 2 baby care).
-- ============================================================================

INSERT INTO workers (
    id,
    name,
    category,
    locality,
    experience_years,
    base_rate,
    rate_unit,
    hourly_rate,
    travel_charge,
    is_available,
    skills,
    rating,
    review_count,
    verification_status,
    is_demo,
    is_hidden,
    tasks
)
VALUES
    -- Non-House-help workers (tasks = empty array)
    ('w1',  'Ravi Kumar',    'Electrician',     'North Colony', 8,  300, 'per_hour', 300, 40, true,  'Fan, wiring, switchboards',                                        4.60, 31, 'Demo profile', true,  false, '{}'),
    ('w3',  'Imran Shaikh',  'Plumber',         'Market Road',  11, 350, 'per_hour', 350, 50, true,  'Leaks, taps, tank fittings, drainage',                             4.40, 27, 'Demo profile', true,  false, '{}'),
    ('w4',  'Mohan Das',     'Painter',         'Station Area', 14, 500, 'per_day',  500, 60, false, 'Interior walls, waterproofing',                                    4.50, 19, 'Demo profile', true,  false, '{}'),
    ('w5',  'Anita Joseph',  'Carpenter',       'North Colony', 9,  380, 'per_hour', 380, 40, true,  'Doors, shelves, furniture repair',                                 4.70, 23, 'Demo profile', true,  false, '{}'),
    ('w6',  'Karthik R',     'Appliance repair','Lake View',    6,  350, 'per_visit',350, 40, true,  'Washing machine, fridge, mixer',                                   4.30, 35, 'Demo profile', true,  false, '{}'),
    ('w7',  'Latha Sundar',  'Electrician',     'Station Area', 3,  260, 'per_hour', 260, 30, true,  'Lights, inverter wiring',                                          4.10,  8, 'Demo profile', true,  false, '{}'),
    ('w8',  'Faizal Ahmed',  'Plumber',         'North Colony', 2,  280, 'per_hour', 280, 30, true,  'Basic plumbing, bathroom fittings',                                0.00,  0, 'Unverified',   false, false, '{}'),
    -- House help workers (Task E: 10 workers with varied tasks)
    ('w2',  'Selvi Devi',    'House help', 'Lake View',    5,  250, 'per_visit', 250, 30, true,  'Maid & deep cleaning: kitchens, bathrooms, floors',
     4.80, 52, 'Demo profile', true, false,
     '{Sweeping and mopping,Bathroom cleaning,Kitchen cleaning,Dusting,Utensil cleaning}'),
    ('w9',  'Meena Kumari',  'House help', 'Lake View',    7,  180, 'per_visit', 180, 20, true,  'Maid: daily cleaning, utensils, laundry, dusting',
     4.50, 14, 'Demo profile', true, false,
     '{Dish washing,Sweeping and mopping,Clothes washing,Clothes drying and folding,Dusting,Utensil cleaning}'),
    ('w10', 'Suresh Babu',   'House help', 'Market Road',  10, 300, 'per_visit', 300, 20, true,  'Cook: North & South Indian home meals, tiffin prep',
     4.60, 12, 'Demo profile', true, false,
     '{Cook full meals,Tiffin / meal prep,Breakfast only,Vegetarian only}'),
    ('w11', 'Sunita Bai',    'House help', 'North Colony', 6,  200, 'per_visit', 200, 25, true,  'All-rounder maid: sweeping, veg prep, helper',
     4.70, 29, 'Demo profile', true, false,
     '{Sweeping and mopping,Dish washing,Utensil cleaning,Snacks and tea,Grocery shopping}'),
    ('w12', 'Kalyani Rao',   'House help', 'Station Area', 4,  220, 'per_visit', 220, 25, true,  'Ironing, laundry, light cooking',
     4.30,  9, 'Demo profile', true, false,
     '{Ironing,Clothes washing,Clothes drying and folding,Breakfast only}'),
    -- Senior care workers (2 of them, Task E)
    ('w13', 'Parvathi Nair', 'House help', 'North Colony', 12, 400, 'per_day',   400, 30, true,  'Senior care: companionship, medicine reminders, hospital escort',
     4.90, 18, 'Demo profile', true, false,
     '{"Senior care – companionship, medicine reminders, help with walking and bathing, hospital visits"}'),
    ('w14', 'Rosy Thomas',   'House help', 'Lake View',    8,  350, 'per_day',   350, 30, true,  'Senior care and light housekeeping',
     4.60, 11, 'Demo profile', true, false,
     '{"Senior care – companionship, medicine reminders, help with walking and bathing, hospital visits",Sweeping and mopping,Dusting}'),
    -- Baby care workers (2 of them, Task E)
    ('w15', 'Deepa Menon',   'House help', 'Market Road',  5,  300, 'per_day',   300, 35, true,  'Baby sitting (day & night), feeding, child care',
     4.80, 22, 'Demo profile', true, false,
     '{Baby sitting (day),Baby sitting (night),Feeding and play}'),
    ('w16', 'Jyothi Pillai', 'House help', 'Station Area', 6,  280, 'per_day',   280, 30, false, 'Baby sitting, child pick-up and drop, play activities',
     4.50, 16, 'Demo profile', true, false,
     '{Baby sitting (day),Child pick-up and drop,Feeding and play}'),
    -- Full-service maid
    ('w17', 'Geetha Iyer',   'House help', 'North Colony', 9,  260, 'per_visit', 260, 20, true,  'Full-service maid: cleaning, cooking, grocery',
     4.40,  7, 'Demo profile', true, false,
     '{Sweeping and mopping,Bathroom cleaning,Kitchen cleaning,Cook full meals,Grocery shopping,Dish washing}')
ON CONFLICT (id) DO UPDATE SET
    name               = EXCLUDED.name,
    category           = EXCLUDED.category,
    locality           = EXCLUDED.locality,
    experience_years   = EXCLUDED.experience_years,
    base_rate          = EXCLUDED.base_rate,
    rate_unit          = EXCLUDED.rate_unit,
    hourly_rate        = EXCLUDED.hourly_rate,
    travel_charge      = EXCLUDED.travel_charge,
    is_available       = EXCLUDED.is_available,
    skills             = EXCLUDED.skills,
    rating             = EXCLUDED.rating,
    review_count       = EXCLUDED.review_count,
    verification_status= EXCLUDED.verification_status,
    is_demo            = EXCLUDED.is_demo,
    is_hidden          = EXCLUDED.is_hidden,
    tasks              = EXCLUDED.tasks;
