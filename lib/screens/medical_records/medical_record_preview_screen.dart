import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_record_category.dart';
import '../../services/firestore/medical_record_service.dart';
import '../../services/storage/medical_record_storage.dart';
import '../../widgets/buttons/primary_button.dart';
import '../../widgets/buttons/secondary_button.dart';
import 'widgets/medical_record_upload_dialog.dart';

/// Screen allowing the patient to preview selected file, add optional notes, and confirm upload.
class MedicalRecordPreviewScreen extends StatefulWidget {
  const MedicalRecordPreviewScreen({
    super.key,
    required this.patientId,
    required this.category,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.bytes,
    this.isRegistration = false,
  });

  final String patientId;
  final MedicalRecordCategory category;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final Uint8List bytes;
  final bool isRegistration;

  @override
  State<MedicalRecordPreviewScreen> createState() =>
      _MedicalRecordPreviewScreenState();
}

class _MedicalRecordPreviewScreenState
    extends State<MedicalRecordPreviewScreen> {
  late String _currentFileName;
  late int _currentFileSize;
  late String _currentMimeType;
  late Uint8List _currentBytes;
  late MedicalRecordCategory _currentCategory;

  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFileName = widget.fileName;
    _currentFileSize = widget.fileSizeBytes;
    _currentMimeType = widget.mimeType;
    _currentBytes = widget.bytes;
    _currentCategory = widget.category;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleChangeFile() async {
    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result.isEmpty) return;

      final file = result.first;
      Uint8List? bytes;

      if (file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          bytes = await ioFile.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorUnsupportedFormat),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!MedicalRecordStorage.isValidFileSize(bytes.length)) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorFileSizeExceeded),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final mimeType = MedicalRecordStorage.resolveMimeType(file.name, null);
      if (!MedicalRecordStorage.isValidMimeType(mimeType)) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorUnsupportedFormat),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      setState(() {
        _currentFileName = file.name;
        _currentFileSize = bytes!.length;
        _currentMimeType = mimeType;
        _currentBytes = bytes;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PreviewScreen] Change file error: $e');
      }
    }
  }

  Future<void> _handleUpload() async {
    final service = context.read<MedicalRecordService>();

    final createdRecord = await MedicalRecordUploadDialog.startUpload(
      context,
      patientId: widget.patientId,
      fileName: _currentFileName,
      bytes: _currentBytes,
      mimeType: _currentMimeType,
      category: _currentCategory.id,
      notes: _notesController.text,
      service: service,
    );

    if (createdRecord != null && mounted) {
      context.go(
        RouteNames.medicalRecordSuccess,
        extra: {
          'patientId': widget.patientId,
          'isRegistration': widget.isRegistration,
          'record': createdRecord,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPdf = _currentMimeType.contains('pdf') ||
        _currentFileName.toLowerCase().endsWith('.pdf');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.documentPreviewTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.documentPreviewSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Document Preview Visual Container ─────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  children: [
                    if (!isPdf)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          width: double.infinity,
                          color: AppColors.background,
                          child: Image.memory(
                            _currentBytes,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, stack) => const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFFD32F2F),
                              size: 56,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PDF DOCUMENT',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD32F2F),
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Metadata table ──────────────────────────────────────
                    _MetaRow(
                      label: l10n.categoryLabel,
                      value: _currentCategory.getLocalizedTitle(l10n),
                      icon: _currentCategory.icon,
                      accentColor: _currentCategory.accentColor,
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    _MetaRow(
                      label: l10n.fileNameLabel,
                      value: _currentFileName,
                      isBold: true,
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    _MetaRow(
                      label: l10n.fileSizeLabel,
                      value: _formatFileSize(_currentFileSize),
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    _MetaRow(
                      label: l10n.fileTypeLabel,
                      value: isPdf ? 'PDF' : 'Image ($ext)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Optional Notes Field ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.notesLabel,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: l10n.notesHint,
                        hintStyle: const TextStyle(color: AppColors.textHint),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Action Buttons ────────────────────────────────────────────
              PrimaryButton(
                label: l10n.uploadButton,
                icon: Icons.cloud_upload_rounded,
                onPressed: _handleUpload,
              ),

              const SizedBox(height: AppTheme.spacingSm),

              SecondaryButton(
                label: l10n.changeFileButton,
                icon: Icons.folder_open_rounded,
                onPressed: _handleChangeFile,
              ),

              const SizedBox(height: AppTheme.spacingSm),

              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get ext {
    final dot = _currentFileName.lastIndexOf('.');
    if (dot != -1 && dot < _currentFileName.length - 1) {
      return _currentFileName.substring(dot + 1).toUpperCase();
    }
    return 'IMG';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        if (icon != null) ...[
          Icon(icon, size: 16, color: accentColor ?? AppColors.primary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                  color: accentColor ?? AppColors.textPrimary,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
