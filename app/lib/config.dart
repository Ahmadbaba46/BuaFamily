// Supplied at build time, e.g.
//   flutter run --dart-define-from-file=config.json
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
