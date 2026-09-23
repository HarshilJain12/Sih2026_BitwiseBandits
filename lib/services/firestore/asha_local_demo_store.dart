import '../../models/asha_worker.dart';
import '../../models/awareness_campaign.dart';
import '../../models/community_health_alert.dart';
import '../../models/family.dart';
import '../../models/family_member.dart';
import '../../models/follow_up.dart';
import '../../models/health_observation.dart';
import '../../models/home_visit.dart';
import '../../models/vaccination_record.dart';

/// In-memory demo dataset for the ASHA module.
///
/// Used automatically when Firestore is unreachable or denies writes
/// (e.g. security rules not deployed), so the one-click demo always shows
/// data. Fresh on every [reset] — no stale or partial cloud data.
class AshaLocalDemoStore {
  final List<Family> families = [];
  final List<FamilyMember> members = [];
  final List<FollowUp> followUps = [];
  final List<VaccinationRecord> vaccinations = [];
  final List<CommunityHealthAlert> alerts = [];
  final List<AwarenessCampaign> campaigns = [];
  final List<HomeVisit> visits = [];
  final List<HealthObservation> observations = [];
  final List<AshaWorker> workers = [];

  int _seq = 0;
  String _id(String prefix) =>
      'local_${prefix}_${_seq++}_${DateTime.now().millisecondsSinceEpoch}';

  /// Clears everything and loads a fresh demo dataset.
  void reset() {
    families.clear();
    members.clear();
    followUps.clear();
    vaccinations.clear();
    alerts.clear();
    campaigns.clear();
    visits.clear();
    observations.clear();
    workers.clear();
    _seed();
  }

