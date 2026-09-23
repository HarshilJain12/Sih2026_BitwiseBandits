import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/asha_worker.dart';
import 'asha_data_service.dart';

/// Helper to populate realistic demonstration data for Maharashtra rural healthcare.
class AshaDemoSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Guards a Firestore operation with a timeout so the demo never hangs
  /// forever on a slow/blocked connection. The timeout message hints at the
  /// most common causes (no network, Firestore rules not deployed).
  static Future<T> _guard<T>(Future<T> operation, String opName) {
    return operation.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
        'Firestore "$opName" timed out. Check internet connection and '
        'that firestore.rules is deployed (firebase deploy --only firestore:rules).',
      ),
    );
  }

  /// Seeds a complete demo dataset into Firestore.
  static Future<void> seedAll(AshaDataService service) async {
    final now = DateTime.now();

    // 1. Ensure Demo Worker exists in Firestore
    final workerRef = _db.collection('asha_workers').doc('demo_asha_001');
    final worker = AshaWorker.demoWorker;
    await _guard(
      workerRef.set(worker.toFirestore(useServerTimestamp: true), SetOptions(merge: true)),
      'save demo worker',
    );

    // Check if families already seeded
    final existingFamilies = await _guard(
      _db.collection('families')
          .where('village', isEqualTo: worker.village)
          .limit(1)
          .get(),
      'check existing families',
    );

    if (existingFamilies.docs.isNotEmpty) {
      debugPrint('Demo dataset already exists for village ${worker.village}');
      return;
    }

    // 2. Seed Families
    final family1 = await _guard(
      service.createFamily(
        headOfFamilyName: 'Ramesh Patil',
        address: 'Kondhwa Budruk, Lane 1',
        village: worker.village,
        ward: worker.wardId,
        block: worker.block,
        district: worker.district,
        contactNumber: '+91 9822011223',
      ),
      'seed family 1',
    );

    final family2 = await _guard(
      service.createFamily(
        headOfFamilyName: 'Prakash Jadhav',
        address: 'Ward 4, Near Water Tank',
        village: worker.village,
        ward: worker.wardId,
        block: worker.block,
        district: worker.district,
        contactNumber: '+91 9822044556',
      ),
      'seed family 2',
    );

    final family3 = await _guard(
      service.createFamily(
        headOfFamilyName: 'Suresh Shinde',
        address: 'Ambedkar Nagar, Plot 14',
        village: worker.village,
        ward: worker.wardId,
        block: worker.block,
        district: worker.district,
        contactNumber: '+91 9822077889',
      ),
      'seed family 3',
    );

    // 3. Seed Family Members
    // Family 1 (Patil): Ramesh (Head), Sunita (Pregnant - 2nd Tri), Aarav (2 yr infant)
    await _guard(
      service.addFamilyMember(
        familyId: family1.familyId,
        name: 'Ramesh Patil',
        age: 34,
        gender: 'Male',
        relationship: 'Head',
        phone: '+91 9822011223',
      ),
      'seed member Ramesh Patil',
    );

    final m1Pregnant = await _guard(
      service.addFamilyMember(
        familyId: family1.familyId,
        name: 'Sunita Patil',
        age: 28,
        gender: 'Female',
        relationship: 'Wife',
        phone: '+91 9822011224',
        pregnancyStatus: true,
        expectedDeliveryMonth: 'November 2026',
        nutritionStatus: 'Moderate Anemia (Hb 9.4)',
      ),
      'seed member Sunita Patil',
    );

    final m1Child = await _guard(
      service.addFamilyMember(
        familyId: family1.familyId,
        name: 'Aarav Patil',
        age: 2,
        gender: 'Male',
        relationship: 'Son',
        infantStatus: true,
        nutritionStatus: 'Normal Weight for Age',
      ),
      'seed member Aarav Patil',
    );

    // Family 2 (Jadhav): Prakash (Head, HTN), Suman (Diabetes), Anaya (6m infant)
    final m2Head = await _guard(
      service.addFamilyMember(
        familyId: family2.familyId,
        name: 'Prakash Jadhav',
        age: 65,
        gender: 'Male',
        relationship: 'Head',
        phone: '+91 9822044556',
      ),
      'seed member Prakash Jadhav',
    );

    await _guard(
      service.addFamilyMember(
        familyId: family2.familyId,
        name: 'Suman Jadhav',
        age: 60,
        gender: 'Female',
        relationship: 'Wife',
      ),
      'seed member Suman Jadhav',
    );

    final m2Infant = await _guard(
      service.addFamilyMember(
        familyId: family2.familyId,
        name: 'Anaya Jadhav',
        age: 0,
        gender: 'Female',
        relationship: 'Granddaughter',
        infantStatus: true,
        nutritionStatus: 'Exclusively Breastfed',
      ),
      'seed member Anaya Jadhav',
    );

    // Family 3 (Shinde)
    await _guard(
      service.addFamilyMember(
        familyId: family3.familyId,
        name: 'Suresh Shinde',
        age: 42,
        gender: 'Male',
        relationship: 'Head',
        phone: '+91 9822077889',
      ),
      'seed member Suresh Shinde',
    );

    // 4. Seed Vaccinations
    await _guard(
      service.scheduleVaccination(
        patientId: m1Child.patientId ?? 'P-1002938471',
        memberId: m1Child.memberId,
        chwId: worker.ashaId,
        vaccineName: 'MR-1 (Measles & Rubella)',
        vaccineType: 'Routine Infant Immunization',
        scheduledDate: now.add(const Duration(days: 3)),
      ),
      'seed vaccination MR-1',
    );

    await _guard(
      service.scheduleVaccination(
        patientId: m2Infant.patientId ?? 'P-1002938472',
        memberId: m2Infant.memberId,
        chwId: worker.ashaId,
        vaccineName: 'Pentavalent-1 & OPV-1',
        vaccineType: 'Routine Infant Immunization',
        scheduledDate: now.add(const Duration(days: 7)),
      ),
      'seed vaccination Pentavalent-1',
    );

    // 5. Seed Follow-ups
    await _guard(
      service.createFollowUp(
        ashaId: worker.ashaId,
        memberId: m1Pregnant.memberId,
        familyId: family1.familyId,
        type: 'pregnancy',
        description: '2nd Trimester ANC Check & IFA tablet adherence check. Check BP & Hb.',
        scheduledDate: now.add(const Duration(days: 2)),
      ),
      'seed pregnancy follow-up',
    );

    await _guard(
      service.createFollowUp(
        ashaId: worker.ashaId,
        memberId: m2Head.memberId,
        familyId: family2.familyId,
        type: 'hypertension',
        description: 'Hypertension monitoring & salt counseling. Last BP 155/98 mmHg.',
        scheduledDate: now.add(const Duration(days: 5)),
      ),
      'seed hypertension follow-up',
    );

    // 6. Seed Community Health Alerts / Village Issues
    await _guard(
      service.submitAlert(
        ashaId: worker.ashaId,
        ashaName: worker.name,
        issueType: 'Water Contamination',
        description: 'Drinking water pipeline contamination observed near Lane 2 public tap.',
        village: worker.village,
        ward: worker.wardId,
        severity: 'high',
        voiceTranscript: 'Drinking water pipeline contamination observed near Lane 2 public tap.',
      ),
      'seed water contamination alert',
    );

    await _guard(
      service.submitAlert(
        ashaId: worker.ashaId,
        ashaName: worker.name,
        issueType: 'Dengue Concern',
        description: 'Stagnant water and mosquito breeding near open gutter by primary school.',
        village: worker.village,
        ward: worker.wardId,
        severity: 'medium',
        voiceTranscript: 'Stagnant water and mosquito breeding near open gutter by primary school.',
      ),
      'seed dengue concern alert',
    );

    // 7. Seed Awareness Campaigns
    await _guard(
      service.createCampaign(
        title: 'Mission Indradhanush Immunization Drive',
        description: 'Special weekend vaccination drive for children under 5 and pregnant women.',
        safetyInstructions: 'Bring immunization card and aadhaar card if available.',
        hospitalName: 'Kondhwa PHC Health Center',
        targetVillages: [worker.village],
        targetWards: [worker.wardId],
        targetType: 'general',
        createdBy: worker.ashaId,
      ),
      'seed awareness campaign',
    );

    debugPrint('Demo dataset seeded successfully.');
  }
}
