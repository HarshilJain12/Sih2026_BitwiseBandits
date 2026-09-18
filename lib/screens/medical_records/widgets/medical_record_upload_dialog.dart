import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/medical_record.dart';
import '../../../services/firestore/medical_record_service.dart';

/// Modal dialog showing uploading state and handling the upload transaction.
class MedicalRecordUploadDialog extends StatefulWidget {
  const MedicalRecordUploadDialog({
    super.key,
    required this.patientId,
    required this.fileName,
    required this.bytes,
    required this.mimeType,
    required this.category,
    this.notes,
    required this.service,
  });

  final String patientId;
  final String fileName;
  final Uint8List bytes;
  final String mimeType;
  final String category;
  final String? notes;
  final MedicalRecordService service;

  static Future<MedicalRecord?> startUpload(
    BuildContext context, {
    required String patientId,
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    required String category,
    String? notes,
    required MedicalRecordService service,
  }) {
    return showDialog<MedicalRecord>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MedicalRecordUploadDialog(
        patientId: patientId,
        fileName: fileName,
        bytes: bytes,
        mimeType: mimeType,
        category: category,
        notes: notes,
        service: service,
      ),
    );
  }

  @override
  State<MedicalRecordUploadDialog> createState() =>
      _MedicalRecordUploadDialogState();
}

class _MedicalRecordUploadDialogState extends State<MedicalRecordUploadDialog> {
  bool _isUploading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performUpload();
  }

  Future<void> _performUpload() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final record = await widget.service.uploadAndCreateRecord(
        patientId: widget.patientId,
        originalFileName: widget.fileName,
        bytes: widget.bytes,
        mimeType: widget.mimeType,
        category: widget.category,
        notes: widget.notes?.trim().isEmpty == true ? null : widget.notes?.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(record);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MedicalRecordUploadDialog] Upload failed: $e');
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isUploading = false;
          _errorMessage = l10n.errorUploadFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_isUploading,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isUploading) ...[
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text(
                  l10n.uploadingTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  widget.fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  _errorMessage ?? l10n.errorUploadFailed,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: _performUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.tryAgain),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
