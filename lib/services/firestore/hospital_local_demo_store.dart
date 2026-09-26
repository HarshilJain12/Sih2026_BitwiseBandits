import '../../models/appointment.dart';
import '../../models/asha_worker.dart';
import '../../models/awareness_campaign.dart';
import '../../models/community_health_alert.dart';
import '../../models/hospital_doctor.dart';
import '../../models/opd_appointment.dart';
import '../../models/patient.dart';

/// In-memory demo dataset for the Hospital Admin dashboard.
///
/// Mirrors [AshaLocalDemoStore]: used automatically when Firestore is
/// unreachable or denies access, so the admin demo always shows data.
class HospitalLocalDemoStore {
  final List<HospitalDoctor> doctors = [];
  final List<Patient> patients = [];
  final List<Appointment> appointments = [];
  final List<OpdAppointment> opdAppointments = [];
  final List<CommunityHealthAlert> alerts = [];
  final List<AwarenessCampaign> campaigns = [];
  final List<AshaWorker> workers = [];
  final Map<String, bool> duty = {};

  int _seq = 0;
  String _id(String prefix) =>
      'local_${prefix}_${_seq++}_${DateTime.now().millisecondsSinceEpoch}';

  /// Clears everything and loads a fresh demo dataset.
  void reset() {
    doctors.clear();
    patients.clear();
    appointments.clear();
    opdAppointments.clear();
    alerts.clear();
    campaigns.clear();
    workers.clear();
    duty.clear();
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    doctors.addAll(const [
      HospitalDoctor(
          doctorId: 'DOC001', name: 'Rajesh Sharma',
          specialization: 'General Medicine', phone: '+91 9810010011'),
      HospitalDoctor(
          doctorId: 'DOC002', name: 'Priya Mehta',
          specialization: 'Pediatrics', phone: '+91 9810010012'),
      HospitalDoctor(
          doctorId: 'DOC003', name: 'Amit Deshmukh',
          specialization: 'Orthopedics', phone: '+91 9810010013'),
      HospitalDoctor(
          doctorId: 'DOC004', name: 'Sneha Kulkarni',
          specialization: 'Gynecology', phone: '+91 9810010014'),
    ]);
    for (final d in doctors) {
      duty[d.doctorId] = true;
    }

    Patient patient(String id, String name, String phone, int age,
        List<String> tags, {String? qrToken}) {
      final p = Patient(
        patientId: id, ownerUid: 'demo-owner', name: name, phoneNumber: phone,
        age: age, createdAt: now, updatedAt: now, healthTags: tags,
        qrToken: qrToken ?? 'QRT-${id.replaceAll('-', '')}',
        qrVersion: 1,
      );
      patients.add(p);
      return p;
    }

    final p1 = patient('P-1002938471', 'Rahul Kumar', '+91 9822011223', 34, const ['Hypertension']);
    final p2 = patient('P-1002938472', 'Anjali Singh', '+91 9822011224', 28, const ['Pregnant']);
    final p3 = patient('P-1002938473', 'Priya Patil', '+91 9822011225', 45, const ['Diabetic']);
    final p4 = patient('P-1002938474', 'Suresh Jadhav', '+91 9822011226', 65, const ['Hypertension', 'Cardiac']);
    final p5 = patient('P-1002938475', 'Meena Deshmukh', '+91 9822011227', 52, const []);
    final p6 = patient('P-1002938476', 'Aarav Patil', '+91 9822011228', 2, const []);
    final p7 = patient('P-1002938477', 'Sunita Patil', '+91 9822011229', 28, const ['Pregnant', 'Anemia']);
    final p8 = patient('P-1002938478', 'Prakash Jadhav', '+91 9822011230', 65, const ['Hypertension']);
    // Seed same-name patients for testing disambiguation via mobile number:
    patient('P-1002938479', 'Vikram Shinde', '+91 9876543212', 22, const []);
    patient('P-1002938480', 'Vikram Shinde', '+91 9123456780', 25, const ['Diabetic']);
    patient('P-1002938481', 'Vikram Kumar', '+91 8712345645', 27, const []);

    // OPD queue for today: completed → in-consultation → waiting.
    Appointment apt(Patient p, HospitalDoctor d, int hour, int minute,
        String status, String type) {
      final a = Appointment(
        appointmentId: _id('apt'), patientId: p.patientId, patientName: p.name,
        doctorId: d.doctorId, doctorName: d.name,
        scheduledAt: today.add(Duration(hours: hour, minutes: minute)),
        status: status, type: type, createdAt: now);
      appointments.add(a);
      return a;
    }

    final d1 = doctors[0], d2 = doctors[1], d3 = doctors[2], d4 = doctors[3];
    apt(p1, d1, 9, 0, 'completed', 'consultation');
    apt(p2, d1, 9, 30, 'completed', 'follow_up');
    apt(p3, d1, 10, 0, 'current', 'consultation');
    apt(p4, d1, 10, 30, 'upcoming', 'routine_checkup');
    apt(p5, d1, 11, 0, 'upcoming', 'consultation');
    apt(p6, d2, 9, 15, 'completed', 'consultation');
    apt(p7, d4, 9, 45, 'current', 'consultation');
    apt(p8, d3, 10, 15, 'upcoming', 'consultation');
    apt(p2, d2, 11, 30, 'upcoming', 'follow_up');
    // One entry for tomorrow (not part of today's queue).
    appointments.add(Appointment(
      appointmentId: _id('apt'), patientId: p5.patientId, patientName: p5.name,
      doctorId: d3.doctorId, doctorName: d3.name,
      scheduledAt: today.add(const Duration(days: 1, hours: 10)),
      status: 'upcoming', type: 'follow_up', createdAt: now));

    alerts.addAll([
      CommunityHealthAlert(
        alertId: 'demo_alert_1', ashaId: 'ASHA001', ashaName: 'Sunita Sharma',
        issueType: 'Water Contamination',
        description: 'Drinking water pipeline contamination observed near Lane 2 public tap.',
        village: 'Kondhwa', ward: 'Ward 4', severity: 'high', status: 'pending',
        createdAt: now, updatedAt: now),
      CommunityHealthAlert(
        alertId: 'demo_alert_2', ashaId: 'ASHA001', ashaName: 'Sunita Sharma',
        issueType: 'Dengue Concern',
        description: 'Stagnant water and mosquito breeding near open gutter by primary school.',
        village: 'Kondhwa', ward: 'Ward 4', severity: 'medium', status: 'pending',
        createdAt: now, updatedAt: now),
    ]);

    campaigns.add(AwarenessCampaign(
      campaignId: 'demo_campaign_1',
      title: 'Mission Indradhanush Immunization Drive',
      description: 'Special weekend vaccination drive for children under 5 and pregnant women.',
      safetyInstructions: 'Bring immunization card and aadhaar card if available.',
      hospitalName: 'Kondhwa PHC Health Center',
      targetVillages: const ['Kondhwa'], targetWards: const ['Ward 4'],
      targetType: 'general', status: 'published', createdBy: 'ADMIN001',
      createdAt: now, updatedAt: now));

    workers.addAll([
      AshaWorker.demoWorker,
      AshaWorker(
        id: 'demo_asha_002', ashaId: 'ASHA002', name: 'Meena Pawar',
        phone: '+91 9876543211', passwordHash: 'proto_hash_MTIzNDU2',
        state: 'Maharashtra', district: 'Pune', block: 'Haveli',
        village: 'Kondhwa', wardId: 'Ward 5', createdAt: now, updatedAt: now),
      AshaWorker(
        id: 'demo_asha_003', ashaId: 'ASHA003', name: 'Lata Shinde',
        phone: '+91 9876543212', passwordHash: 'proto_hash_MTIzNDU2',
        state: 'Maharashtra', district: 'Pune', block: 'Haveli',
        village: 'Katraj', wardId: 'Ward 2', createdAt: now, updatedAt: now),
    ]);
  }

