// ============================================================================
// SevaSetu: Configuration File (Template)
// ============================================================================
// INSTRUCTIONS FOR HACKATHON PARTICIPANTS & BEGINNERS:
//
// 1. Copy this file and rename it to "config.js":
//      cp config.example.js config.js
//
// 2. Where to find your Supabase credentials:
//    - Go to https://supabase.com and log in to your project dashboard.
//    - Click the gear icon "Project Settings" at the bottom left of the sidebar.
//    - Click "API" under the Configuration section.
//    - Under "Project URL", copy the URL (e.g. https://your-project-id.supabase.co).
//    - Under "Project API keys", find the key labeled "anon" (public).
//      Copy this key and paste it into SUPABASE_ANON_KEY below.
//
// ⚠️ CRITICAL SECURITY WARNING:
// - ONLY use the "anon" (public) key in this frontend application.
// - NEVER use or expose the "service_role" secret key here! The service_role key
//   bypasses Row Level Security and must stay completely private on a backend server.
//
// 3. Adapter Selection:
//    - 'supabase' : Connects to your live Supabase database via the Supabase client.
//                   If the Supabase connection fails or credentials are placeholders,
//                   db.js will automatically fall back to 'local' localStorage mode.
//    - 'local'    : Stores all data inside browser localStorage (offline demo mode).
// ============================================================================

const CONFIG = {
  // Database Adapter: 'supabase' or 'local'
  ADAPTER: 'supabase',

  // Supabase Project Settings
  SUPABASE_URL: 'https://YOUR_PROJECT_ID.supabase.co',
  SUPABASE_ANON_KEY: 'YOUR_SUPABASE_ANON_PUBLISHABLE_KEY',

  // Fallback behavior: if true, automatically switch to localStorage if Supabase is unreachable
  AUTO_FALLBACK_TO_LOCAL: true,

  // App details
  APP_NAME: 'SevaSetu',
  VERSION: '0.1.0-demo'
};

// Make config globally available for vanilla JavaScript script tags
if (typeof window !== 'undefined') {
  window.SEVASETU_CONFIG = CONFIG;
}

// Export for module bundlers or Node test runners if needed
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CONFIG;
}
