# Phase 2C — Task Tracker

## 1. Dependency & Config
- [x] Add `cloud_firestore` to pubspec.yaml
- [x] Run `flutter pub get`
- [x] Add Firestore config to firebase.json
- [x] Create firestore.rules

## 2. Data Models
- [x] Create `lib/models/account.dart`
- [x] Create `lib/models/patient.dart`
- [x] Create `lib/models/patient_link.dart`

## 3. Services
- [x] Create `lib/services/patient_id_generator.dart`
- [x] Create `lib/services/firestore/account_service.dart`
- [x] Create `lib/services/firestore/patient_service.dart`

## 4. Integration
- [x] Modify `lib/main.dart` — add Firestore services to MultiProvider
- [x] Modify `lib/screens/login/patient/patient_otp_screen.dart` — call ensureAccountExists after auth
- [x] Modify `lib/screens/login/patient/patient_login_screen.dart` — call ensureAccountExists on auto-verify
- [x] Modify `lib/screens/login/patient/patient_auth_success_screen.dart` — show patient identity state

## 5. Tests
- [x] Create `test/patient_model_test.dart`
- [x] Create `test/account_model_test.dart`
- [x] Create `test/patient_id_generator_test.dart`

## 6. Verification
- [x] `flutter pub get`
- [x] `dart format .`
- [x] `flutter analyze` (0 issues)
- [x] `flutter test` (21/21 passed)
- [x] Build on Android emulator
