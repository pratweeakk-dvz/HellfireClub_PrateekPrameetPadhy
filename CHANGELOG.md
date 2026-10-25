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



