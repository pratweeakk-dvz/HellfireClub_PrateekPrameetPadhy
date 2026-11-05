# SevaSetu Prototype Changelog

## Phase 1: Design, Logo, House Help & Mobile Navigation

### What changed:
- **House Help Category**: Added "House help" as a first-class trade category covering maids, cooks, and cleaners (`🧹`). Added 4 demo house help workers (`w2` Selvi Devi, `w9` Meena Kumari, `w10` Suresh Babu, `w11` Sunita Bai) with skills in deep cleaning, home-style meal prep, and daily housekeeping.
- **Mobile-First Bottom Tab Bar**: Fixed bottom tab bar (`#tabs`) with safe-area support, active tab indicator, and role-based navigation (Find, Map, Bookings, Impact, or Guest Home/Find/Join/About). Touch targets are enlarged to a minimum of 48px/56px.
- **Avatar Worker Cards**: Responsive cards with circular category-tinted initial avatars (`.av`), availability status indicators with live dot badges, and clear hourly/visit pricing.
- **Inline SVG Logo**: Standalone SVG mark and brand lockup ("SevaSetu – Trust for every home, Work for every hand") in the header without external image dependencies.
- **Language Switcher**: Added a bilingual toggle (`English` / `हिंदी`) in the header that translates primary navigation, hero banners, and service categories.

### How to test:
1. Open `index.html` in a mobile viewport (e.g. 360px wide).
2. Confirm the bottom navigation bar is visible and accessible with thumb-friendly buttons.
3. On the Home page under Services, verify that **House help** is listed first with subtitle "Maid, cook, daily or deep cleaning".
4. Tap **House help** to navigate to `#find/House%20help`; verify house help workers (Selvi Devi, Meena Kumari, Suresh Babu, Sunita Bai) appear with avatar badges.
5. Tap the `🌐 हिंदी` button in the header and verify that the interface translates to Hindi. Tap `🌐 English` to switch back.

---

## Phase 2: Pricing, Rate Units & Bargaining / Counter-Offers

### What changed:
- **Rate Units**: Each worker profile now defines a base rate along with its billing unit: `/hr` (`per_hour`), `/visit` (`per_visit`), or `/day` (`per_day`). Workers can update their rate and unit from the Worker Dashboard (`#work`), and new providers can select it during registration.
- **Itemised Price Quotes**: Workers send detailed quotes split into Base labour, Estimated materials / extras, and Travel fee.
- **Bargaining / Counter-Offer Flow**:
  - When customer receives a quote (`quoted`), they can either accept or propose a counter-offer with revised labour and extras (up to 3 negotiation rounds max).
  - Status transitions to `negotiating` with counter-offer details shown to the worker.
  - The worker can accept the counter-offer directly or send a final counter-offer back.
  - Once either side accepts, the final agreed amount is locked (`b.agreedPrice`), displaying a `🔒 Agreed price locked` card.
- **Strict Number Validation**: Prevents negative or zero rates (`> 0` for labour/base, `>= 0` for materials and travel).
- **Status Stepper Integration**: Stepper displays current round info (e.g. `Quote sent (Round 1/3)`, `Negotiating (Counter 2/3)`, `Price agreed & approved (₹370)`).

### How to test:
1. As a customer, request worker Ravi Kumar (`#worker/w1`). Describe the job and tap "Send request".
2. Switch role to Worker (`#work`) and select Ravi Kumar from the "Demo sign-in as" dropdown.
3. Notice the new "Base rate & unit" inputs (e.g. `300` and `/hour`). Tap "Accept" on the request, fill in Labour ₹300, Materials ₹100, Travel ₹40, and tap "Send quote".
4. Switch role to Customer (`#cust`). View the quote.
5. Expand "Bargain / Send counter-offer (Round 2/3)". Enter Proposed Labour ₹250, Materials ₹80, Travel ₹40, Note: "Can we do ₹370 total?", and tap "Send counter-offer".
6. Switch back to Worker (`#work`). Notice the highlighted Customer counter-offer card showing ₹370.
7. Tap "Accept counter-offer (₹370)". Observe status changes to "Price agreed & approved" with the agreed price locked card.

