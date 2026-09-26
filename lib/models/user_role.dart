/// The four user roles in Arogya Seva.
///
/// Add new roles here as the system grows. Route guards and dashboards
/// can switch on this enum in later chunks.
enum UserRole {
  patient,
  asha,
  doctor,
  hospitalAdmin;

  /// Serializable key for persisting / passing as route parameter.
  String get key => name;

  static UserRole? fromKey(String key) {
    return UserRole.values.where((r) => r.key == key).firstOrNull;
  }
}
