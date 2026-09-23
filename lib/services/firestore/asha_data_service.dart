import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/asha_worker.dart';
import '../../models/awareness_campaign.dart';
import '../../models/community_health_alert.dart';
import '../../models/family.dart';
import '../../models/family_member.dart';
import '../../models/follow_up.dart';
import '../../models/health_observation.dart';
import '../../models/home_visit.dart';
import '../../models/vaccination_record.dart';
import 'asha_local_demo_store.dart';

/// Service layer for all ASHA Worker Firestore operations.
///
/// Uses the centralized Firestore database — does NOT create separate databases.
class AshaDataService {
  AshaDataService();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// When true, all reads/writes are served from a built-in in-memory demo
  /// dataset instead of Firestore — used automatically when Firestore is
  /// unreachable or denies access, so the one-click demo always shows data.
  bool localDemoMode = false;

  /// In-memory demo dataset (fresh after every [enableLocalDemo]).
  final AshaLocalDemoStore localStore = AshaLocalDemoStore();

  /// Switches to the offline demo dataset with a clean slate.
  void enableLocalDemo() {
    localDemoMode = true;
    localStore.reset();
  }

  /// Switches back to Firestore (e.g. after security rules are deployed).
  void disableLocalDemo() {
    localDemoMode = false;
  }

