// Supabase config via --dart-define, vide = mode local seul.
const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
