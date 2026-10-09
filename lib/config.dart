// Supabase config via --dart-define ou defaults Tradingworkspace
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://hvxslvdqnwaafvdanasf.supabase.co',
);
const supabaseKey = String.fromEnvironment(
  'SUPABASE_KEY',
  defaultValue: 'sb_publishable_wvvtlC4ym1GS8VvXhR2wWA_Pg5OLHy3',
);
bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
