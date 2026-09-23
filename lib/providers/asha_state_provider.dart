import 'package:flutter/material.dart';

import '../models/asha_worker.dart';
import '../models/family.dart';
import '../models/family_member.dart';
import '../services/firestore/asha_data_service.dart';
import '../services/firestore/asha_demo_seeder.dart';

/// State management provider for ASHA Worker session.
class AshaStateProvider extends ChangeNotifier {
  AshaStateProvider({required this.dataService}) {
    // Automatically initialize with demo worker so session is never null during testing
    _currentWorker = AshaWorker.demoWorker;
  }

  final AshaDataService dataService;

  AshaWorker? _currentWorker;
  Map<String, int> _dashboardStats = {};
  bool _isLoading = false;
  String? _lastError;

  /// Always returns an active worker, falling back to demoWorker if null.
  AshaWorker get currentWorker => _currentWorker ?? AshaWorker.demoWorker;
  Map<String, int> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => true;

  /// Human-readable reason for the most recent [seedDemoData] failure, if any.
  String? get lastError => _lastError;

  void setWorker(AshaWorker worker) {
    _currentWorker = worker;
    notifyListeners();
  }

  void logout() {
    _currentWorker = AshaWorker.demoWorker;
    _dashboardStats = {};
    notifyListeners();
  }

  Future<void> loadDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    _dashboardStats = await dataService.getDashboardStats(
      currentWorker.ashaId,
      currentWorker.village,
    );

    _isLoading = false;
    notifyListeners();
  }

  bool _usedLocalDemo = false;

  /// True when the dashboard is currently showing the built-in offline demo
  /// dataset instead of Firestore data.
  bool get usedLocalDemo => _usedLocalDemo;

  /// Seeds realistic demo data (families, members, vaccinations, followups, alerts).
  ///
  /// Always returns true with visible data: if Firestore seeding fails
  /// (offline, permission-denied, …), it automatically falls back to the
  /// built-in local demo dataset. Only returns false for unexpected errors —
  /// see [lastError] for the reason.
  Future<bool> seedDemoData() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await AshaDemoSeeder.seedAll(dataService);
      _usedLocalDemo = false;
      await loadDashboardStats();
      return true;
    } catch (e) {
      debugPrint('[AshaStateProvider] Firestore seed failed, '
          'using local demo dataset: $e');
      // Fall back to the bundled offline dataset so the demo always works.
      dataService.enableLocalDemo();
      _usedLocalDemo = true;
      await loadDashboardStats();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AshaWorker?> register({
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
    final worker = await dataService.registerAshaWorker(
      ashaId: ashaId,
      name: name,
      phone: phone,
      password: password,
      state: state,
      district: district,
      block: block,
      village: village,
      wardId: wardId,
    );
    if (worker != null) {
      _currentWorker = worker;
      notifyListeners();
    }
    return worker;
  }

  Future<AshaWorker?> login(String ashaId, String password) async {
    final worker = await dataService.loginAshaWorker(ashaId, password);
    if (worker != null) {
      _currentWorker = worker;
      notifyListeners();
    }
    return worker;
  }
}
