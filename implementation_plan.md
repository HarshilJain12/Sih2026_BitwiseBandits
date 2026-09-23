# Phase 2C — Patient Identity + Firestore Data Foundation

Build the Firestore data # Static QR Code Generation & Scanning System

I understand completely now! You want the QR Code to be a static, permanent asset generated **at the moment of registration**, and you want it directly saved into the Firestore database so it exists permanently alongside the patient's data.

Here is the exact plan to implement this:

## Proposed Changes

### 1. Patient Registration (Static Base64 Generation)
When a new patient registers:
- I will use the `qr_flutter` package to generate a QR code containing their unique `patientId`.
- I will convert this QR code into a **base64 PNG Data URI** string (`data:image/png;base64,...`).
- I will save this string directly into the `patients` Firestore document under a new field called `qrCodeBase64`.

### 2. Patient Dashboard QR Display
- The Patient Dashboard will now simply read the `qrCodeBase64` field from Firestore and display it using Flutter's native `Image.memory()` decoder.

### 3. Doctor QR Scanner
- The Doctor QR Scanner will be updated to read the static `patientId` directly from the scanned QR code and immediately open the corresponding patient record. 

### 4. Backfill Script (Migration)
- Since you already have 3 patients (Harshil, Hello, Abc) in the database without this `qrCodeBase64` field, I will write a quick utility script that will loop through them, generate their static QR codes, and update their documents in Firestore.

> [!IMPORTANT]  
> ### User Review Required
> Are you ready for me to execute this plan? Just hit **Approve** and I will write the code right now! Phone Authentication to a patient profile system with unique Patient IDs and multi-patient-per-account architecture.

## User Review Required

