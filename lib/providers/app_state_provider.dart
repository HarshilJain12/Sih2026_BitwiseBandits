import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../models/language_option.dart';
import '../models/user_role.dart';
import '../services/interfaces/storage_service.dart';

/// Application-level state provider.
///
/// Currently manages:
/// - Selected locale (persisted via [StorageService])
/// - Active/selected user role
/// - Doctor session data
///
/// Architecture note: future chunks can add [AuthProvider] and
/// [UserProvider] as separate providers rather than expanding this class.
class AppStateProvider extends ChangeNotifier {
  AppStateProvider({required this.storageService});

  final StorageService storageService;

  Locale _locale = const Locale('en');
  bool _isInitialized = false;
  bool _hasSelectedLanguage = false;
  UserRole? _selectedRole;
  String? _currentPatientId;

  // Doctor session fields
  String? _activeDoctorId;
  String? _activeDoctorName;
  String? _activeDoctorSpecialization;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;
  bool get hasSelectedLanguage => _hasSelectedLanguage;
  UserRole? get selectedRole => _selectedRole;
  String? get currentPatientId => _currentPatientId;

  /// Doctor session accessors.
  String? get activeDoctorId => _activeDoctorId;
  String? get activeDoctorName => _activeDoctorName;
  String? get activeDoctorSpecialization => _activeDoctorSpecialization;

  /// Whether the current session is an authenticated doctor.
  bool get isDoctorSession =>
      _selectedRole == UserRole.doctor && _activeDoctorId != null;

  /// Sets the active Patient ID for the current session.
  void setCurrentPatientId(String? patientId) {
    _currentPatientId = patientId;
    notifyListeners();
  }

  /// Clears the active patient session.
  void clearPatientSession() {
    _currentPatientId = null;
    notifyListeners();
  }

  /// Sets the doctor session data after successful login.
  void setDoctorSession({
    required String doctorId,
    required String name,
    required String specialization,
  }) {
    _activeDoctorId = doctorId;
    _activeDoctorName = name;
    _activeDoctorSpecialization = specialization;
    _selectedRole = UserRole.doctor;
    notifyListeners();
  }

  /// Clears the doctor session data on logout.
  void clearDoctorSession() {
    _activeDoctorId = null;
    _activeDoctorName = null;
    _activeDoctorSpecialization = null;
    if (_selectedRole == UserRole.doctor) {
      _selectedRole = null;
    }
    notifyListeners();
  }

  /// Must be called before the app renders. Loads persisted locale.
  Future<void> initialize() async {
    final saved = await storageService.getLanguage();
    if (saved != null) {
      final match = LanguageOption.supportedLanguages
          .where((l) => l.code == saved)
          .firstOrNull;
      if (match != null) {
        _locale = match.locale;
        _hasSelectedLanguage = true;
      }
    }
    _isInitialized = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  /// Changes the selected locale and persists it.
  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    _hasSelectedLanguage = true;
    await storageService.saveLanguage(locale.languageCode);
    notifyListeners();
  }

  /// Sets the currently active role.
  void selectRole(UserRole role) {
    _selectedRole = role;
    if (role != UserRole.patient) {
      _currentPatientId = null;
    }
    notifyListeners();
  }
}
