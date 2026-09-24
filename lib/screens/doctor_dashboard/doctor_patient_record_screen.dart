import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/medical_record.dart';
import '../../models/medical_record_category.dart';
import '../../models/patient.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore/medical_record_service.dart';
import '../../services/firestore/patient_service.dart';
import '../doctor/widgets/doctor_patient_ai_summary_view.dart';
import '../medical_records/widgets/document_viewer_dialog.dart';

/// Unified Patient Medical Record screen for doctors.
///
/// Accessed from QR scan, name search, or appointment tap — all converge here.
/// Shows patient header, health tags, medical history, and doctor upload actions.
class DoctorPatientRecordScreen extends StatefulWidget {
  const DoctorPatientRecordScreen({super.key, required this.patientId});

  final String patientId;

  @override
  State<DoctorPatientRecordScreen> createState() =>
      _DoctorPatientRecordScreenState();
}

class _DoctorPatientRecordScreenState extends State<DoctorPatientRecordScreen> {
  Patient? _patient;
  List<MedicalRecord> _records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final patientService = context.read<PatientService>();
      final recordService = context.read<MedicalRecordService>();

      final patient = await patientService.getPatientById(widget.patientId);
      if (patient == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Patient record not found.';
        });
        return;
      }

      final records = await recordService.getRecordsForDoctor(widget.patientId);

      if (mounted) {
        setState(() {
          _patient = patient;
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load patient record.';
        });
      }
    }
  }

  void _showAddRecordSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddRecordSheet(
        patientId: widget.patientId,
        onRecordAdded: () {
          _loadPatientData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical record added successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Patient Record'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildRecordView(),
      floatingActionButton: _patient != null
          ? FloatingActionButton.extended(
              onPressed: _showAddRecordSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Medical Record'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: _loadPatientData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordView() {
    final patient = _patient!;

    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Patient Header ──────────────────────────────────
            _buildPatientHeader(patient),

            const SizedBox(height: AppTheme.spacingLg),

            // ── Health Tags ──────────────────────────────────────
            _buildHealthTags(patient),

            const SizedBox(height: AppTheme.spacingLg),

            // ── AI Health Summary & Clinical Insights ────────────
            DoctorPatientAiSummaryView(patient: patient),

            const SizedBox(height: AppTheme.spacingXl),

            // ── Medical History ──────────────────────────────────
            _buildMedicalHistory(),

            const SizedBox(height: 80), // FAB clearance
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(Patient patient) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    patient.name.isNotEmpty
                        ? patient.name[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Patient ID: ${patient.patientId}',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: AppTheme.spacingLg,
              runSpacing: AppTheme.spacingSm,
              children: [
                if (patient.age != null)
                  _buildInfoChip(Icons.cake_rounded, 'Age: ${patient.age}'),
                if (patient.weightKg != null)
                  _buildInfoChip(
                      Icons.monitor_weight_rounded, '${patient.weightKg} kg'),
                if (patient.heightCm != null)
                  _buildInfoChip(
                      Icons.height_rounded, '${patient.heightCm} cm'),
                if (patient.location != null &&
                    patient.location!.village != null)
                  _buildInfoChip(Icons.location_on_rounded,
                      patient.location!.village!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildHealthTags(Patient patient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HEALTH TAGS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (patient.healthTags.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              'No health tags recorded.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: patient.healthTags.map((tag) {
              final tagColor = _getTagColor(tag);
              return Chip(
                label: Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                backgroundColor: tagColor.withValues(alpha: 0.12),
                side: BorderSide(color: tagColor.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            }).toList(),
          ),
      ],
    );
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'diabetic':
      case 'diabetes':
        return const Color(0xFFE67E22);
      case 'hypertension':
        return const Color(0xFFE74C3C);
      case 'pregnant':
        return const Color(0xFF9B59B6);
      case 'allergy':
        return const Color(0xFF3498DB);
      case 'asthma':
        return const Color(0xFF1ABC9C);
      case 'aids':
      case 'hiv':
        return const Color(0xFFE74C3C);
      default:
        return AppColors.primary;
    }
  }

  Widget _buildMedicalHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MEDICAL HISTORY',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (_records.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              'No medical records available.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          )
        else
          ..._records.map((record) => _buildRecordCard(record)),
      ],
    );
  }

  Widget _buildRecordCard(MedicalRecord record) {
    final dateStr =
        '${record.uploadedAt.day} ${_monthName(record.uploadedAt.month)} ${record.uploadedAt.year}';

    // Use existing MedicalRecordCategory API for label
    String categoryLabel;
    if (record.category != null) {
      final cat = MedicalRecordCategory.fromId(record.category);
      // Capitalize the id for display without requiring localization context
      categoryLabel = cat.id.replaceAll('_', ' ');
      categoryLabel = categoryLabel[0].toUpperCase() + categoryLabel.substring(1);
    } else {
      categoryLabel = 'Medical Record';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (record.isDoctorRecord) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.medical_services_rounded,
                                  size: 12, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                'Dr. ${record.doctorName ?? "Doctor"}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                'Notes: ${record.notes}',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (record.originalFileName.isNotEmpty &&
                record.storagePath.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingSm),
              InkWell(
                onTap: () {
                  final recordService = context.read<MedicalRecordService>();
                  DocumentViewerDialog.openRecord(
                    context: context,
                    record: record,
                    service: recordService,
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        record.mimeType.contains('pdf')
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          record.originalFileName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month];
  }
}

/// Bottom sheet for adding a new medical record (notes or document upload).
class _AddRecordSheet extends StatefulWidget {
  const _AddRecordSheet({
    required this.patientId,
    required this.onRecordAdded,
  });

  final String patientId;
  final VoidCallback onRecordAdded;

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  final _notesController = TextEditingController();
  String _selectedCategory = 'consultation';
  bool _isUploading = false;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;
  String? _selectedFileMime;
  String? _errorMessage;

  static const _categories = [
    ('consultation', 'Consultation'),
    ('lab_report', 'Lab Report'),
    ('prescription', 'Prescription'),
    ('scan', 'Scan / X-Ray'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isNotEmpty) {
        final file = result.first;
        
        Uint8List? bytes;
        if (file.path != null) {
          final ioFile = File(file.path!);
          if (await ioFile.exists()) {
            bytes = await ioFile.readAsBytes();
          }
        }

        if (bytes == null) {
          setState(() => _errorMessage = 'Unable to read file content.');
          return;
        }

        // Validate file size (10 MB max)
        if (bytes.length > 10 * 1024 * 1024) {
          setState(() => _errorMessage = 'File exceeds 10 MB limit.');
          return;
        }

        String mimeType = 'application/octet-stream';
        final ext = file.extension?.toLowerCase();
        if (ext == 'pdf') {
          mimeType = 'application/pdf';
        } else if (ext == 'jpg' || ext == 'jpeg') {
          mimeType = 'image/jpeg';
        } else if (ext == 'png') {
          mimeType = 'image/png';
        }

        setState(() {
          _selectedFileName = file.name;
          _selectedFileBytes = bytes;
          _selectedFileMime = mimeType;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Unable to select file.');
    }
  }

  Future<void> _submitRecord() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty && _selectedFileBytes == null) {
      setState(() => _errorMessage = 'Please add notes or upload a document.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final appState = context.read<AppStateProvider>();
      final recordService = context.read<MedicalRecordService>();

      await recordService.addDoctorRecord(
        patientId: widget.patientId,
        doctorUid: appState.activeDoctorId ?? '',
        doctorName: appState.activeDoctorName ?? 'Doctor',
        doctorSpecialization: appState.activeDoctorSpecialization,
        category: _selectedCategory,
        notes: notes.isNotEmpty ? notes : null,
        originalFileName: _selectedFileName,
        bytes: _selectedFileBytes,
        mimeType: _selectedFileMime,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRecordAdded();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Failed to add record. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.spacingLg,
        right: AppTheme.spacingLg,
        top: AppTheme.spacingLg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            Text(
              'Add Medical Record',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) =>
                      DropdownMenuItem(value: c.$1, child: Text(c.$2)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Clinical Notes',
                hintText: 'Enter diagnosis, observations, instructions...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // File picker
            OutlinedButton.icon(
              onPressed: _isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(_selectedFileName ?? 'Upload Document (PDF, JPG, PNG)'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            if (_selectedFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF10B981)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        setState(() {
                          _selectedFileName = null;
                          _selectedFileBytes = null;
                          _selectedFileMime = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spacingSm),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ),

            const SizedBox(height: AppTheme.spacingLg),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Record'),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}