---

## Phase 3: Interactive Leaflet Map & Nearby Workers

### What changed:
- **Leaflet & OpenStreetMap**: Integrated Leaflet.js with free OpenStreetMap tiles (no API keys required).
- **Nearby Worker Markers**: Placed workers on the map across Bengaluru sample localities with custom emoji pins indicating trade and availability status (active green for available, muted grey for busy).
- **Location & ETA Badges**: Each worker card and map marker popup displays relative distance (e.g., `📍 0.8 km`) and arrival estimate (e.g., `⚡ Available within ~12 min`).
- **Interactive Marker Selection**: Tapping any worker pin opens an info popup with rating, pricing, and a "Select" button that smoothly scrolls to a worker preview card below the map.
- **Graceful Fallback**: If the map fails to initialize or the device is offline with un-cached tiles, it automatically falls back to an error-free list view displaying all nearby workers with their distances and arrival badges.

### How to test:
1. Tap the **Map** tab (`🗺️ Map` or `#map`) from the bottom navigation or tap "🗺️ View nearby map" from the search page.
2. Verify the interactive map renders centered on the sample locality with worker pins.
3. Tap on any worker marker to view their popup card showing their category, rate, distance, and ETA badge.
4. Tap "Select" in the popup to display their preview card below the map.
5. In DevTools, simulate offline mode or disable JavaScript for `cdnjs.cloudflare.com` to confirm that the map container gracefully falls back to the list view without errors.

---

## Phase 4: Installable Progressive Web App (PWA)

### What changed:
- **Web App Manifest (`manifest.json`)**: Configured PWA metadata with standalone display mode, orientation, brand theme colors (`#1F7A70` and `#f6faf9`), and responsive icons (`icon-192.png`, `icon-512.png`, `apple-touch-icon.png`, `favicon-32.png`) with maskable support.
- **Service Worker (`sw.js`)**: Implemented a lightweight caching service worker with cache-first strategy for app shell assets and network-first navigation handling.
- **App Shell Registration**: Registered the service worker in `index.html` ensuring the demo functions completely offline without internet connectivity.
- **Installability**: Meets all Chrome and mobile browser PWA installation requirements ("Add to Home Screen" prompt supported).

### How to test:
1. Open the app in Chrome or mobile browser.
2. Open Chrome DevTools > **Application** tab > **Manifest**. Confirm that the identity, presentation (`standalone`), and icons render without warnings.
3. In DevTools > **Application** tab > **Service Workers**, confirm `sw.js` is active and running.
4. Toggle the **Offline** checkbox in DevTools or turn on Airplane mode on your device, then reload the page (`F5`). Verify the entire application shell, sample data, and navigation still load smoothly offline.
5. In Chrome's URL bar or mobile menu, verify the **Install app** / **Add to Home screen** prompt is available.

---

## Phase 5: SQL Schema, Seed Data & Data Layer Alignment

### What changed:
- **Database Schema (`schema.sql`)**:
  - Added `rate_unit` column to `workers` (`per_hour`, `per_visit`, `per_day`) alongside `base_rate` and `hourly_rate` (backward compatible).
  - Updated category constraints to support **House help** as a first-class service category.
  - Added Phase 2 price locking fields to `bookings`: `agreed_total NUMERIC` and `agreed_breakdown JSONB`.
  - Added Phase 2 bargaining columns to `quotes`: `round_number INT CHECK (round_number BETWEEN 1 AND 3)`, `offered_by TEXT CHECK (offered_by IN ('worker', 'customer'))`, and `total_estimate NUMERIC`.
  - Updated lifecycle state transition trigger `validate_booking_status_transition()` so that `negotiating` can cleanly transition to `approved` (when worker accepts customer counter-offer), `quoted` (when worker counters back), `rejected`, or `cancelled`.
  - Ensured idempotent re-run safety via `DROP TABLE IF EXISTS ... CASCADE`, `CREATE TABLE IF NOT EXISTS`, and `CREATE INDEX IF NOT EXISTS`.
  - Detailed Row Level Security (RLS) policies and architectural notes. Reaffirmed that `worker_private` has **NO SELECT** policy, preventing any leaks of phone numbers, addresses, or Aadhaar last 4 digits to regular/anonymous users.