> [!IMPORTANT]
> **Cloud Firestore must be enabled in the Firebase Console.** The project `sih2026-75333` currently has no Firestore database. After implementation, you will need to:
> 1. Go to [Firebase Console → Firestore](https://console.firebase.google.com/project/sih2026-75333/firestore)
> 2. Click **Create database**
> 3. Choose **Production mode** (we'll deploy our security rules)
> 4. Select a Firestore location (e.g., `asia-south1` for India proximity)

> [!WARNING]
> **Do NOT choose Test mode** when creating the database. We are deploying proper security rules.

## Open Questions

> [!IMPORTANT]
> **Firestore location**: Which region do you prefer? Recommended: `asia-south1` (Mumbai) for lowest latency to Maharashtra users. This cannot be changed after creation.

---

## Proposed Changes

### Dependency Addition

#### [MODIFY] [pubspec.yaml](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/pubspec.yaml)
- Add `cloud_firestore: ^5.6.7` (compatible with existing `firebase_core: ^4.15.0` and `firebase_auth: ^6.7.0`)
- No changes to existing Firebase versions

---

### Data Models

#### [NEW] [account.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/models/account.dart)
Strongly typed model for `/accounts/{firebaseUid}` documents:
- `firebaseUid`, `phoneNumber`, `createdAt`, `updatedAt`, `accountType`
- `fromFirestore()` / `toFirestore()` with safe Timestamp handling
- Immutable with `copyWith()`

#### [NEW] [patient.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/models/patient.dart)
Strongly typed model for `/patients/{patientId}` documents:
- `patientId`, `ownerUid`, `name`, `phoneNumber`, `createdAt`, `updatedAt`, `status`
- `fromFirestore()` / `toFirestore()` with safe Timestamp handling
- Only identity fields — no medical history, documents, or appointments

#### [NEW] [patient_link.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/models/patient_link.dart)
Strongly typed model for `/accounts/{uid}/patientLinks/{patientId}` subcollection:
- `patientId`, `relationship`, `createdAt`
- `fromFirestore()` / `toFirestore()`
- Relationship defaults to `"self"` for this phase

---

### Services / Repository Layer

#### [NEW] [patient_id_generator.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/services/patient_id_generator.dart)
- Generates collision-safe Patient IDs in format `P-XXXXXXXXXX` (10-char alphanumeric suffix)
- Uses `dart:math` `Random.secure()` for cryptographic randomness
- Checks Firestore `/patients/{id}` for collisions before returning
- Retry loop with max attempts to prevent infinite loops

#### [NEW] [account_service.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/services/firestore/account_service.dart)
- `ensureAccountExists()` — idempotent: creates `/accounts/{uid}` only if it doesn't exist; never overwrites existing `createdAt`
- `getAccount()` — fetches account document by UID
- Obtains UID from `FirebaseAuth.instance.currentUser` (never trusts UI-provided UID)
- Phone number sourced from `currentUser.phoneNumber`

#### [NEW] [patient_service.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/services/firestore/patient_service.dart)
- `createPatient()` — generates Patient ID, creates `/patients/{id}` and `/accounts/{uid}/patientLinks/{id}` in a **Firestore batch write** for atomicity
- `getPatient()` — fetch by Patient ID
- `getLinkedPatients()` — fetches all patients linked to the authenticated account
- `hasPatientProfile()` — checks if the current account has any patient links
- `patientIdExists()` — checks whether a Patient ID is already taken
- All methods verify authentication state before operating

---

### Firestore Security Rules

#### [NEW] [firestore.rules](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/firestore.rules)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Accounts: only the owner can read/write their own account
    match /accounts/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      
      // Patient links: only the account owner can manage
      match /patientLinks/{linkId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
    
    // Patients: only the owner can read/write
    // TODO: Future phases will add role-based access for ASHA, Doctor, Hospital Admin
    match /patients/{patientId} {
      allow read: if request.auth != null && resource.data.ownerUid == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.ownerUid == request.auth.uid;
      allow update: if request.auth != null && resource.data.ownerUid == request.auth.uid;
      allow delete: if false; // Patients cannot be deleted
    }
    
    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

#### [MODIFY] [firebase.json](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/firebase.json)
- Add `"firestore"` configuration pointing to `firestore.rules`

---

### Integration — Post-Auth Account Setup

#### [MODIFY] [patient_otp_screen.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/screens/login/patient/patient_otp_screen.dart)
- After successful OTP verification (line ~192), call `AccountService.ensureAccountExists()` before navigating to success screen
- Non-blocking: if Firestore is unavailable, still navigate (account creation can retry later)
- No UI changes to the OTP screen itself

#### [MODIFY] [patient_login_screen.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/screens/login/patient/patient_login_screen.dart)
- In `onVerificationCompleted` callback (instant verification), also call `AccountService.ensureAccountExists()`
- Same non-blocking approach

#### [MODIFY] [patient_auth_success_screen.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/screens/login/patient/patient_auth_success_screen.dart)
- Add a "Register Patient" or "Continue" button that navigates to patient registration when no patient profile exists
- Show Patient ID and basic info when a patient profile already exists
- Uses `PatientService.hasPatientProfile()` to determine state
- Minimal UI additions to existing success screen — no major redesign

---

### Provider for Firestore Services

#### [MODIFY] [main.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/lib/main.dart)
- Add `AccountService` and `PatientService` to the `MultiProvider` block
- No changes to Firebase initialization, Router, or existing providers

---

### Tests

#### [NEW] [patient_model_test.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/test/patient_model_test.dart)
- Serialization/deserialization roundtrip
- `toFirestore()` / `fromFirestore()` with mock Timestamp handling
- Status field validation

#### [NEW] [account_model_test.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/test/account_model_test.dart)
- Serialization/deserialization roundtrip
- AccountType field validation

#### [NEW] [patient_id_generator_test.dart](file:///c:/Users/harsh/OneDrive/Documents/Antigravity/Sih%202026/test/patient_id_generator_test.dart)
- ID format validation (`P-` prefix + 10 alphanumeric chars)
- Uniqueness across multiple generations
- Character set validation (uppercase + digits only)

---

## Architecture Summary

```
Firebase Phone Auth (EXISTING — UNCHANGED)
        ↓
  Firebase UID obtained
        ↓
  AccountService.ensureAccountExists()
        ↓
  /accounts/{uid} created (idempotent)
        ↓
  PatientService.createPatient(name, ...)
        ↓
  Firestore Batch Write:
    ├── /patients/{P-XXXXXXXXXX}  (new document)
    └── /accounts/{uid}/patientLinks/{P-XXXXXXXXXX}  (subcollection)
```

### Firestore Data Structure

```
/accounts/{firebaseUid}
  ├── firebaseUid: string
  ├── phoneNumber: string (from FirebaseAuth)
  ├── createdAt: Timestamp
  ├── updatedAt: Timestamp
  └── accountType: "patient"

/accounts/{firebaseUid}/patientLinks/{patientId}
  ├── patientId: string ("P-XXXXXXXXXX")
  ├── relationship: string ("self")
  └── createdAt: Timestamp

/patients/{patientId}
  ├── patientId: string ("P-XXXXXXXXXX")
  ├── ownerUid: string (Firebase UID)
  ├── name: string
  ├── phoneNumber: string
  ├── createdAt: Timestamp
  ├── updatedAt: Timestamp
  └── status: string ("active")
```

---

## Files NOT Modified

| File | Reason |
|------|--------|
| `firebase_options.dart` | Explicitly preserved per requirements |
| `firebase_initializer.dart` | Working Firebase init — no changes needed |
| `firebase_service.dart` | Core Firebase service — preserved |
| `auth_service.dart` (interface) | Auth interface — unchanged |
| `firebase_auth_service.dart` | Working Phone Auth — untouched |
| `mock_auth_service.dart` | Staff mock auth — preserved |
| All Phase 1 UI screens | No redesign of existing screens |
| Android `google-services.json` | No package name or config changes |

---

## Verification Plan

### Automated Tests
```bash
flutter pub get
dart format .
flutter analyze
flutter test
```

### Manual Verification
1. Build and run on Android emulator: `flutter run -d emulator-5554`
2. Verify existing Phone Auth flow still works with test number
3. After Firestore is enabled in Firebase Console:
   - Verify account document creation after OTP success
   - Verify patient creation and Patient ID generation
   - Verify security rules block unauthorized access

---

## What This Phase Does NOT Include

- ❌ Medical document uploads
- ❌ AI extraction (Gemini)
- ❌ Family member registration UI
- ❌ Appointments / prescriptions / referrals
- ❌ ASHA / Doctor / Hospital Admin workflows
- ❌ Role-based access control beyond patient-owner
- ❌ Web Phone Auth changes
