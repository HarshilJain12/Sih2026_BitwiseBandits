import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/asha_worker.dart';
import '../models/awareness_campaign.dart';
import '../models/community_health_alert.dart';
import '../models/hospital_doctor.dart';
import '../models/patient.dart';
import '../services/firestore/hospital_admin_service.dart';

/// State management provider for the Hospital Admin dashboard.
class AdminStateProvider extends ChangeNotifier {
  AdminStateProvider({required this.dataService});

  final HospitalAdminService dataService;

  Map<String, int> _overview = {};
  List<Appointment> _queue = [];
  List<Appointment> _completedToday = [];
  List<Appointment> _allAppointments = [];
  List<Patient> _patients = [];
  List<HospitalDoctor> _doctors = [];
  List<CommunityHealthAlert> _alerts = [];
  List<AshaWorker> _workers = [];
  List<AwarenessCampaign> _campaigns = [];

  bool _isLoading = false;
  String? _lastError;
  bool _usedLocalDemo = false;

  Map<String, int> get overview => _overview;
  List<Appointment> get queue => _queue;
  List<Appointment> get completedToday => _completedToday;
  List<Appointment> get allAppointments => _allAppointments;
  List<Patient> get patients => _patients;
  List<HospitalDoctor> get doctors => _doctors;
  List<CommunityHealthAlert> get alerts => _alerts;
  List<AshaWorker> get workers => _workers;
  List<AwarenessCampaign> get campaigns => _campaigns;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// True when showing the built-in offline demo dataset.
  bool get usedLocalDemo => _usedLocalDemo;

  /// Loads the full admin dataset, falling back to the bundled demo data
  /// when Firestore is unreachable or denies access. Always leaves visible
  /// data behind — never a stuck loader.
  Future<bool> loadAll() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _refreshFromService();
      _usedLocalDemo = false;
      return true;
    } catch (e) {
      debugPrint('[AdminStateProvider] Firestore failed, '
          'using local demo dataset: $e');
      dataService.enableLocalDemo();
      _usedLocalDemo = true;
      await _refreshFromService();
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshFromService() async {
    _overview = await dataService.getOverviewStats();
    _queue = await dataService.getTodayQueue();
    _completedToday = await dataService.getTodayCompleted();
    _allAppointments = await dataService.getAllAppointments();
    _patients = await dataService.getAllPatients();
    _doctors = await dataService.getDoctors();
    _alerts = await dataService.getAllAlerts();
    _workers = await dataService.getWorkers();
    _campaigns = await dataService.getCampaigns();
    notifyListeners();
  }

  Future<List<Patient>> searchPatients(String query) {
    return dataService.searchPatients(query);
  }

  Future<void> refreshQueue() async {
    _queue = await dataService.getTodayQueue();
    _completedToday = await dataService.getTodayCompleted();
    _overview = await dataService.getOverviewStats();
    notifyListeners();
  }

  Future<void> callNext(String doctorId) async {
    await dataService.callNext(doctorId);
    await refreshQueue();
  }

  Future<void> updateAppointmentStatus(
      String appointmentId, String status) async {
    await dataService.updateAppointmentStatus(appointmentId, status);
    await refreshQueue();
  }

  Future<void> setDoctorDuty(String doctorId, bool onDuty) async {
    await dataService.setDoctorDuty(doctorId, onDuty);
    _doctors = await dataService.getDoctors();
    _overview = await dataService.getOverviewStats();
    notifyListeners();
  }

  Future<void> updateAlertStatus(String alertId, String status) async {
    await dataService.updateAlertStatus(alertId, status);
    _alerts = await dataService.getAllAlerts();
    _overview = await dataService.getOverviewStats();
    notifyListeners();
  }

  /// Queue tokens for one doctor, in consultation order.
  List<Appointment> queueForDoctor(String doctorId) =>
      _queue.where((a) => a.doctorId == doctorId).toList();
}