- **Seed Data (`seed.sql`)**:
  - Added all 11 prototype workers (`w1` through `w11`) matching `index.html`, including the 4 House help providers (`w2`, `w9`, `w10`, `w11`) and their respective rate units (`per_visit`, `per_hour`, `per_day`).
  - Safe re-running via `ON CONFLICT (id) DO UPDATE SET`.
- **Data Layer (`db.js`)**:
  - Updated `DEFAULT_SEED_WORKERS` to match all 11 workers with `House help` and rate units.
  - Updated `VALID_STATUS_TRANSITIONS` to allow `negotiating -> approved / quoted / rejected / cancelled`.
  - Added `sendCounterOffer`, `approveBooking`, and `acceptCounterOffer` methods to both `localAdapter` and `supabaseAdapter`.
  - Updated `normalizeWorker` and `normalizeBooking` to handle `rate_unit`, `base_rate`, and `agreedPrice` locking.

### How to test:
1. Open Supabase SQL Editor (or local Postgres instance).
2. Execute `schema.sql` from top to bottom. Verify all 6 tables (`workers`, `worker_private`, `bookings`, `quotes`, `reviews`, `reports`), triggers, and RLS policies are created without errors.
3. Re-run `schema.sql` a second time to verify idempotent execution without `relation already exists` or duplicate errors.
4. Execute `seed.sql`. Verify all 11 workers are inserted or updated, and check that querying `SELECT name, category, base_rate, rate_unit FROM workers WHERE category = 'House help';` returns Selvi Devi, Meena Kumari, Suresh Babu, and Sunita Bai.
5. In Node or browser with `config.js` pointing to Supabase, run `scratch/test_phase5.js` (or trigger in browser) to verify the full bargaining and price locking lifecycle.

---

## Phase 6: BHK-Based Pricing for Sweeping and Mopping

### What changed:
- **BHK-Based Pricing for Sweeping & Mopping**:
  - Implemented 1 BHK, 2 BHK, 3 BHK, and 4 BHK rates specifically and exclusively for the "Sweeping and mopping" task in the House help category. All other tasks continue using the worker's standard base rate.
  - Existing workers offering Sweeping and mopping without BHK rates default smoothly to their base rate across all 4 BHK sizes until edited.
- **Worker Cards & Profile**:
  - Worker cards for providers who offer Sweeping and mopping display a dedicated price badge: `"Sweeping & mopping from ₹{1BHK} (1 BHK)"` (or Hindi equivalent `"झाड़ू-पोंछा ₹{1BHK} (1 BHK) से"`).
  - Worker profile pages display a clear, structured table showing the worker's complete 1 BHK, 2 BHK, 3 BHK, and 4 BHK rates alongside their unit.
- **Worker Registration & Dashboard**:
  - Provider onboarding (`#join`) and registration form (`regForm`): ticking "Sweeping and mopping" reveals 4 rate input fields (1 BHK, 2 BHK, 3 BHK, 4 BHK in ₹). Validates that all 4 are numbers > 0 and in ascending order (`1 BHK <= 2 BHK <= 3 BHK <= 4 BHK`).
  - Worker Dashboard (`#work`): House help workers who offer Sweeping and mopping can view and edit their 1/2/3/4 BHK rates at any time with validation and instant localStorage persistence.
- **Customer Booking Form & Dynamic Mixed-Task Breakdown**:
  - Ticking "Sweeping and mopping" in `#book/:id` dynamically shows a required BHK selector directly beneath the task list. If unticked, the selector is hidden and cleared. It never appears for other tasks.
  - Mixed Task Pricing Breakdown: When Sweeping and mopping is chosen with other tasks, a real-time price breakdown table itemises the BHK rate for sweeping, the worker's base rate for the remaining tasks, and travel charges, summing them to an accurate estimated total.
  - Submitting without choosing a BHK when Sweeping and mopping is selected triggers validation error. The selected BHK is saved directly onto the booking record (`bhk` and `bhk_type`).