  void _seed() {
    final now = DateTime.now();
    const village = 'Kondhwa';
    const ward = 'Ward 4';
    const block = 'Haveli';
    const district = 'Pune';
    const ashaId = 'ASHA001';

    workers.add(AshaWorker.demoWorker);

    Family family(String id, String head, String address, String contact) {
      final f = Family(
        familyId: id,
        headOfFamilyName: head,
        address: address,
        village: village,
        ward: ward,
        block: block,
        district: district,
        contactNumber: contact,
        createdAt: now,
        updatedAt: now,
      );
      families.add(f);
      return f;
    }

    FamilyMember member({
      required String id,
      required String familyId,
      required String name,
      required int age,
      required String gender,
      required String relationship,
      String? phone,
      String? patientId,
      bool pregnancyStatus = false,
      String? expectedDeliveryMonth,
      bool infantStatus = false,
      String? nutritionStatus,
    }) {
      final m = FamilyMember(
        memberId: id,
        familyId: familyId,
        patientId: patientId ?? _id('patient'),
        name: name,
        age: age,
        gender: gender,
        relationship: relationship,
        phone: phone,
        pregnancyStatus: pregnancyStatus,
        expectedDeliveryMonth: expectedDeliveryMonth,
        infantStatus: infantStatus,
        nutritionStatus: nutritionStatus,
        createdAt: now,
        updatedAt: now,
      );
      members.add(m);
      return m;
    }

    final f1 = family('demo_family_1', 'Ramesh Patil',
        'Kondhwa Budruk, Lane 1', '+91 9822011223');
    final f2 = family('demo_family_2', 'Prakash Jadhav',
        'Ward 4, Near Water Tank', '+91 9822044556');
    final f3 = family('demo_family_3', 'Suresh Shinde',
        'Ambedkar Nagar, Plot 14', '+91 9822077889');

    member(id: 'demo_member_ramesh', familyId: f1.familyId, name: 'Ramesh Patil',
        age: 34, gender: 'Male', relationship: 'Head', phone: '+91 9822011223');
    final sunita = member(
        id: 'demo_member_sunita', familyId: f1.familyId, name: 'Sunita Patil',
        age: 28, gender: 'Female', relationship: 'Wife', phone: '+91 9822011224',
        pregnancyStatus: true, expectedDeliveryMonth: 'November 2026',
        nutritionStatus: 'Moderate Anemia (Hb 9.4)');
    final aarav = member(id: 'demo_member_aarav', familyId: f1.familyId,
        name: 'Aarav Patil', age: 2, gender: 'Male', relationship: 'Son',
        infantStatus: true, nutritionStatus: 'Normal Weight for Age');

    final prakash = member(id: 'demo_member_prakash', familyId: f2.familyId,
        name: 'Prakash Jadhav', age: 65, gender: 'Male', relationship: 'Head',
        phone: '+91 9822044556');
    member(id: 'demo_member_suman', familyId: f2.familyId, name: 'Suman Jadhav',
        age: 60, gender: 'Female', relationship: 'Wife');
    final anaya = member(id: 'demo_member_anaya', familyId: f2.familyId,
        name: 'Anaya Jadhav', age: 0, gender: 'Female',
        relationship: 'Granddaughter', infantStatus: true,
        nutritionStatus: 'Exclusively Breastfed');
    member(id: 'demo_member_suresh', familyId: f3.familyId, name: 'Suresh Shinde',
        age: 42, gender: 'Male', relationship: 'Head', phone: '+91 9822077889');

    vaccinations.addAll([
      VaccinationRecord(
        vaccinationId: 'demo_vax_1', patientId: aarav.patientId ?? 'P-1002938471',
        memberId: aarav.memberId, chwId: ashaId,
        vaccineName: 'MR-1 (Measles & Rubella)',
        vaccineType: 'Routine Infant Immunization',
        scheduledDate: now.add(const Duration(days: 3)), status: 'scheduled',
        createdAt: now, updatedAt: now),
      VaccinationRecord(
        vaccinationId: 'demo_vax_2', patientId: anaya.patientId ?? 'P-1002938472',
        memberId: anaya.memberId, chwId: ashaId,
        vaccineName: 'Pentavalent-1 & OPV-1',
        vaccineType: 'Routine Infant Immunization',
        scheduledDate: now.add(const Duration(days: 7)), status: 'scheduled',
        createdAt: now, updatedAt: now),
    ]);

    followUps.addAll([
      FollowUp(
        followUpId: 'demo_fu_1', ashaId: ashaId, memberId: sunita.memberId,
        familyId: f1.familyId, type: 'pregnancy',
        description: '2nd Trimester ANC Check & IFA tablet adherence check. Check BP & Hb.',
        scheduledDate: now.add(const Duration(days: 2)), status: 'pending',
        createdAt: now, updatedAt: now),
      FollowUp(
        followUpId: 'demo_fu_2', ashaId: ashaId, memberId: prakash.memberId,
        familyId: f2.familyId, type: 'hypertension',
        description: 'Hypertension monitoring & salt counseling. Last BP 155/98 mmHg.',
        scheduledDate: now.add(const Duration(days: 5)), status: 'pending',
        createdAt: now, updatedAt: now),
    ]);

    alerts.addAll([
      CommunityHealthAlert(
        alertId: 'demo_alert_1', ashaId: ashaId, ashaName: 'Sunita Sharma',
        issueType: 'Water Contamination',
        description: 'Drinking water pipeline contamination observed near Lane 2 public tap.',
        village: village, ward: ward, severity: 'high', status: 'pending',
        voiceTranscript: 'Drinking water pipeline contamination observed near Lane 2 public tap.',
        createdAt: now, updatedAt: now),
      CommunityHealthAlert(
        alertId: 'demo_alert_2', ashaId: ashaId, ashaName: 'Sunita Sharma',
        issueType: 'Dengue Concern',
        description: 'Stagnant water and mosquito breeding near open gutter by primary school.',
        village: village, ward: ward, severity: 'medium', status: 'pending',
        voiceTranscript: 'Stagnant water and mosquito breeding near open gutter by primary school.',
        createdAt: now, updatedAt: now),
    ]);

    // Published (unlike the cloud seeder's draft) so the Awareness tab shows it.
    campaigns.add(AwarenessCampaign(
      campaignId: 'demo_campaign_1',
      title: 'Mission Indradhanush Immunization Drive',
      description: 'Special weekend vaccination drive for children under 5 and pregnant women.',
      safetyInstructions: 'Bring immunization card and aadhaar card if available.',
      hospitalName: 'Kondhwa PHC Health Center',
      targetVillages: const [village],
      targetWards: const [ward],
      targetType: 'general',
      status: 'published',
      createdBy: ashaId,
      createdAt: now,
      updatedAt: now,
    ));

    visits.add(HomeVisit(
      visitId: 'demo_visit_1', ashaId: ashaId, familyId: f1.familyId,
      date: now, status: 'completed', createdAt: now, updatedAt: now));
  }

  // ─── Reads ─────────────────────────────────────────────────────────────
  List<Family> familiesByVillage(String village) =>
      families.where((f) => f.village == village).toList();

  List<FamilyMember> membersOf(String familyId) =>
      members.where((m) => m.familyId == familyId).toList();

  List<FamilyMember> pregnantWomen(String village) {
    final ids = familiesByVillage(village).map((f) => f.familyId).toSet();
    return members
        .where((m) => ids.contains(m.familyId) && m.pregnancyStatus)
        .toList();
  }