  // ─── Queue helpers ───────────────────────────────────────────────────
  List<Appointment> _sorted(List<Appointment> list) {
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// Today's live OPD queue (waiting + in-consultation), oldest first.
  List<Appointment> todayQueue() => _sorted(appointments
      .where((a) =>
          _isToday(a.scheduledAt) &&
          (a.status == 'upcoming' || a.status == 'current'))
      .toList());

  List<Appointment> todayCompleted() => _sorted(appointments
      .where((a) => _isToday(a.scheduledAt) && a.status == 'completed')
      .toList());

  List<Appointment> allAppointments() => _sorted(List.of(appointments));

  List<Appointment> queueForDoctor(String doctorId) =>
      todayQueue().where((a) => a.doctorId == doctorId).toList();

  void updateStatus(String appointmentId, String status) {
    final i = appointments.indexWhere((a) => a.appointmentId == appointmentId);
    if (i == -1) return;
    appointments[i] = appointments[i].copyWith(status: status);
  }

  /// Moves the next waiting token of a doctor into consultation.
  void callNext(String doctorId) {
    final waiting = queueForDoctor(doctorId)
        .where((a) => a.status == 'upcoming')
        .toList();
    if (waiting.isEmpty) return;
    updateStatus(waiting.first.appointmentId, 'current');
  }

  // ─── Directory helpers ─────────────────────────────────────────────
  List<Patient> searchPatients(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.of(patients);
    return patients
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.patientId.toLowerCase().contains(q) ||
            p.phoneNumber.contains(q))
        .toList();
  }