- **Bargaining & Price Locking**:
  - Worker quotes and customer counter-offers start from the BHK-based price (e.g. BHK rate or mixed total) rather than an arbitrary base rate.
  - Price locking persists both the selected BHK and the agreed total (`agreedPrice` and `agreed_price`).
- **House Help Filters**:
  - Added an optional BHK filter dropdown (`All BHK sizes`, `1 BHK`, `2 BHK`, `3 BHK`, `4 BHK`) on the House help list page (`#hh`).
  - The "Max rate (₹)" filter evaluates against the selected BHK price for Sweeping and mopping workers, and uses the standard rate otherwise.
- **Supabase & Database Layer Alignment**:
  - `schema.sql`: Added `rate_1bhk`, `rate_2bhk`, `rate_3bhk`, `rate_4bhk` to `workers` and `bhk_type`, `agreed_price` to `bookings` with safe migration DO blocks.
  - `seed.sql`: Populated 1-4 BHK rates for sample House help workers (`w2`, `w9`, `w11`, `w14`, `w17`).
  - `db.js`: Extended seed workers, normalization routines, local storage adapter, and Supabase client methods to support BHK rates, BHK booking types, and agreed price locking.
- **Bilingual I18N**:
  - Added complete English and Hindi translations for all new BHK labels, breakdown headings, and validation messages.

### How to test:
1. Open `index.html` in browser.
2. Navigate to **House Help** (`#hh`). Verify worker cards for Selvi Devi (`w2`) and Meena Kumari (`w9`) display `"Sweeping & mopping from ₹200 (1 BHK)"` and `"Sweeping & mopping from ₹150 (1 BHK)"` respectively.
3. In House Help filters, select `2 BHK` and set `Max rate` to `200`. Tap "Apply filters". Verify workers whose 2 BHK rate exceeds 200 (like Selvi Devi at ₹250) are excluded, while matching workers (like Meena Kumari at ₹180 and Sunita Bai at ₹200) are shown.
4. Open Selvi Devi's profile (`#worker/w2`). Confirm the full 1/2/3/4 BHK rate table is displayed (1 BHK: ₹200, 2 BHK: ₹250, 3 BHK: ₹300, 4 BHK: ₹350).
5. Tap "Request this worker" (`#book/w2`). Tick "Sweeping and mopping"; verify the "Select home size (BHK)" dropdown appears directly below. Select "2 BHK (₹250)". Confirm immediate breakdown shows ₹250 for sweeping, ₹30 travel, total ₹280.
6. Also tick "Bathroom cleaning" and "Kitchen cleaning". Confirm breakdown updates to show Sweeping (2 BHK) at ₹250, Other tasks at ₹250, Travel at ₹30, Total at ₹530. Untick "Sweeping and mopping"; verify the BHK selector and sweeping line disappear.
7. Re-tick "Sweeping and mopping", choose "2 BHK", fill details, and submit request.
8. Switch role to Worker (`#work`) as Selvi Devi. Verify the request shows tasks with "(2 BHK)". Tap "Accept" and verify initial Labour is prefilled with ₹530. Send quote.
9. Switch back to Customer (`#cust`). Expand counter-offer: confirm proposed labour starts from ₹530. Submit counter-offer (e.g. Labour ₹480).
10. Switch back to Worker (`#work`) and tap "Accept counter-offer". Verify status is locked with agreed price ₹510 (480 + 30 travel) and BHK preserved.
11. Test Worker Registration (`#join` or `#work` register form): Tick "Sweeping and mopping", enter test rates (e.g., 200, 250, 300, 350), verify validation works for non-positive or non-ascending numbers.
12. Tap the language toggle `🌐 हिंदी` and verify all BHK labels and messages render in Hindi. Tap `🌐 English` to switch back.




