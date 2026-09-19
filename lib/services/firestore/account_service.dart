import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/account.dart';

/// Service responsible for managing `/accounts/{firebaseUid}` documents.
///
/// All operations verify authentication state and derive the UID from
/// [FirebaseAuth.instance.currentUser] — never trusting UI-provided values.
class AccountService {
  AccountService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _accountsRef =>
      _firestore.collection('accounts');

  /// Ensures an account document exists for the currently authenticated user.
  ///
  /// **Idempotent**: if the account already exists, only `updatedAt` is refreshed.
  /// The `createdAt` timestamp and existing data are never overwritten.
  ///
  /// Returns the [Account] after ensuring it exists.
  ///
  /// Throws [StateError] if the user is not authenticated.
  Future<Account> ensureAccountExists({
    String? uid,
    String? phoneNumber,
  }) async {
    final user = _auth.currentUser;
    final effectiveUid = uid ?? user?.uid;
    if (effectiveUid == null || effectiveUid.isEmpty) {
      throw StateError(
        'Cannot create account: no authenticated user. '
        'Ensure Firebase Phone Auth is completed before calling this method.',
      );
    }

    final effectivePhone = phoneNumber ?? user?.phoneNumber ?? '';
    final docRef = _accountsRef.doc(effectiveUid);

    try {
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        // Account already exists — update only the last-seen timestamp
        await docRef.update({'updatedAt': FieldValue.serverTimestamp()});

        if (kDebugMode) {
          debugPrint(
            '[AccountService] Account $effectiveUid already exists, updated timestamp.',
          );
        }

        // Re-fetch to get the server-side timestamp
        final updated = await docRef.get();
        return Account.fromFirestore(updated);
      }

      // Create new account document
      final newAccount = Account(
        firebaseUid: effectiveUid,
        phoneNumber: effectivePhone,
        createdAt: DateTime.now(), // Will be overwritten by server timestamp
        updatedAt: DateTime.now(),
        accountType: 'patient',
      );

      await docRef.set(newAccount.toFirestore(useServerTimestamp: true));

      if (kDebugMode) {
        debugPrint(
          '[AccountService] Created new account for $effectiveUid ($effectivePhone).',
        );
      }

      // Re-fetch to get the server-side timestamps
      final created = await docRef.get();
      return Account.fromFirestore(created);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccountService] Error ensuring account exists: $e');
      }
      rethrow;
    }
  }

  /// Fetches the account document for the given [uid].
  ///
  /// Returns `null` if the document does not exist.
  Future<Account?> getAccount(String uid) async {
    try {
      final snapshot = await _accountsRef.doc(uid).get();
      if (!snapshot.exists) return null;
      return Account.fromFirestore(snapshot);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AccountService] Error fetching account $uid: $e');
      }
      rethrow;
    }
  }

  /// Returns the Firebase UID of the currently authenticated user, or `null`.
  String? get currentUid => _auth.currentUser?.uid;
}