  List<HospitalDoctor> roster() => doctors
      .map((d) => d.copyWith(
            onDuty: duty[d.doctorId] ?? true,
            todayLoad: appointments
                .where((a) =>
                    a.doctorId == d.doctorId && _isToday(a.scheduledAt))
                .length,
          ))
      .toList();

  void setDuty(String doctorId, bool onDuty) => duty[doctorId] = onDuty;

  List<CommunityHealthAlert> pendingAlerts() => alerts
      .where((a) => a.status == 'pending')
      .toList();

  List<CommunityHealthAlert> allAlerts() {
    final list = List<CommunityHealthAlert>.from(alerts);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void updateAlertStatus(String alertId, String status) {
    final i = alerts.indexWhere((a) => a.alertId == alertId);
    if (i == -1) return;
    final a = alerts[i];
    alerts[i] = CommunityHealthAlert(
      alertId: a.alertId, ashaId: a.ashaId, ashaName: a.ashaName,
      issueType: a.issueType, description: a.description, village: a.village,
      ward: a.ward, severity: a.severity, status: status,
      voiceTranscript: a.voiceTranscript,
      affectedPopulation: a.affectedPopulation, photoUrl: a.photoUrl,
      createdAt: a.createdAt, updatedAt: DateTime.now());
  }

  // ─── OPD Appointment Slip Management ────────────────────────────────
  OpdAppointment createOpdAppointment(OpdAppointment appointment) {
    // Determine assigned doctor based on category if matching doctor exists
    HospitalDoctor? assignedDoc;
    for (final d in doctors) {
      if (d.specialization.toLowerCase() ==
          appointment.doctorCategory.toLowerCase()) {
        assignedDoc = d;
        break;
      }
    }
    assignedDoc ??= doctors.isNotEmpty ? doctors.first : null;

    final assignedDoctorId = appointment.doctorId ?? assignedDoc?.doctorId ?? 'DOC001';
    final assignedDoctorName =
        appointment.doctorName ?? assignedDoc?.name ?? appointment.doctorCategory;

    final effectiveAppt = appointment.copyWith(
      doctorId: assignedDoctorId,
      doctorName: assignedDoctorName,
    );

    opdAppointments.add(effectiveAppt);

    // Also add to active appointments queue so it appears in the doctor queue & stats
    final generalApt = Appointment(
      appointmentId: effectiveAppt.appointmentId,
      patientId: effectiveAppt.patientId ?? 'WALK_IN_${DateTime.now().millisecondsSinceEpoch}',
      patientName: effectiveAppt.patientName,
      doctorId: assignedDoctorId,
      doctorName: assignedDoctorName,
      scheduledAt: effectiveAppt.appointmentDate,
      status: effectiveAppt.status,
      type: 'opd_slip',
      notes: effectiveAppt.doctorCategory,
      createdAt: effectiveAppt.createdAt,
    );
    appointments.add(generalApt);

    return effectiveAppt;
  }

  List<OpdAppointment> allOpdAppointments() => List.unmodifiable(opdAppointments);

  List<OpdAppointment> todayOpdAppointments() =>
      opdAppointments.where((o) => _isToday(o.appointmentDate)).toList();

  Map<String, int> overview() {
    final queue = todayQueue();
    return {
      'totalPatients': patients.length,
      'totalDoctors': doctors.length,
      'doctorsOnDuty': duty.values.where((v) => v).length,
      'todayAppointments': queue.length + todayCompleted().length,
      'opdWaiting': queue.where((a) => a.status == 'upcoming').length,
      'opdInConsultation': queue.where((a) => a.status == 'current').length,
      'completedToday': todayCompleted().length,
      'pendingAlerts': pendingAlerts().length,
      'activeAshaWorkers': workers.length,
      'publishedCampaigns': campaigns.where((c) => c.status == 'published').length,
    };
  }
}