  // ─── Collections ────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _ashaWorkers =>
      _db.collection('asha_workers');
  CollectionReference<Map<String, dynamic>> get _families =>
      _db.collection('families');
  CollectionReference<Map<String, dynamic>> get _familyMembers =>
      _db.collection('family_members');
  CollectionReference<Map<String, dynamic>> get _homeVisits =>
      _db.collection('home_visits');
  CollectionReference<Map<String, dynamic>> get _healthObservations =>
      _db.collection('health_observations');
  CollectionReference<Map<String, dynamic>> get _followUps =>
      _db.collection('follow_ups');
  CollectionReference<Map<String, dynamic>> get _communityAlerts =>
      _db.collection('community_health_alerts');
  CollectionReference<Map<String, dynamic>> get _awarenessCampaigns =>
      _db.collection('awareness_campaigns');
  CollectionReference<Map<String, dynamic>> get _vaccinations =>
      _db.collection('vaccination_records');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  // ─── Password Hashing (prototype-safe) ──────────────────────────────────
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = base64Encode(bytes);
    return 'proto_hash_$hash';
  }

  bool _verifyPassword(String password, String storedHash) {
    return _hashPassword(password) == storedHash;
  }

  // ─── ASHA Registration ──────────────────────────────────────────────────
  Future<AshaWorker?> registerAshaWorker({
    required String ashaId,
    required String name,
    required String phone,
    required String password,
    required String state,
    required String district,
    required String block,
    required String village,
    required String wardId,
  }) async {
    if (localDemoMode) {
      final now = DateTime.now();
      final worker = AshaWorker(
        id: 'local_asha_${now.millisecondsSinceEpoch}',
        ashaId: ashaId,
        name: name,
        phone: phone,
        passwordHash: _hashPassword(password),
        state: state,
        district: district,
        block: block,
        village: village,
        wardId: wardId,
        createdAt: now,
        updatedAt: now,
      );
      localStore.workers.add(worker);
      return worker;
    }
    // Check uniqueness
    final existing = await _ashaWorkers
        .where('ashaId', isEqualTo: ashaId)
        .limit(1)
        .get()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception(
            'Connection timed out. Please check your internet or Firebase security rules.',
          ),
        );
    if (existing.docs.isNotEmpty) return null; // Already exists

    final doc = _ashaWorkers.doc();
    final now = DateTime.now();
    final worker = AshaWorker(
      id: doc.id,
      ashaId: ashaId,
      name: name,
      phone: phone,
      passwordHash: _hashPassword(password),
      state: state,
      district: district,
      block: block,
      village: village,
      wardId: wardId,
      createdAt: now,
      updatedAt: now,
    );
    await doc
        .set(worker.toFirestore(useServerTimestamp: true))
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception(
            'Save timed out. Please check your internet or Firebase security rules.',
          ),
        );
    return worker;
  }

  // ─── ASHA Login ─────────────────────────────────────────────────────────
  Future<AshaWorker?> loginAshaWorker(String ashaId, String password) async {
    if (localDemoMode) return localStore.login(ashaId, password);
    final snap = await _ashaWorkers
        .where('ashaId', isEqualTo: ashaId)
        .limit(1)
        .get()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw Exception(
            'Connection timed out. Please check your internet or Firebase security rules.',
          ),
        );
    if (snap.docs.isEmpty) return null;
    final worker = AshaWorker.fromFirestore(snap.docs.first);
    if (!_verifyPassword(password, worker.passwordHash)) return null;
    return worker;
  }

  // ─── Family CRUD ────────────────────────────────────────────────────────
  Future<Family> createFamily({
    required String headOfFamilyName,
    required String address,
    required String village,
    required String ward,
    required String block,
    required String district,
    required String contactNumber,
  }) async {
    if (localDemoMode) {
      return localStore.createFamily(
        headOfFamilyName: headOfFamilyName,
        address: address,
        village: village,
        ward: ward,
        block: block,
        district: district,
        contactNumber: contactNumber,
      );
    }
    final doc = _families.doc();
    final now = DateTime.now();
    final family = Family(
      familyId: doc.id,
      headOfFamilyName: headOfFamilyName,
      address: address,
      village: village,
      ward: ward,
      block: block,
      district: district,
      contactNumber: contactNumber,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(family.toFirestore(useServerTimestamp: true));
    return family;
  }

  Future<List<Family>> getFamiliesByVillage(String village) async {
    if (localDemoMode) return localStore.familiesByVillage(village);
    final snap = await _families
        .where('village', isEqualTo: village)
        .get();
    return snap.docs.map((d) => Family.fromFirestore(d)).toList();
  }

  // ─── Family Member CRUD ─────────────────────────────────────────────────
  String _generatePatientId() {
    final rand = Random();
    final id = List.generate(10, (_) => rand.nextInt(10)).join();
    return 'P-$id';
  }

  Future<FamilyMember> addFamilyMember({
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
  }) async {
    if (localDemoMode) {
      return localStore.addFamilyMember(
        familyId: familyId,
        name: name,
        age: age,
        gender: gender,
        relationship: relationship,
        phone: phone,
        pregnancyStatus: pregnancyStatus,
        expectedDeliveryMonth: expectedDeliveryMonth,
        infantStatus: infantStatus,
        nutritionStatus: nutritionStatus,
        existingPatientId: existingPatientId,
      );
    }
    final doc = _familyMembers.doc();
    final now = DateTime.now();
    final member = FamilyMember(
      memberId: doc.id,
      familyId: familyId,
      patientId: existingPatientId ?? _generatePatientId(),
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
    await doc.set(member.toFirestore(useServerTimestamp: true));
    return member;
  }

  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    if (localDemoMode) return localStore.membersOf(familyId);
    final snap = await _familyMembers
        .where('familyId', isEqualTo: familyId)
        .get();
    return snap.docs.map((d) => FamilyMember.fromFirestore(d)).toList();
  }

  Future<List<FamilyMember>> getPregnantWomen(String village) async {
    if (localDemoMode) return localStore.pregnantWomen(village);
    final families = await getFamiliesByVillage(village);
    final members = <FamilyMember>[];
    for (final f in families) {
      final snap = await _familyMembers
          .where('familyId', isEqualTo: f.familyId)
          .where('pregnancyStatus', isEqualTo: true)
          .get();
      members.addAll(snap.docs.map((d) => FamilyMember.fromFirestore(d)));
    }
    return members;
  }

  Future<List<FamilyMember>> getInfants(String village) async {
    if (localDemoMode) return localStore.infants(village);
    final families = await getFamiliesByVillage(village);
    final members = <FamilyMember>[];
    for (final f in families) {
      final snap = await _familyMembers
          .where('familyId', isEqualTo: f.familyId)
          .where('infantStatus', isEqualTo: true)
          .get();
      members.addAll(snap.docs.map((d) => FamilyMember.fromFirestore(d)));
    }
    return members;
  }

  // ─── Home Visit CRUD ────────────────────────────────────────────────────
  Future<HomeVisit> createHomeVisit({
    required String ashaId,
    required String familyId,
  }) async {
    if (localDemoMode) {
      return localStore.createHomeVisit(ashaId: ashaId, familyId: familyId);
    }
    final doc = _homeVisits.doc();
    final now = DateTime.now();
    final visit = HomeVisit(
      visitId: doc.id,
      ashaId: ashaId,
      familyId: familyId,
      date: now,
      status: 'completed',
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(visit.toFirestore(useServerTimestamp: true));
    return visit;
  }

  Future<List<HomeVisit>> getVisitsByAsha(String ashaId) async {
    if (localDemoMode) return localStore.visitsByAsha(ashaId);
    final snap = await _homeVisits
        .where('ashaId', isEqualTo: ashaId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => HomeVisit.fromFirestore(d)).toList();
  }

  // ─── Health Observation CRUD ────────────────────────────────────────────
  Future<HealthObservation> createObservation({
    required String visitId,
    required String memberId,
    String? generalHealth,
    String? maternalHealth,
    String? infantHealth,
    String? nutrition,
    bool followUpRequired = false,
    DateTime? followUpDate,
  }) async {
    if (localDemoMode) {
      return localStore.createObservation(
        visitId: visitId,
        memberId: memberId,
        generalHealth: generalHealth,
        maternalHealth: maternalHealth,
        infantHealth: infantHealth,
        nutrition: nutrition,
        followUpRequired: followUpRequired,
        followUpDate: followUpDate,
      );
    }
    final doc = _healthObservations.doc();
    final now = DateTime.now();
    final obs = HealthObservation(
      observationId: doc.id,
      visitId: visitId,
      memberId: memberId,
      generalHealth: generalHealth,
      maternalHealth: maternalHealth,
      infantHealth: infantHealth,
      nutrition: nutrition,
      followUpRequired: followUpRequired,
      followUpDate: followUpDate,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(obs.toFirestore(useServerTimestamp: true));
    return obs;
  }

  // ─── Follow-Up CRUD ────────────────────────────────────────────────────
  Future<FollowUp> createFollowUp({
    required String ashaId,
    required String memberId,
    required String familyId,
    required String type,
    required String description,
    required DateTime scheduledDate,
  }) async {
    if (localDemoMode) {
      return localStore.createFollowUp(
        ashaId: ashaId,
        memberId: memberId,
        familyId: familyId,
        type: type,
        description: description,
        scheduledDate: scheduledDate,
      );
    }
    final doc = _followUps.doc();
    final now = DateTime.now();
    final followUp = FollowUp(
      followUpId: doc.id,
      ashaId: ashaId,
      memberId: memberId,
      familyId: familyId,
      type: type,
      description: description,
      scheduledDate: scheduledDate,
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(followUp.toFirestore(useServerTimestamp: true));
    return followUp;
  }

  Future<List<FollowUp>> getFollowUpsByAsha(String ashaId) async {
    if (localDemoMode) return localStore.followUpsByAsha(ashaId);
    final snap = await _followUps
        .where('ashaId', isEqualTo: ashaId)
        .orderBy('scheduledDate')
        .get();
    return snap.docs.map((d) => FollowUp.fromFirestore(d)).toList();
  }

  Future<void> completeFollowUp(String followUpId) async {
    if (localDemoMode) {
      localStore.completeFollowUp(followUpId);
      return;
    }
    await _followUps.doc(followUpId).update({
      'status': 'completed',
      'completedDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Community Health Alerts ────────────────────────────────────────────
  Future<CommunityHealthAlert> submitAlert({
    required String ashaId,
    required String ashaName,
    required String issueType,
    required String description,
    required String village,
    required String ward,
    required String severity,
    String? voiceTranscript,
    int? affectedPopulation,
  }) async {
    if (localDemoMode) {
      return localStore.submitAlert(
        ashaId: ashaId,
        ashaName: ashaName,
        issueType: issueType,
        description: description,
        village: village,
        ward: ward,
        severity: severity,
        voiceTranscript: voiceTranscript,
        affectedPopulation: affectedPopulation,
      );
    }
    final doc = _communityAlerts.doc();
    final now = DateTime.now();
    final alert = CommunityHealthAlert(
      alertId: doc.id,
      ashaId: ashaId,
      ashaName: ashaName,
      issueType: issueType,
      description: description,
      village: village,
      ward: ward,
      severity: severity,
      status: 'pending',
      voiceTranscript: voiceTranscript,
      affectedPopulation: affectedPopulation,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(alert.toFirestore(useServerTimestamp: true));
    return alert;
  }

  Future<List<CommunityHealthAlert>> getPendingAlerts() async {
    if (localDemoMode) return localStore.pendingAlerts();
    final snap = await _communityAlerts
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => CommunityHealthAlert.fromFirestore(d)).toList();
  }

  Future<List<CommunityHealthAlert>> getAllAlerts() async {
    if (localDemoMode) return localStore.allAlerts();
    final snap = await _communityAlerts
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => CommunityHealthAlert.fromFirestore(d)).toList();
  }

  Future<void> updateAlertStatus(String alertId, String status) async {
    if (localDemoMode) {
      localStore.updateAlertStatus(alertId, status);
      return;
    }
    await _communityAlerts.doc(alertId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Awareness Campaigns ───────────────────────────────────────────────
  Future<AwarenessCampaign> createCampaign({
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
  }) async {
    if (localDemoMode) {
      return localStore.createCampaign(
        alertId: alertId,
        title: title,
        description: description,
        safetyInstructions: safetyInstructions,
        hospitalName: hospitalName,
        contactInfo: contactInfo,
        targetVillages: targetVillages,
        targetWards: targetWards,
        targetType: targetType,
        createdBy: createdBy,
      );
    }
    final doc = _awarenessCampaigns.doc();
    final now = DateTime.now();
    final campaign = AwarenessCampaign(
      campaignId: doc.id,
      alertId: alertId,
      title: title,
      description: description,
      safetyInstructions: safetyInstructions,
      hospitalName: hospitalName,
      contactInfo: contactInfo,
      targetVillages: targetVillages,
      targetWards: targetWards,
      targetType: targetType,
      status: 'draft',
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(campaign.toFirestore(useServerTimestamp: true));
    return campaign;
  }

  Future<void> publishCampaign(String campaignId) async {
    if (localDemoMode) {
      localStore.publishCampaign(campaignId);
      return;
    }
    await _awarenessCampaigns.doc(campaignId).update({
      'status': 'published',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AwarenessCampaign>> getPublishedCampaigns() async {
    if (localDemoMode) return localStore.publishedCampaigns();
    final snap = await _awarenessCampaigns
        .where('status', isEqualTo: 'published')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => AwarenessCampaign.fromFirestore(d)).toList();
  }

  // ─── Vaccination Records ───────────────────────────────────────────────
  Future<VaccinationRecord> scheduleVaccination({
    required String patientId,
    String? memberId,
    required String chwId,
    required String vaccineName,
    required String vaccineType,
    required DateTime scheduledDate,
  }) async {
    if (localDemoMode) {
      return localStore.scheduleVaccination(
        patientId: patientId,
        memberId: memberId,
        chwId: chwId,
        vaccineName: vaccineName,
        vaccineType: vaccineType,
        scheduledDate: scheduledDate,
      );
    }
    final doc = _vaccinations.doc();
    final now = DateTime.now();
    final record = VaccinationRecord(
      vaccinationId: doc.id,
      patientId: patientId,
      memberId: memberId,
      chwId: chwId,
      vaccineName: vaccineName,
      vaccineType: vaccineType,
      scheduledDate: scheduledDate,
      status: 'scheduled',
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(record.toFirestore(useServerTimestamp: true));
    return record;
  }

  Future<void> administerVaccination(String vaccinationId, {String? remarks}) async {
    if (localDemoMode) {
      localStore.administerVaccination(vaccinationId, remarks: remarks);
      return;
    }
    final update = <String, dynamic>{
      'status': 'administered',
      'administeredDate': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (remarks != null) update['remarks'] = remarks;
    await _vaccinations.doc(vaccinationId).update(update);
  }

  Future<List<VaccinationRecord>> getVaccinationsByChw(String chwId) async {
    if (localDemoMode) return localStore.vaccinationsByChw(chwId);
    final snap = await _vaccinations
        .where('chwId', isEqualTo: chwId)
        .orderBy('scheduledDate')
        .get();
    return snap.docs.map((d) => VaccinationRecord.fromFirestore(d)).toList();
  }

  // ─── Notifications ─────────────────────────────────────────────────────
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    required String type,
    String? campaignId,
  }) async {
    if (localDemoMode) return;
    await _notifications.add({
      'targetUserId': targetUserId,
      'title': title,
      'body': body,
      'type': type,
      'campaignId': campaignId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Dashboard Stats ───────────────────────────────────────────────────
  Future<Map<String, int>> getDashboardStats(String ashaId, String village) async {
    if (localDemoMode) return localStore.dashboardStats(ashaId, village);
    try {
      final families = await getFamiliesByVillage(village);
      final allMembers = <FamilyMember>[];
      for (final f in families) {
        final members = await getFamilyMembers(f.familyId);
        allMembers.addAll(members);
      }
      
      final todayVisits = await _homeVisits
          .where('ashaId', isEqualTo: ashaId)
          .get();
      final todayCount = todayVisits.docs.where((d) {
        final date = (d.data()['date'] as Timestamp?)?.toDate();
        if (date == null) return false;
        final now = DateTime.now();
        return date.year == now.year && date.month == now.month && date.day == now.day;
      }).length;

      final followUps = await getFollowUpsByAsha(ashaId);
      final pendingFollowUps = followUps.where((f) => f.status == 'pending').length;

      final vaccinations = await getVaccinationsByChw(ashaId);
      final dueVaccinations = vaccinations.where((v) => 
        v.status == 'scheduled' || v.status == 'pending'
      ).length;

      return {
        'todayVisits': todayCount,
        'totalFamilies': families.length,
        'totalMembers': allMembers.length,
        'pregnantWomen': allMembers.where((m) => m.pregnancyStatus).length,
        'infants': allMembers.where((m) => m.infantStatus).length,
        'vaccinationsDue': dueVaccinations,
        'followUpsDue': pendingFollowUps,
      };
    } catch (e) {
      debugPrint('Error getting dashboard stats: $e');
      return {
        'todayVisits': 0,
        'totalFamilies': 0,
        'totalMembers': 0,
        'pregnantWomen': 0,
        'infants': 0,
        'vaccinationsDue': 0,
        'followUpsDue': 0,
      };
    }
  }
}
