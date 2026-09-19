/// Configuration constants for Supabase integration.
///
/// Uses publishable/anon credentials only. Never expose service_role or secret keys.
class SupabaseConfig {
  SupabaseConfig._();

  /// The Supabase Project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ezjecnfrrkgehsabzgrg.supabase.co',
  );

  /// The Supabase Publishable / Anon Key.
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_VmyQYEVu-5c6YRUHsg3tIw_gb9r641y',
  );

  /// The private Supabase Storage bucket for patient medical records.
  static const String medicalRecordsBucket = 'medical-records';
}
