import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/patient.dart';
import '../../models/patient_link.dart';
import '../../models/patient_location.dart';
import '../patient_id_generator.dart';

/// Service responsible for managing patient profiles and their links to accounts.
///
/// Handles:
/// - Creating patients with unique Patient IDs (atomic batch writes)
/// - Retrieving patient profiles by ID
/// - Listing patients linked to the authenticated account
/// - Checking whether the current account has existing patient profiles
///
/// All operations verify authentication state and derive the UID from
/// [FirebaseAuth.instance.currentUser].
class PatientService {
  PatientService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PatientIdGenerator? idGenerator,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _idGenerator = idGenerator ?? PatientIdGenerator();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PatientIdGenerator _idGenerator;

  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _firestore.collection('patients');

  CollectionReference<Map<String, dynamic>> _patientLinksRef(String uid) =>
      _firestore.collection('accounts').doc(uid).collection('patientLinks');

  /// Creates a new patient profile and links it to the current account.
  ///
  /// Uses a Firestore **batch write** to atomically create both:
  /// 1. `/patients/{patientId}` — the patient document
  /// 2. `/accounts/{uid}/patientLinks/{patientId}` — the link document
  ///
  /// The [relationship] parameter defaults to `"self"` for the first patient.
  /// Future phases will support family member relationships.
  ///
  /// Returns the created [Patient] with its generated Patient ID.
  ///
  /// Throws [StateError] if the user is not authenticated.
  Future<Patient> createPatient({
    required String name,
    int? age,
    double? weightKg,
    double? heightCm,
    String relationship = 'self',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Cannot create patient: no authenticated user. '
        'Ensure Firebase Phone Auth is completed before calling this method.',
      );
    }

    final uid = user.uid;
    final phoneNumber = user.phoneNumber ?? '';

    // Generate a unique Patient ID
    final patientId = _idGenerator.generate();

    final now = DateTime.now();

    final patient = Patient(
      patientId: patientId,
      ownerUid: uid,
      name: name,
      phoneNumber: phoneNumber,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      createdAt: now,
      updatedAt: now,
      status: 'active',
    );

    final patientLink = PatientLink(
      patientId: patientId,
      relationship: relationship,
      createdAt: now,
    );

    // Atomic batch write: patient + link created together or not at all
    final batch = _firestore.batch();

    batch.set(
      _patientsRef.doc(patientId),
      patient.toFirestore(useServerTimestamp: true),
    );

    batch.set(
      _patientLinksRef(uid).doc(patientId),
      patientLink.toFirestore(useServerTimestamp: true),
    );

