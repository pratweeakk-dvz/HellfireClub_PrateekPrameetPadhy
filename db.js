// ============================================================================
// SevaSetu: Database Abstraction Layer (db.js)
// ============================================================================
// Provides a unified data interface with two interchangeable adapters:
//   1. "local"    : Browser localStorage (demo offline mode)
//   2. "supabase" : Supabase PostgreSQL cloud backend via supabase-js CDN
//
// Key Features:
// - Pinned Supabase JS SDK: @supabase/supabase-js@2.48.0
// - Auto-fallback: If Supabase credentials are placeholders, network fails,
//   or queries fail, gracefully falls back to localStorage.
// - State machine transition validation on both local & cloud.
// - Clean normalization so the frontend receives consistent data structures.
// ============================================================================

(function (root, factory) {
  if (typeof define === 'function' && define.amd) {
    define([], factory);
  } else if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.db = factory();
  }
}(typeof self !== 'undefined' ? self : this, function () {
  'use strict';

  // --------------------------------------------------------------------------
  // 1. Pinned Supabase JS CDN URL & Version
  // --------------------------------------------------------------------------
  const SUPABASE_CDN_URL = 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.48.0/dist/umd/supabase.min.js';

  // --------------------------------------------------------------------------
  // 2. Default Seed Workers (Identical to index.html demo workers)
  // --------------------------------------------------------------------------
  const DEFAULT_SEED_WORKERS = [
    { id: 'w1', name: 'Ravi Kumar', cat: 'Electrician', loc: 'North Colony', exp: 8, rate: 300, travel: 40, avail: true, skills: 'Fan, wiring, switchboards', rating: 4.6, rc: 31, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w2', name: 'Selvi Devi', cat: 'Cleaner', loc: 'Lake View', exp: 5, rate: 180, travel: 30, avail: true, skills: 'Deep cleaning, kitchens, bathrooms', rating: 4.8, rc: 52, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w3', name: 'Imran Shaikh', cat: 'Plumber', loc: 'Market Road', exp: 11, rate: 350, travel: 50, avail: true, skills: 'Leaks, taps, tank fittings', rating: 4.4, rc: 27, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w4', name: 'Mohan Das', cat: 'Painter', loc: 'Station Area', exp: 14, rate: 400, travel: 60, avail: false, skills: 'Interior walls, waterproofing', rating: 4.5, rc: 19, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w5', name: 'Anita Joseph', cat: 'Carpenter', loc: 'North Colony', exp: 9, rate: 380, travel: 40, avail: true, skills: 'Doors, shelves, furniture repair', rating: 4.7, rc: 23, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w6', name: 'Karthik R', cat: 'Appliance repair', loc: 'Lake View', exp: 6, rate: 320, travel: 40, avail: true, skills: 'Washing machine, fridge, mixer', rating: 4.3, rc: 35, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w7', name: 'Latha Sundar', cat: 'Electrician', loc: 'Station Area', exp: 3, rate: 260, travel: 30, avail: true, skills: 'Lights, inverter wiring', rating: 4.1, rc: 8, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w8', name: 'Faizal Ahmed', cat: 'Plumber', loc: 'North Colony', exp: 2, rate: 280, travel: 30, avail: true, skills: 'Basic plumbing, bathroom fittings', rating: 0, rc: 0, ver: 'Unverified', demo: false, hidden: false },
    { id: 'w9', name: 'Meena Kumari', cat: 'Maid', loc: 'Lake View', exp: 7, rate: 120, travel: 20, avail: true, skills: 'Daily cleaning, utensils, laundry', rating: 4.5, rc: 14, ver: 'Demo profile', demo: true, hidden: false },
    { id: 'w10', name: 'Suresh Babu', cat: 'Cook', loc: 'Market Road', exp: 10, rate: 200, travel: 20, avail: true, skills: 'Home-style meals, tiffin prep', rating: 4.6, rc: 12, ver: 'Demo profile', demo: true, hidden: false }
  ];

  // --------------------------------------------------------------------------
  // 3. State Machine Transition Rules
  // Valid transitions:
  //   requested   -> accepted, rejected, cancelled
  //   accepted    -> quoted, cancelled
  //   quoted      -> approved, negotiating, cancelled
  //   negotiating -> quoted, cancelled
  //   approved    -> completed
  // --------------------------------------------------------------------------
  const VALID_STATUS_TRANSITIONS = {
    requested: ['accepted', 'rejected', 'cancelled'],
    accepted: ['quoted', 'cancelled'],
    quoted: ['approved', 'negotiating', 'cancelled'],
    negotiating: ['quoted', 'cancelled'],
    approved: ['completed'],
    completed: [],
    rejected: [],
    cancelled: []
  };

  function validateStatusTransition(currentStatus, nextStatus) {
    if (currentStatus === nextStatus) return true;
    const allowed = VALID_STATUS_TRANSITIONS[currentStatus];
    if (!allowed || !allowed.includes(nextStatus)) {
      throw new Error(`Invalid status transition: cannot change booking status from "${currentStatus}" to "${nextStatus}".`);
    }
    return true;
  }

  // --------------------------------------------------------------------------
  // 4. LocalStorage Adapter ("local")
  // Retains full compatibility with index.html's localStorage data schema ('kaamsetu').
  // --------------------------------------------------------------------------
  const STORAGE_KEY = 'kaamsetu';

  function getLocalStore() {
    try {
      const data = localStorage.getItem(STORAGE_KEY);
      if (data) {
        const parsed = JSON.parse(data);
        if (parsed && Array.isArray(parsed.workers)) {
          // Ensure default seed workers exist
          DEFAULT_SEED_WORKERS.forEach(dw => {
            if (!parsed.workers.find(w => w.id === dw.id)) {
              parsed.workers.push({ ...dw });
            }
          });
          return parsed;
        }
      }
    } catch (e) {
      console.warn('[SevaSetu db] localStorage read error:', e);
    }

    // Default initialization if store is missing
    const initial = {
      workers: DEFAULT_SEED_WORKERS.map(w => ({ ...w })),
      bookings: [],
      reports: [],
      me: 'w1',
      n: 1,
      role: null,
      user: null
    };
    saveLocalStore(initial);
    return initial;
  }

  function saveLocalStore(state) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (e) {
      console.warn('[SevaSetu db] localStorage save failed:', e);
    }
  }

  const localAdapter = {
    name: 'local',

    async init() {
      getLocalStore();
      return true;
    },

    async listWorkers(filters = {}) {
      const state = getLocalStore();
      let list = state.workers.filter(w => !w.hidden);

      if (filters.cat) {
        list = list.filter(w => w.cat === filters.cat);
      }
      if (filters.loc) {
        list = list.filter(w => w.loc === filters.loc);
      }
      if (filters.av) {
        list = list.filter(w => w.avail);
      }
      if (filters.max && Number(filters.max) > 0) {
        list = list.filter(w => w.rate <= Number(filters.max));
      }
      if (filters.q) {
        const query = filters.q.toLowerCase();
        list = list.filter(w =>
          (w.name + ' ' + w.skills + ' ' + w.cat).toLowerCase().includes(query)
        );
      }
      return list;
    },

    async getWorker(workerId) {
      const state = getLocalStore();
      return state.workers.find(w => w.id === workerId) || null;
    },

    async registerWorker(workerData, privateData = null) {
      const state = getLocalStore();
      const id = 'w' + (state.workers.length + 1 + (Date.now() % 1000));
      const newWorker = {
        id,
        name: workerData.name,
        cat: workerData.cat,
        loc: workerData.loc,
        exp: Number(workerData.exp || 0),
        rate: Number(workerData.rate),
        travel: Number(workerData.travel || 30),
        avail: true,
        skills: workerData.skills,
        rating: 0,
        rc: 0,
        ver: privateData ? 'Demo verified' : 'Unverified',
        demo: false,
        hidden: false,
        // Only keep last 4 digits of Aadhaar if provided in demo verification
        a4: privateData ? String(privateData.aadhaar || '').slice(-4) : null,
        mobile: privateData ? String(privateData.mobile || '') : null
      };
      state.workers.push(newWorker);
      saveLocalStore(state);
      return newWorker;
    },

    async updateWorker(workerId, updates) {
      const state = getLocalStore();
      const worker = state.workers.find(w => w.id === workerId);
      if (!worker) throw new Error(`Worker with ID "${workerId}" not found.`);
      Object.assign(worker, updates);
      saveLocalStore(state);
      return worker;
    },

    async createBooking(bookingData) {
      const state = getLocalStore();
      const id = 'SS-2026-' + String(state.n++).padStart(6, '0');
      const booking = {
        id,
        wid: bookingData.wid || bookingData.worker_id,
        cat: bookingData.cat || bookingData.category,
        desc: bookingData.desc || bookingData.description,
        loc: bookingData.loc || bookingData.locality,
        when: bookingData.when || bookingData.booking_time,
        status: 'requested',
        quote: null,
        review: null,
        report: null,
        created: new Date().toISOString()
      };
      state.bookings.push(booking);
      saveLocalStore(state);
      return booking;
    },

    async listBookings() {
      const state = getLocalStore();
      // Return a copy sorted newest first
      return state.bookings.slice().reverse();
    },

    async getBooking(bookingId) {
      const state = getLocalStore();
      return state.bookings.find(b => b.id === bookingId) || null;
    },

    async setStatus(bookingId, newStatus, message = '') {
      const state = getLocalStore();
      const booking = state.bookings.find(b => b.id === bookingId);
      if (!booking) throw new Error(`Booking "${bookingId}" not found.`);

      // Validate state transition rule
      validateStatusTransition(booking.status, newStatus);

      booking.status = newStatus;
      booking.updated = new Date().toISOString();
      saveLocalStore(state);
      return { success: true, booking, message };
    },

    async saveQuote(bookingId, quoteData) {
      const state = getLocalStore();
      const booking = state.bookings.find(b => b.id === bookingId);
      if (!booking) throw new Error(`Booking "${bookingId}" not found.`);

      // Status must transition to 'quoted'
      validateStatusTransition(booking.status, 'quoted');

      const version = (booking.quote ? booking.quote.v || 1 : 0) + 1;
      booking.quote = {
        v: version,
        labor: Number(quoteData.labor || quoteData.labour_charge),
        mat: Number(quoteData.mat || quoteData.materials_charge || 0),
        travel: Number(quoteData.travel || quoteData.travel_charge || 0),
        note: (quoteData.note || '').trim(),
        ask: (quoteData.ask || quoteData.revision_request || '').trim()
      };
      booking.status = 'quoted';
      saveLocalStore(state);
      return booking.quote;
    },

    async addReview(bookingId, reviewData) {
      const state = getLocalStore();
      const booking = state.bookings.find(b => b.id === bookingId);
      if (!booking) throw new Error(`Booking "${bookingId}" not found.`);

      const rating = Number(reviewData.r || reviewData.rating);
      const comment = (reviewData.t || reviewData.comment || '').trim();

      booking.review = { r: rating, t: comment };

      // Update worker average rating and review count
      const worker = state.workers.find(w => w.id === booking.wid);
      if (worker) {
        worker.rating = Number(((worker.rating * worker.rc + rating) / (worker.rc + 1)).toFixed(2));
        worker.rc += 1;
      }

      saveLocalStore(state);
      return booking.review;
    },

    async addReport(bookingId, reportData) {
      const state = getLocalStore();
      const booking = state.bookings.find(b => b.id === bookingId);
      if (!booking) throw new Error(`Booking "${bookingId}" not found.`);

      const issueText = (reportData.t || reportData.issue_text || '').trim();
      const report = {
        t: issueText,
        s: 'Open',
        note: ''
      };
      booking.report = report;
      if (!state.reports.includes(bookingId)) {
        state.reports.push(bookingId);
      }
      saveLocalStore(state);
      return report;
    },

    async listReports() {
      const state = getLocalStore();
      return state.bookings
        .filter(b => b.report)
        .map(b => ({
          bookingId: b.id,
          workerId: b.wid,
          category: b.cat,
          issueText: b.report.t,
          status: b.report.s,
          resolutionNote: b.report.note
        }));
    },

    async resolveReport(bookingId, resolutionNote) {
      const state = getLocalStore();
      const booking = state.bookings.find(b => b.id === bookingId);
      if (!booking || !booking.report) throw new Error(`Report for booking "${bookingId}" not found.`);

      booking.report.s = 'Resolved';
      booking.report.note = resolutionNote.trim();
      saveLocalStore(state);
      return booking.report;
    }
  };


  // --------------------------------------------------------------------------
  // 5. Supabase Adapter ("supabase")
  // Interacts with Postgres tables: workers, worker_private, bookings, quotes,
  // reviews, and reports.
  // --------------------------------------------------------------------------
  let supabaseClient = null;

  async function loadSupabaseScript() {
    if (typeof window === 'undefined') return false;
    if (window.supabase && typeof window.supabase.createClient === 'function') {
      return true;
    }

    return new Promise((resolve) => {
      const existingScript = document.querySelector(`script[src*="supabase-js"]`);
      if (existingScript) {
        existingScript.addEventListener('load', () => resolve(true));
        existingScript.addEventListener('error', () => resolve(false));
        return;
      }

      const script = document.createElement('script');
      script.src = SUPABASE_CDN_URL;
      script.async = true;
      script.onload = () => resolve(true);
      script.onerror = (err) => {
        console.warn('[SevaSetu db] Failed to load supabase-js from CDN:', err);
        resolve(false);
      };
      document.head.appendChild(script);
    });
  }

  function normalizeWorker(row) {
    if (!row) return null;
    return {
      id: row.id,
      name: row.name,
      cat: row.category,
      loc: row.locality,
      exp: row.experience_years,
      rate: Number(row.hourly_rate),
      travel: Number(row.travel_charge),
      avail: row.is_available,
      skills: row.skills,
      rating: Number(row.rating),
      rc: row.review_count,
      ver: row.verification_status,
      demo: row.is_demo,
      hidden: row.is_hidden
    };
  }

  function normalizeBooking(row) {
    if (!row) return null;
    // Extract latest quote if quotes relation is joined
    let latestQuote = null;
    if (row.quotes && Array.isArray(row.quotes) && row.quotes.length > 0) {
      const sorted = row.quotes.slice().sort((a, b) => b.version - a.version);
      const q = sorted[0];
      latestQuote = {
        v: q.version,
        labor: Number(q.labour_charge),
        mat: Number(q.materials_charge),
        travel: Number(q.travel_charge),
        note: q.note || '',
        ask: q.revision_request || ''
      };
    }

    // Extract review if relation joined
    let reviewObj = null;
    if (row.reviews) {
      const r = Array.isArray(row.reviews) ? row.reviews[0] : row.reviews;
      if (r) {
        reviewObj = {
          r: r.rating,
          t: r.comment
        };
      }
    }

    // Extract report if relation joined
    let reportObj = null;
    if (row.reports) {
      const rp = Array.isArray(row.reports) ? row.reports[0] : row.reports;
      if (rp) {
        reportObj = {
          t: rp.issue_text,
          s: rp.status,
          note: rp.resolution_note || ''
        };
      }
    }

    return {
      id: row.id,
      wid: row.worker_id,
      cat: row.category,
      desc: row.description,
      loc: row.locality,
      when: row.booking_time,
      status: row.status,
      created: row.created_at,
      quote: latestQuote,
      review: reviewObj,
      report: reportObj
    };
  }

  const supabaseAdapter = {
    name: 'supabase',

    async init(config) {
      const url = config.SUPABASE_URL || '';
      const key = config.SUPABASE_ANON_KEY || '';

      // Check if user has replaced placeholder credentials
      const isPlaceholder = !url || !key ||
        url.includes('YOUR_PROJECT_ID') ||
        key.includes('YOUR_SUPABASE_ANON_KEY') ||
        !url.startsWith('https://');

      if (isPlaceholder) {
        console.warn('[SevaSetu db] Supabase credentials in config are unconfigured or placeholders. Falling back to local adapter.');
        return false;
      }

      const scriptLoaded = await loadSupabaseScript();
      if (!scriptLoaded || !window.supabase) {
        console.warn('[SevaSetu db] supabase-js could not be loaded. Falling back to local adapter.');
        return false;
      }

      try {
        supabaseClient = window.supabase.createClient(url, key);
        // Quick lightweight ping to verify connection and credentials
        const { error } = await supabaseClient.from('workers').select('id').limit(1);
        if (error) {
          console.warn('[SevaSetu db] Supabase connection test returned error:', error.message);
          return false;
        }
        console.log('[SevaSetu db] Supabase adapter connected successfully to:', url);
        return true;
      } catch (err) {
        console.warn('[SevaSetu db] Supabase initialization failed:', err);
        return false;
      }
    },

    async listWorkers(filters = {}) {
      let query = supabaseClient.from('workers').select('*').eq('is_hidden', false);

      if (filters.cat) {
        query = query.eq('category', filters.cat);
      }
      if (filters.loc) {
        query = query.eq('locality', filters.loc);
      }
      if (filters.av) {
        query = query.eq('is_available', true);
      }
      if (filters.max && Number(filters.max) > 0) {
        query = query.lte('hourly_rate', Number(filters.max));
      }

      const { data, error } = await query.order('name');
      if (error) throw error;

      let list = (data || []).map(normalizeWorker);
      if (filters.q) {
        const q = filters.q.toLowerCase();
        list = list.filter(w =>
          (w.name + ' ' + w.skills + ' ' + w.cat).toLowerCase().includes(q)
        );
      }
      return list;
    },

    async getWorker(workerId) {
      const { data, error } = await supabaseClient
        .from('workers')
        .select('*')
        .eq('id', workerId)
        .single();
      if (error) throw error;
      return normalizeWorker(data);
    },

    async registerWorker(workerData, privateData = null) {
      const workerId = 'w' + Date.now();
      const workerRecord = {
        id: workerId,
        name: workerData.name,
        category: workerData.cat,
        locality: workerData.loc,
        experience_years: Number(workerData.exp || 0),
        hourly_rate: Number(workerData.rate),
        travel_charge: Number(workerData.travel || 30),
        is_available: true,
        skills: workerData.skills,
        rating: 0,
        review_count: 0,
        verification_status: privateData ? 'Demo verified' : 'Unverified',
        is_demo: false,
        is_hidden: false
      };

      const { data, error } = await supabaseClient
        .from('workers')
        .insert([workerRecord])
        .select()
        .single();
      if (error) throw error;

      // Insert private details into worker_private (INSERT-only RLS policy)
      if (privateData) {
        const privateRecord = {
          worker_id: workerId,
          home_address: privateData.address || privateData.home_address,
          // CRITICAL: Store only the last 4 digits of Aadhaar
          aadhaar_last4: String(privateData.aadhaar || '').slice(-4),
          mobile_number: String(privateData.mobile || '')
        };
        const { error: privError } = await supabaseClient
          .from('worker_private')
          .insert([privateRecord]);
        if (privError) {
          console.warn('[SevaSetu db] Note: Private info insert failed (demo):', privError.message);
        }
      }

      return normalizeWorker(data);
    },

    async updateWorker(workerId, updates) {
      const dbUpdates = {};
      if (updates.name !== undefined) dbUpdates.name = updates.name;
      if (updates.cat !== undefined) dbUpdates.category = updates.cat;
      if (updates.loc !== undefined) dbUpdates.locality = updates.loc;
      if (updates.avail !== undefined) dbUpdates.is_available = updates.avail;
      if (updates.rate !== undefined) dbUpdates.hourly_rate = Number(updates.rate);
      if (updates.travel !== undefined) dbUpdates.travel_charge = Number(updates.travel);
      if (updates.hidden !== undefined) dbUpdates.is_hidden = updates.hidden;

      const { data, error } = await supabaseClient
        .from('workers')
        .update(dbUpdates)
        .eq('id', workerId)
        .select()
        .single();
      if (error) throw error;
      return normalizeWorker(data);
    },

    async createBooking(bookingData) {
      const payload = {
        worker_id: bookingData.wid || bookingData.worker_id,
        category: bookingData.cat || bookingData.category,
        description: bookingData.desc || bookingData.description,
        locality: bookingData.loc || bookingData.locality,
        booking_time: bookingData.when || bookingData.booking_time,
        status: 'requested'
      };

      const { data, error } = await supabaseClient
        .from('bookings')
        .insert([payload])
        .select()
        .single();
      if (error) throw error;
      return normalizeBooking(data);
    },

    async listBookings() {
      const { data, error } = await supabaseClient
        .from('bookings')
        .select(`
          *,
          quotes (*),
          reviews (*),
          reports (*)
        `)
        .order('created_at', { ascending: false });
      if (error) throw error;
      return (data || []).map(normalizeBooking);
    },

    async getBooking(bookingId) {
      const { data, error } = await supabaseClient
        .from('bookings')
        .select(`
          *,
          quotes (*),
          reviews (*),
          reports (*)
        `)
        .eq('id', bookingId)
        .single();
      if (error) throw error;
      return normalizeBooking(data);
    },

    async setStatus(bookingId, newStatus, message = '') {
      // Fetch current status to validate transition client-side first
      const { data: current, error: fetchErr } = await supabaseClient
        .from('bookings')
        .select('status')
        .eq('id', bookingId)
        .single();
      if (fetchErr) throw fetchErr;

      validateStatusTransition(current.status, newStatus);

      // Updating status triggers the database trigger: trg_validate_booking_status
      const { data, error } = await supabaseClient
        .from('bookings')
        .update({ status: newStatus })
        .eq('id', bookingId)
        .select()
        .single();
      if (error) throw error;
      return { success: true, booking: normalizeBooking(data), message };
    },

    async saveQuote(bookingId, quoteData) {
      // 1. Fetch current quote version
      const { data: existingQuotes, error: qErr } = await supabaseClient
        .from('quotes')
        .select('version')
        .eq('booking_id', bookingId)
        .order('version', { ascending: false })
        .limit(1);
      if (qErr) throw qErr;

      const nextVersion = (existingQuotes && existingQuotes[0] ? existingQuotes[0].version : 0) + 1;

      // 2. Insert new versioned quote
      const quotePayload = {
        booking_id: bookingId,
        version: nextVersion,
        labour_charge: Number(quoteData.labor || quoteData.labour_charge),
        materials_charge: Number(quoteData.mat || quoteData.materials_charge || 0),
        travel_charge: Number(quoteData.travel || quoteData.travel_charge || 0),
        note: (quoteData.note || '').trim(),
        revision_request: (quoteData.ask || quoteData.revision_request || '').trim()
      };

      const { data: newQuote, error: insertErr } = await supabaseClient
        .from('quotes')
        .insert([quotePayload])
        .select()
        .single();
      if (insertErr) throw insertErr;

      // 3. Update booking status to 'quoted'
      await this.setStatus(bookingId, 'quoted');

      return {
        v: newQuote.version,
        labor: Number(newQuote.labour_charge),
        mat: Number(newQuote.materials_charge),
        travel: Number(newQuote.travel_charge),
        note: newQuote.note,
        ask: newQuote.revision_request
      };
    },

    async addReview(bookingId, reviewData) {
      // Fetch worker_id for the booking
      const { data: booking, error: bErr } = await supabaseClient
        .from('bookings')
        .select('worker_id')
        .eq('id', bookingId)
        .single();
      if (bErr) throw bErr;

      const payload = {
        booking_id: bookingId,
        worker_id: booking.worker_id,
        rating: Number(reviewData.r || reviewData.rating),
        comment: (reviewData.t || reviewData.comment || '').trim()
      };

      const { data, error } = await supabaseClient
        .from('reviews')
        .insert([payload])
        .select()
        .single();
      if (error) throw error;
      return { r: data.rating, t: data.comment };
    },

    async addReport(bookingId, reportData) {
      const payload = {
        booking_id: bookingId,
        issue_text: (reportData.t || reportData.issue_text || '').trim(),
        status: 'Open'
      };

      const { data, error } = await supabaseClient
        .from('reports')
        .insert([payload])
        .select()
        .single();
      if (error) throw error;
      return { t: data.issue_text, s: data.status, note: data.resolution_note || '' };
    },

    async listReports() {
      const { data, error } = await supabaseClient
        .from('reports')
        .select(`
          id,
          booking_id,
          issue_text,
          status,
          resolution_note,
          bookings (
            worker_id,
            category
          )
        `)
        .order('created_at', { ascending: false });
      if (error) throw error;

      return (data || []).map(r => ({
        bookingId: r.booking_id,
        workerId: r.bookings ? r.bookings.worker_id : null,
        category: r.bookings ? r.bookings.category : '',
        issueText: r.issue_text,
        status: r.status,
        resolutionNote: r.resolution_note || ''
      }));
    },

    async resolveReport(bookingId, resolutionNote) {
      const { data, error } = await supabaseClient
        .from('reports')
        .update({
          status: 'Resolved',
          resolution_note: resolutionNote.trim(),
          resolved_at: new Date().toISOString()
        })
        .eq('booking_id', bookingId)
        .select()
        .single();
      if (error) throw error;
      return { t: data.issue_text, s: data.status, note: data.resolution_note };
    }
  };


  // --------------------------------------------------------------------------
  // 6. Unified Database Interface with Graceful Fallback
  // Wraps active adapter operations. If Supabase fails, automatically switches
  // to local localStorage adapter.
  // --------------------------------------------------------------------------
  let activeAdapter = localAdapter;
  let isInitialized = false;

  async function resolveConfig() {
    if (typeof window !== 'undefined' && window.SEVASETU_CONFIG) {
      return window.SEVASETU_CONFIG;
    }
    if (typeof window !== 'undefined' && window.APP_CONFIG) {
      return window.APP_CONFIG;
    }
    return { ADAPTER: 'local' };
  }

  async function initDatabase() {
    if (isInitialized) return activeAdapter;

    const config = await resolveConfig();
    const desiredAdapter = (config.ADAPTER || 'local').toLowerCase();

    if (desiredAdapter === 'supabase') {
      try {
        const success = await supabaseAdapter.init(config);
        if (success) {
          activeAdapter = supabaseAdapter;
          isInitialized = true;
          return activeAdapter;
        }
      } catch (err) {
        console.warn('[SevaSetu db] Failed to connect to Supabase:', err);
      }
      console.warn('[SevaSetu db] Falling back to local adapter.');
    }

    await localAdapter.init();
    activeAdapter = localAdapter;
    isInitialized = true;
    return activeAdapter;
  }

  // Wrapper function that handles execution & fallback
  async function execute(actionName, ...args) {
    await initDatabase();

    try {
      return await activeAdapter[actionName](...args);
    } catch (err) {
      // If active adapter was Supabase and an unexpected network / server error occurred,
      // fallback to local and retry the action.
      if (activeAdapter.name === 'supabase') {
        console.warn(`[SevaSetu db] Supabase call "${actionName}" failed. Switching to local fallback. Error:`, err.message || err);
        activeAdapter = localAdapter;
        await localAdapter.init();
        return await localAdapter[actionName](...args);
      }
      // If already on local, re-throw (e.g. invalid status transition)
      throw err;
    }
  }

  // --------------------------------------------------------------------------
  // 7. Public API Interface
  // --------------------------------------------------------------------------
  const api = {
    // Adapter info
    getAdapterName() {
      return activeAdapter ? activeAdapter.name : 'uninitialized';
    },

    async init() {
      return await initDatabase();
    },

    // 1. listWorkers
    async listWorkers(filters = {}) {
      return await execute('listWorkers', filters);
    },

    // 2. createBooking
    async createBooking(bookingData) {
      return await execute('createBooking', bookingData);
    },

    // 3. listBookings
    async listBookings() {
      return await execute('listBookings');
    },

    // 4. setStatus
    async setStatus(bookingId, newStatus, message) {
      return await execute('setStatus', bookingId, newStatus, message);
    },

    // 5. saveQuote
    async saveQuote(bookingId, quoteData) {
      return await execute('saveQuote', bookingId, quoteData);
    },

    // 6. addReview
    async addReview(bookingId, reviewData) {
      return await execute('addReview', bookingId, reviewData);
    },

    // 7. addReport
    async addReport(bookingId, reportData) {
      return await execute('addReport', bookingId, reportData);
    },

    // 8. listReports
    async listReports() {
      return await execute('listReports');
    },

    // Extra helpers for UI convenience
    async getWorker(workerId) {
      return await execute('getWorker', workerId);
    },

    async registerWorker(workerData, privateData) {
      return await execute('registerWorker', workerData, privateData);
    },

    async updateWorker(workerId, updates) {
      return await execute('updateWorker', workerId, updates);
    },

    async getBooking(bookingId) {
      return await execute('getBooking', bookingId);
    },

    async resolveReport(bookingId, resolutionNote) {
      return await execute('resolveReport', bookingId, resolutionNote);
    }
  };

  return api;
}));