  List<FamilyMember> infants(String village) {
    final ids = familiesByVillage(village).map((f) => f.familyId).toSet();
    return members
        .where((m) => ids.contains(m.familyId) && m.infantStatus)
        .toList();
  }

  List<HomeVisit> visitsByAsha(String ashaId) {
    final list = visits.where((v) => v.ashaId == ashaId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<FollowUp> followUpsByAsha(String ashaId) {
    final list = followUps.where((f) => f.ashaId == ashaId).toList();
    list.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return list;
  }

  List<CommunityHealthAlert> pendingAlerts() {
    final list = alerts.where((a) => a.status == 'pending').toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<CommunityHealthAlert> allAlerts() {
    final list = List<CommunityHealthAlert>.from(alerts);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<AwarenessCampaign> publishedCampaigns() =>
      campaigns.where((c) => c.status == 'published').toList();

  List<VaccinationRecord> vaccinationsByChw(String chwId) {
    final list = vaccinations.where((v) => v.chwId == chwId).toList();
    list.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return list;
  }

  Map<String, int> dashboardStats(String ashaId, String village) {
    final fams = familiesByVillage(village);
    final ids = fams.map((f) => f.familyId).toSet();
    final all = members.where((m) => ids.contains(m.familyId)).toList();
    final today = DateTime.now();
    final todayCount = visitsByAsha(ashaId).where((v) =>
        v.date.year == today.year &&
        v.date.month == today.month &&
        v.date.day == today.day).length;
    return {
      'todayVisits': todayCount,
      'totalFamilies': fams.length,
      'totalMembers': all.length,
      'pregnantWomen': all.where((m) => m.pregnancyStatus).length,
      'infants': all.where((m) => m.infantStatus).length,
      'vaccinationsDue': vaccinationsByChw(ashaId)
          .where((v) => v.status == 'scheduled' || v.status == 'pending')
          .length,
      'followUpsDue': followUpsByAsha(ashaId)
          .where((f) => f.status == 'pending')
          .length,
    };
  }

  // ─── Writes (kept in memory so the whole demo stays functional) ─────────
  Family createFamily({
    required String headOfFamilyName,
    required String address,
    required String village,
    required String ward,
    required String block,
    required String district,
    required String contactNumber,
  }) {
    final now = DateTime.now();
    final family = Family(
      familyId: _id('family'), headOfFamilyName: headOfFamilyName,
      address: address, village: village, ward: ward, block: block,
      district: district, contactNumber: contactNumber,
      createdAt: now, updatedAt: now);
    families.add(family);
    return family;
  }

  FamilyMember addFamilyMember({
    required String familyId,
    required String name,
    required int age,
    required String gender,
    required String relationship,
    String? phone,
    bool pregnancyStatus = false,
    String? expectedDeliveryMonth,
    bool infantStatus = false,
    String? nutritionStatus,
    String? existingPatientId,
  }) {
    final now = DateTime.now();
    final member = FamilyMember(
      memberId: _id('member'), familyId: familyId,
      patientId: existingPatientId ?? _id('patient'),
      name: name, age: age, gender: gender, relationship: relationship,
      phone: phone, pregnancyStatus: pregnancyStatus,
      expectedDeliveryMonth: expectedDeliveryMonth, infantStatus: infantStatus,
      nutritionStatus: nutritionStatus, createdAt: now, updatedAt: now);
    members.add(member);
    return member;
  }

  HomeVisit createHomeVisit({required String ashaId, required String familyId}) {
    final now = DateTime.now();
    final visit = HomeVisit(
        visitId: _id('visit'), ashaId: ashaId, familyId: familyId,
        date: now, status: 'completed', createdAt: now, updatedAt: now);
    visits.add(visit);
    return visit;
  }

  HealthObservation createObservation({
    required String visitId,
    required String memberId,
    String? generalHealth,
    String? maternalHealth,
    String? infantHealth,
    String? nutrition,
    bool followUpRequired = false,
    DateTime? followUpDate,
  }) {
    final now = DateTime.now();
    final obs = HealthObservation(
        observationId: _id('obs'), visitId: visitId, memberId: memberId,
        generalHealth: generalHealth, maternalHealth: maternalHealth,
        infantHealth: infantHealth, nutrition: nutrition,
        followUpRequired: followUpRequired, followUpDate: followUpDate,
        createdAt: now, updatedAt: now);
    observations.add(obs);
    return obs;
  }

  FollowUp createFollowUp({
    required String ashaId,
    required String memberId,
    required String familyId,
    required String type,
    required String description,
    required DateTime scheduledDate,
  }) {
    final now = DateTime.now();
    final fu = FollowUp(
        followUpId: _id('fu'), ashaId: ashaId, memberId: memberId,
        familyId: familyId, type: type, description: description,
        scheduledDate: scheduledDate, status: 'pending',
        createdAt: now, updatedAt: now);
    followUps.add(fu);
    return fu;
  }

  void completeFollowUp(String followUpId) {
    final i = followUps.indexWhere((f) => f.followUpId == followUpId);
    if (i == -1) return;
    final f = followUps[i];
    followUps[i] = FollowUp(
        followUpId: f.followUpId, ashaId: f.ashaId, memberId: f.memberId,
        familyId: f.familyId, type: f.type, description: f.description,
        scheduledDate: f.scheduledDate, status: 'completed',
        completedDate: DateTime.now(), notes: f.notes,
        createdAt: f.createdAt, updatedAt: DateTime.now());
  }

  CommunityHealthAlert submitAlert({
    required String ashaId,
    required String ashaName,
    required String issueType,
    required String description,
    required String village,
    required String ward,
    required String severity,
    String? voiceTranscript,
    int? affectedPopulation,
  }) {
    final now = DateTime.now();
    final alert = CommunityHealthAlert(
        alertId: _id('alert'), ashaId: ashaId, ashaName: ashaName,
        issueType: issueType, description: description, village: village,
        ward: ward, severity: severity, status: 'pending',
        voiceTranscript: voiceTranscript, affectedPopulation: affectedPopulation,
        createdAt: now, updatedAt: now);
    alerts.add(alert);
    return alert;
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

  AwarenessCampaign createCampaign({
    String? alertId,
    required String title,
    required String description,
    required String safetyInstructions,
    required String hospitalName,
    String? contactInfo,
    required List<String> targetVillages,
    required List<String> targetWards,
    required String targetType,
    required String createdBy,
  }) {
    final now = DateTime.now();
    final c = AwarenessCampaign(
        campaignId: _id('campaign'), alertId: alertId, title: title,
        description: description, safetyInstructions: safetyInstructions,
        hospitalName: hospitalName, contactInfo: contactInfo,
        targetVillages: targetVillages, targetWards: targetWards,
        targetType: targetType, status: 'draft', createdBy: createdBy,
        createdAt: now, updatedAt: now);
    campaigns.add(c);
    return c;
  }

  void publishCampaign(String campaignId) {
    final i = campaigns.indexWhere((c) => c.campaignId == campaignId);
    if (i == -1) return;
    final c = campaigns[i];
    campaigns[i] = AwarenessCampaign(
        campaignId: c.campaignId, alertId: c.alertId, title: c.title,
        description: c.description, safetyInstructions: c.safetyInstructions,
        hospitalName: c.hospitalName, contactInfo: c.contactInfo,
        targetVillages: c.targetVillages, targetWards: c.targetWards,
        targetType: c.targetType, status: 'published', createdBy: c.createdBy,
        createdAt: c.createdAt, updatedAt: DateTime.now());
  }

  VaccinationRecord scheduleVaccination({
    required String patientId,
    String? memberId,
    required String chwId,
    required String vaccineName,
    required String vaccineType,
    required DateTime scheduledDate,
  }) {
    final now = DateTime.now();
    final v = VaccinationRecord(
        vaccinationId: _id('vax'), patientId: patientId, memberId: memberId,
        chwId: chwId, vaccineName: vaccineName, vaccineType: vaccineType,
        scheduledDate: scheduledDate, status: 'scheduled',
        createdAt: now, updatedAt: now);
    vaccinations.add(v);
    return v;
  }

  void administerVaccination(String vaccinationId, {String? remarks}) {
    final i = vaccinations.indexWhere((v) => v.vaccinationId == vaccinationId);
    if (i == -1) return;
    final v = vaccinations[i];
    vaccinations[i] = VaccinationRecord(
        vaccinationId: v.vaccinationId, patientId: v.patientId,
        memberId: v.memberId, chwId: v.chwId, vaccineName: v.vaccineName,
        vaccineType: v.vaccineType, scheduledDate: v.scheduledDate,
        administeredDate: DateTime.now(), status: 'administered',
        remarks: remarks ?? v.remarks,
        createdAt: v.createdAt, updatedAt: DateTime.now());
  }

  AshaWorker? login(String ashaId, String password) {
    if (ashaId == AshaWorker.demoWorker.ashaId && password == '123456') {
      if (!workers.any((w) => w.ashaId == ashaId)) {
        workers.add(AshaWorker.demoWorker);
      }
      return AshaWorker.demoWorker;
    }
    try {
      return workers.firstWhere((w) => w.ashaId == ashaId);
    } catch (_) {
      return null;
    }
  }
}