    try {
      await batch.commit();

      if (kDebugMode) {
        debugPrint(
          '[PatientService] Created patient $patientId for account $uid.',
        );
      }

      // Re-fetch to get server timestamps
      final snapshot = await _patientsRef.doc(patientId).get();
      return Patient.fromFirestore(snapshot);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientService] Error creating patient: $e');
      }
      rethrow;
    }
  }

  /// Updates the geographic location of an existing patient profile.
  ///
  /// Updates only the `location` and `updatedAt` fields in `/patients/{patientId}`.
  /// Client-side and Firestore security rules verify ownership before writing.
  Future<Patient> updatePatientLocation({
    required String patientId,
    required PatientLocation location,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Cannot update patient location: no authenticated user. '
        'Ensure Firebase Phone Auth is completed before calling this method.',
      );
    }

    final docRef = _patientsRef.doc(patientId);

    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw StateError('Patient $patientId does not exist.');
      }

      final existing = Patient.fromFirestore(snapshot);
      if (existing.ownerUid != user.uid) {
        throw StateError(
          'Access denied: user ${user.uid} does not own patient $patientId.',
        );
      }

      await docRef.update({
        'location': location.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint(
          '[PatientService] Updated location for patient $patientId (source: ${location.source}).',
        );
      }

      final updatedSnapshot = await docRef.get();
      return Patient.fromFirestore(updatedSnapshot);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientService] Error updating patient location: $e');
      }
      rethrow;
    }
  }

  /// Retrieves a patient by their Patient ID.
  ///
  /// Returns `null` if the patient does not exist or the current user
  /// does not own the patient record.
  Future<Patient?> getPatient(String patientId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final snapshot = await _patientsRef.doc(patientId).get();
      if (!snapshot.exists) return null;

      final patient = Patient.fromFirestore(snapshot);

      // Security check: only return if the current user owns this patient
      if (patient.ownerUid != user.uid) {
        if (kDebugMode) {
          debugPrint(
            '[PatientService] Access denied: user ${user.uid} does not own '
            'patient $patientId (owner: ${patient.ownerUid}).',
          );
        }
        return null;
      }

      return patient;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientService] Error fetching patient $patientId: $e');
      }
      rethrow;
    }
  }

  /// Returns all patients linked to the currently authenticated account (or specified [uid]).
  ///
  /// Primary lookup: `/accounts/{uid}/patientLinks/{patientId}` -> `/patients/{patientId}`
  /// Fallback/Healing: `/patients` where `ownerUid == uid` -> backfills `/accounts/{uid}/patientLinks`
  Future<List<Patient>> getLinkedPatients({String? uid}) async {
    final user = _auth.currentUser;
    final effectiveUid = uid ?? user?.uid;
    if (effectiveUid == null || effectiveUid.isEmpty) return [];

    try {
      final linksSnapshot = await _patientLinksRef(effectiveUid).get();
      final patients = <Patient>[];

      if (linksSnapshot.docs.isNotEmpty) {
        for (final linkDoc in linksSnapshot.docs) {
          try {
            final link = PatientLink.fromFirestore(linkDoc);
            final patientSnapshot =
                await _patientsRef.doc(link.patientId).get();
            if (patientSnapshot.exists) {
              final patient = Patient.fromFirestore(patientSnapshot);
              if (patient.ownerUid.isEmpty ||
                  patient.ownerUid == effectiveUid) {
                patients.add(patient);
              }
            }
          } catch (itemError) {
            if (kDebugMode) {
              debugPrint(
                '[PatientService] Error loading linked patient item: $itemError',
              );
            }
          }
        }
      }

      // If links were found and loaded, return them
      if (patients.isNotEmpty) {
        return patients;
      }

      // ── Self-Healing Fallback ───────────────────────────────────────────
      // If no patient links were found in subcollection, check if patient profile
      // exists in /patients with ownerUid matching this account.
      if (kDebugMode) {
        debugPrint(
          '[PatientService] No patientLinks found under /accounts/$effectiveUid. Checking /patients by ownerUid...',
        );
      }

      final directPatientsSnapshot = await _patientsRef
          .where('ownerUid', isEqualTo: effectiveUid)
          .get();

      if (directPatientsSnapshot.docs.isNotEmpty) {
        for (final doc in directPatientsSnapshot.docs) {
          try {
            final patient = Patient.fromFirestore(doc);
            patients.add(patient);

            // Backfill the missing patientLink document
            final link = PatientLink(
              patientId: patient.patientId,
              relationship: 'self',
              createdAt: patient.createdAt,
            );
            await _patientLinksRef(effectiveUid)
                .doc(patient.patientId)
                .set(link.toFirestore(), SetOptions(merge: true));

            if (kDebugMode) {
              debugPrint(
                '[PatientService] Healed missing patientLink for patient ${patient.patientId} under account $effectiveUid.',
              );
            }
          } catch (healingError) {
            if (kDebugMode) {
              debugPrint(
                '[PatientService] Error healing patientLink: $healingError',
              );
            }
          }
        }
      }

      return patients;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientService] Error fetching linked patients: $e');
      }
      rethrow;
    }
  }

  /// Checks whether the current account already has at least one patient profile.
  ///
  /// Returns `false` if the user is not authenticated or has no profile.
  Future<bool> hasPatientProfile({String? uid}) async {
    final user = _auth.currentUser;
    final effectiveUid = uid ?? user?.uid;
    if (effectiveUid == null || effectiveUid.isEmpty) return false;

    try {
      final snapshot = await _patientLinksRef(effectiveUid).limit(1).get();
      if (snapshot.docs.isNotEmpty) return true;

      // Fallback check directly in /patients by ownerUid
      final patientSnapshot = await _patientsRef
          .where('ownerUid', isEqualTo: effectiveUid)
          .limit(1)
          .get();
      return patientSnapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientService] Error checking patient profile: $e');
      }
      return false;
    }
  }

  /// Checks whether a Patient ID already exists in the `/patients` collection.
  Future<bool> patientIdExists(String patientId) async {
    try {
      final doc = await _patientsRef.doc(patientId).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientService] Error checking patient ID existence: $e');
      }
      rethrow;
    }
  }
}
