# SevaSetu

**Trust for every home, work for every hand.**

Team: **Hellfire Club** | Team leader: **Prateek Prameet Padhy**

Hackathon: VecnaVerse | Domain: Social Impact

Problem statement: Hyperlocal On-Demand Blue-Collar Services Platform

**Live demo:** https://pratweeakk-dvz.github.io/HellfireClub_PrateekPrameetPadhy/

> **Demo mode:** the live site uses clearly labelled sample data stored only in your browser. There are no real workers, payments, Aadhaar checks or bookings.

## The problem
Households struggle to find trustworthy electricians, plumbers, cleaners and house help nearby, quickly and at a fair price. Workers have no easy way to set their own rates, show their skills or build trust.

## Our solution
SevaSetu is a two-sided hyperlocal marketplace. Customers find and book nearby workers, and workers list their skills, set their own rates and accept or negotiate jobs.

## Features (demo prototype)
- **Two roles:** choose Customer or Service Provider
- **Find workers:** search and filter by category, locality, maximum rate and availability, with distance and "available within ~30 min" badges
- **Dedicated House help section:** maids, cooks, cleaners, senior care and baby sitting
- **Task checklist for House help workers:** at registration, workers tick the work they do (dish washing, clothes drying, cooking, senior care taking, baby sitting and more)
- **Task-based filters and booking:** customers filter by tasks and choose the tasks they need
- **Pricing and bargaining:** workers set their own rate and unit (per hour, visit or day), and customers can counter-offer
- **Itemised quote:** workers send a quote split into labour, materials and travel, and customers can approve it or bargain for up to 3 rounds
- **Bookings:** booking IDs and a status stepper
- **Worker dashboard:** availability toggle, rate, offered tasks and job requests
- **Map view:** nearby workers shown on a map, with a list-view fallback
- **Languages:** English and Hindi
- **Installable web app:** web manifest and service worker
- **Safety notes:** senior care and baby sitting bookings show a safety note and a "Verification pending" label
- **Demo login and signup:** sign up with name, email and password and your name shows in the header. Saved in the browser only, not real authentication
- **SevaSetu Verified badge:** workers show a green tick or "Verification pending", with a tappable popup. Verification is simulated in this demo
- **Reviews with photos:** after a completed booking, customers can add a star rating, a written note (500 characters) and up to 6 compressed photos, saved in the browser

## Try it in 2 minutes
1. Open the live link and choose "I need a service".
2. Find a worker, tap the green tick to see what was checked, and send a request.
3. Switch role to the worker, accept the job, send a quote, then complete it.
4. Switch back to the customer and leave a review with a note and photos.

## Simulated in this demo
- Aadhaar verification is a **sample check only**. Do not enter a real Aadhaar number. Only the last 4 digits are kept.
- One-time codes are demo codes shown on screen.
- No real payments or messaging.
- Workers and ratings are sample data marked "Demo profile".
- Login and SevaSetu Verified status are simulated and saved only in your browser.
- Reviews with photos are saved in the browser but not yet shown on worker profiles. This is planned next.
- New workers start as "Verification pending". The admin screen handles complaints and listings, and the approve and reject step for verification is planned.

## Tech stack
- HTML, CSS and vanilla JavaScript in a single file (`index.html`), with no build step
- Supabase (Postgres) schema and data layer: `schema.sql`, `seed.sql`, `db.js`
- Leaflet and OpenStreetMap for the map
- GitHub Pages for hosting

## Run it locally
1. Download or clone this repo.
2. Open `index.html` in a browser. Demo mode works with no setup.

## Optional: connect Supabase
1. Create a Supabase project.
2. Run `schema.sql`, then `seed.sql`, in the SQL Editor.
3. Copy `config.example.js` to `config.js` and add your Project URL and **publishable** key.
4. Never commit `config.js` and never use a secret or service_role key in the browser.

## Planned next
- Real phone OTP and real identity verification
- Payments and escrow
- Ratings from real completed jobs
- More languages and more localities
- Real-time job notifications
- Admin approve and reject screen for worker verification
- Review feed on worker profiles with a photo lightbox, filters, worker replies and reporting
- Group and society bookings with shared discounts
- Supabase storage for review photos

## Project files
- `index.html`: the app
- `db.js`, `schema.sql`, `seed.sql`, `config.example.js`: database layer
- `manifest.json`, `sw.js`: installable app
- `CHANGELOG.md`: what changed in each build step

## Authors
- Prateek Prameet Padhy ([@pratweeakk-dvz](https://github.com/pratweeakk-dvz))
- Niharika Jha ([@niharikajha2307](https://github.com/niharikajha2307))
- Final round submission: VecnaVerse