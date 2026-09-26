import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/opd_appointment.dart';
import '../../models/patient.dart';
import '../../providers/admin_state_provider.dart';
import '../../services/printing/opd_slip_print_service.dart';

/// Fast and simple OPD / Appointment Slip generator for hospital receptionists.
///
/// Principles:
/// - Search -> Select Patient -> Select Department Category -> Print OPD Slip.
/// - Existing patient: Auto-loads name, age, and existing QR code.
/// - Walk-in patient: Simple Name, Age, Gender form, NO QR code generated.
/// - Doctor Category ONLY: No doctor names.
/// - Saves appointment record before/alongside printing.
/// - Safe re-print handling without duplicate appointment creation.
class AdminOpdSlipScreen extends StatefulWidget {
  const AdminOpdSlipScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminOpdSlipScreen> createState() => _AdminOpdSlipScreenState();
}

class _AdminOpdSlipScreenState extends State<AdminOpdSlipScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  final _printService = const OpdSlipPrintService();

  List<Patient>? _searchResults;
  bool _isSearching = false;

  Patient? _selectedPatient;
  bool _isWalkInMode = false;
  String _selectedGender = 'Male';
  String _selectedCategory = 'General Medicine';

  bool _isGenerating = false;
  OpdAppointment? _lastGeneratedSlip;
  bool _printFailed = false;

  static const List<Map<String, dynamic>> _categoryData = [
    {'name': 'General Medicine', 'icon': Icons.medical_services_rounded},
    {'name': 'Pediatrics', 'icon': Icons.child_care_rounded},
    {'name': 'Orthopedics', 'icon': Icons.accessibility_new_rounded},
    {'name': 'Gynecology', 'icon': Icons.pregnant_woman_rounded},
    {'name': 'Cardiology', 'icon': Icons.favorite_rounded},
    {'name': 'Dermatology', 'icon': Icons.healing_rounded},
    {'name': 'ENT', 'icon': Icons.hearing_rounded},
    {'name': 'Dentistry', 'icon': Icons.sentiment_satisfied_alt_rounded},
    {'name': 'Ophthalmology', 'icon': Icons.visibility_rounded},
    {'name': 'General Surgery', 'icon': Icons.masks_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final adminState = context.read<AdminStateProvider>();
    final results = await adminState.searchRegisteredPatients(q);
    if (mounted && _searchController.text.trim() == q) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectPatient(Patient patient) {
    setState(() {
      _selectedPatient = patient;
      _isWalkInMode = false;
      _nameController.text = patient.name;
      _ageController.text = patient.age?.toString() ?? '';
      _searchResults = null;
      _searchController.clear();
    });
  }

  void _enableWalkInMode() {
    setState(() {
      _isWalkInMode = true;
      _selectedPatient = null;
      _nameController.clear();
      _ageController.clear();
      _selectedGender = 'Male';
      _searchResults = null;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPatient = null;
      _isWalkInMode = false;
      _nameController.clear();
      _ageController.clear();
      _searchResults = null;
      _searchController.clear();
      _lastGeneratedSlip = null;
      _printFailed = false;
    });
  }

  Future<void> _generateOpdSlip() async {
    final name = _isWalkInMode
        ? _nameController.text.trim()
        : (_selectedPatient?.name ?? _nameController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter or select a patient name.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final age = int.tryParse(_ageController.text.trim()) ??
        _selectedPatient?.age;

    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm a').format(now);
    final apptId = 'OPD-${now.millisecondsSinceEpoch.toString().substring(3)}';

    // Build the OpdAppointment model
    final opd = OpdAppointment(
      appointmentId: apptId,
      hospitalId: 'ADMIN001',
      patientId: _isWalkInMode ? null : _selectedPatient?.patientId,
      patientName: name,
      patientAge: age,
      patientGender: _isWalkInMode ? _selectedGender : null,
      doctorCategory: _selectedCategory,
      appointmentDate: now,
      appointmentTime: timeStr,
      patientType: _isWalkInMode ? 'walk_in' : 'registered',
      qrLinked: !_isWalkInMode && _selectedPatient != null,
      qrPayload: !_isWalkInMode
          ? (_selectedPatient?.qrCodeBase64 ??
              _selectedPatient?.qrToken ??
              _selectedPatient?.patientId)
          : null,
      status: 'upcoming',
      createdAt: now,
    );

    setState(() {
      _isGenerating = true;
      _printFailed = false;
    });

    try {
      final adminState = context.read<AdminStateProvider>();
      // Save appointment record BEFORE / alongside printing
      final savedOpd = await adminState.createOpdAppointment(opd);

      setState(() {
        _lastGeneratedSlip = savedOpd;
        _isGenerating = false;
      });

      // Show the preview dialog & auto-trigger print option
      if (mounted) {
        _showSlipPreviewDialog(savedOpd);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate OPD slip: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handlePrint(OpdAppointment slip) async {
    setState(() => _printFailed = false);
    final success = await _printService.printOpdSlip(slip);
    if (mounted) {
      if (!success) {
        setState(() => _printFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OPD appointment created, but printing failed.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OPD Slip sent to printer successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showSlipPreviewDialog(OpdAppointment slip) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 24),
                          SizedBox(width: 8),
                          Text('OPD Slip Ready',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Physical Slip Preview Box ──────────────────────
                  _buildSlipPreviewCard(slip),

                  const SizedBox(height: 16),

                  if (_printFailed)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppColors.error, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OPD appointment created, but printing failed.',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _handlePrint(slip);
                            setDialogState(() {});
                          },
                          icon: const Icon(Icons.print_rounded),
                          label: Text(_printFailed
                              ? 'Try Printing Again'
                              : (_lastGeneratedSlip != null
                                  ? 'PRINT OPD SLIP'
                                  : 'Print Again')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _printFailed
                                ? AppColors.warning
                                : AppColors.roleAdmin,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _clearSelection();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('+ Next OPD Patient'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlipPreviewCard(OpdAppointment slip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: Colors.black54, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'KONDHWA PHC HEALTH CENTER',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'OPD / APPOINTMENT SLIP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
          const Divider(thickness: 1, color: Colors.black54),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(slip.appointmentDate)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Time: ${slip.appointmentTime}',
                style: const TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Slip ID: ${slip.appointmentId}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: slip.isRegistered
                      ? Colors.blue.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: slip.isRegistered ? Colors.blue : Colors.green,
                  ),
                ),
                child: Text(
                  slip.isRegistered ? 'REGISTERED' : 'WALK-IN',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: slip.isRegistered
                        ? Colors.blue.shade800
                        : Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1, color: Colors.black54),

          // Details
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _slipRow('Patient:', slip.patientName, isBold: true),
                if (slip.patientAge != null)
                  _slipRow('Age:', '${slip.patientAge} Years'),
                if (slip.patientGender != null)
                  _slipRow('Gender:', slip.patientGender!),
                if (slip.patientId != null)
                  _slipRow('Patient ID:', slip.patientId!),
                _slipRow('Department:', slip.doctorCategory.toUpperCase(),
                    isBold: true, highlightColor: AppColors.roleAdmin),
              ],
            ),
          ),

          const Divider(thickness: 1, color: Colors.black54),

          // QR Code or Walk-in note
          if (slip.isRegistered) ...[
            const SizedBox(height: 4),
            _buildPatientQrWidget(slip),
            const SizedBox(height: 4),
            Text(
              slip.patientId ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.black,
                letterSpacing: 1.2,
              ),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '• Walk-in Consultation Slip •\n(No QR Assigned)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPatientQrWidget(OpdAppointment slip) {
    // If base64 exists, decode it; otherwise use QrImageView with patientId/payload
    final payload = slip.qrPayload ?? slip.patientId ?? '';
    if (payload.startsWith('data:image')) {
      try {
        final b64 = payload.split(',').last;
        return Image.memory(
          base64Decode(b64),
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        );
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: QrImageView(
        data: payload,
        version: QrVersions.auto,
        size: 110,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        padding: const EdgeInsets.all(4),
      ),
    );
  }

  Widget _slipRow(String label, String value,
      {bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 12 : 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: highlightColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = context.watch<AdminStateProvider>();

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header banner ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.roleAdminLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                  color: AppColors.roleAdmin.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    color: AppColors.roleAdmin, size: 26),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fast OPD / Appointment Slip',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.roleAdmin)),
                      Text(
                          'Search patient -> Select specialty category -> Print slip in seconds',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // ── Section 1: Patient Search / Walk-in Toggle ─────────────
          if (_selectedPatient == null && !_isWalkInMode) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patient name or mobile number...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.roleAdmin),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                      color: AppColors.roleAdmin, width: 1.5),
                ),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 8),

            // Walk-in fallback button right below search
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Can\'t find patient?',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                TextButton.icon(
                  onPressed: _enableWalkInMode,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('+ New Patient / Walk-in'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.roleAdmin,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_searchResults != null) ...[
              if (_searchResults!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.person_search_rounded,
                          size: 40, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      const Text('No registered patient found',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      const Text(
                        'Generate a quick walk-in OPD slip without registration',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _enableWalkInMode,
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('+ New Patient / Walk-in'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.roleAdmin,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const SizedBox(height: 4),
                Text(
                  'Matching Patients (${_searchResults!.length}):',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                ..._searchResults!.map((p) => _patientResultCard(p)),
              ],
            ],
          ],

          // ── Section 2: Selected Patient or Walk-in Form ────────────
          if (_selectedPatient != null) ...[
            _selectedPatientCard(_selectedPatient!),
            const SizedBox(height: AppTheme.spacingMd),
          ] else if (_isWalkInMode) ...[
            _walkInFormCard(),
            const SizedBox(height: AppTheme.spacingMd),
          ],

          // ── Section 3: Specialty Category Selector ────────────────
          if (_selectedPatient != null || _isWalkInMode) ...[
            const Text(
              'Which doctor / specialty category?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            _categorySelector(),
            const SizedBox(height: AppTheme.spacingLg),

            // ── Generate Button ────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateOpdSlip,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_rounded, size: 22),
              label: Text(
                _isGenerating ? 'Saving & Generating...' : 'GENERATE OPD SLIP',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleAdmin,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Section 4: Recent OPD Slips / History ──────────────────
          if (adminState.opdAppointments.isNotEmpty) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s OPD Slips',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${adminState.opdAppointments.length} Slips',
                  style: const TextStyle(
                      color: AppColors.roleAdmin,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...adminState.opdAppointments.take(5).map(
                  (slip) => _historySlipCard(slip),
                ),
          ],
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('OPD / Appointment Slip'),
        backgroundColor: AppColors.background,
        actions: [
          if (_selectedPatient != null || _isWalkInMode)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Form',
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: SafeArea(child: content),
    );
  }

  Widget _patientResultCard(Patient p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: InkWell(
        onTap: () => _selectPatient(p),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.roleAdminLight,
                child: Text(
                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: AppColors.roleAdmin, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        if (p.age != null)
                          Text(
                            'Age: ${p.age}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mobile: ${p.phoneNumber} • ${p.patientId}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.roleAdmin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedPatientCard(Patient p) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.roleAdmin, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  color: AppColors.roleAdmin, size: 20),
              const SizedBox(width: 6),
              const Text('Selected Patient',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.roleAdmin)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text('✓ QR Linked',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _clearSelection,
                child: const Text('Change',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            'Age: ${p.age ?? 'Not specified'} • Phone: ${p.phoneNumber} • ID: ${p.patientId}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _walkInFormCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 6),
              const Text('New Patient / Walk-in',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: const Text('No QR',
                    style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _clearSelection,
                child: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Patient Name *',
              hintText: 'Enter full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age *',
                    hintText: 'e.g. 34',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gender',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                      children: ['Male', 'Female', 'Other'].map((g) {
                        final isSel = _selectedGender == g;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ChoiceChip(
                              label: Text(g,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSel
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                              selected: isSel,
                              onSelected: (_) =>
                                  setState(() => _selectedGender = g),
                              selectedColor: AppColors.primaryContainer,
                              labelStyle: TextStyle(
                                color: isSel
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _categorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categoryData.map((cat) {
        final name = cat['name'] as String;
        final icon = cat['icon'] as IconData;
        final isSelected = _selectedCategory == name;

        return InkWell(
          onTap: () => setState(() => _selectedCategory = name),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.roleAdmin
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AppColors.roleAdmin
                    : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.roleAdmin,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _historySlipCard(OpdAppointment slip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: slip.isRegistered
                  ? AppColors.primaryContainer
                  : AppColors.success.withValues(alpha: 0.15),
              child: Text(
                slip.patientName.isNotEmpty
                    ? slip.patientName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: slip.isRegistered
                      ? AppColors.primaryDark
                      : AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slip.patientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${slip.doctorCategory} • ${slip.appointmentTime} • ${slip.isRegistered ? 'Registered' : 'Walk-in'}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined, size: 20),
              tooltip: 'Print Slip',
              onPressed: () => _showSlipPreviewDialog(slip),
            ),
          ],
        ),
      ),
    );
  }
}
