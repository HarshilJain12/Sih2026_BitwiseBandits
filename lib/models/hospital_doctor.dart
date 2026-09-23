/// Roster entry for a hospital doctor shown in the Hospital Admin dashboard.
///
/// There is no `/doctors` Firestore collection — the roster is derived from
/// the mock staff directory plus doctors referenced by appointments.
class HospitalDoctor {
  const HospitalDoctor({
    required this.doctorId,
    required this.name,
    required this.specialization,
    this.phone,
    this.onDuty = true,
    this.todayLoad = 0,
  });

  /// Staff login ID, e.g. `DOC001`. Matches [Appointment.doctorId].
  final String doctorId;
  final String name;
  final String specialization;
  final String? phone;

  /// Day availability toggled by the admin (in-memory for now).
  final bool onDuty;

  /// Number of appointments scheduled today (filled in by the service).
  final int todayLoad;

  HospitalDoctor copyWith({bool? onDuty, int? todayLoad}) {
    return HospitalDoctor(
      doctorId: doctorId,
      name: name,
      specialization: specialization,
      phone: phone,
      onDuty: onDuty ?? this.onDuty,
      todayLoad: todayLoad ?? this.todayLoad,
    );
  }
}
