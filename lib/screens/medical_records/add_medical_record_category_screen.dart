import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/medical_record_category.dart';
import '../../services/storage/medical_record_storage.dart';

/// Screen allowing the patient to select a document category before picking a file.
class AddMedicalRecordCategoryScreen extends StatefulWidget {
  const AddMedicalRecordCategoryScreen({
    super.key,
    required this.patientId,
    this.isRegistration = false,
  });

  final String patientId;
  final bool isRegistration;

  @override
  State<AddMedicalRecordCategoryScreen> createState() =>
      _AddMedicalRecordCategoryScreenState();
}

class _AddMedicalRecordCategoryScreenState
    extends State<AddMedicalRecordCategoryScreen> {
  bool _isPicking = false;

  Future<void> _handleCategorySelected(MedicalRecordCategory category) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (!mounted) return;
      setState(() => _isPicking = false);

      if (result.isEmpty) {
        // User cancelled file picking - no error needed
        return;
      }

      final file = result.first;
      Uint8List? bytes;

      if (file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          bytes = await ioFile.readAsBytes();
        }
      }

      if (!mounted) return;

      if (bytes == null || bytes.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorUnsupportedFormat),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate File Size (<= 10 MB)
      if (!MedicalRecordStorage.isValidFileSize(bytes.length)) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorFileSizeExceeded),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Validate MIME type
      final mimeType = MedicalRecordStorage.resolveMimeType(
        file.name,
        null,
      );
      if (!MedicalRecordStorage.isValidMimeType(mimeType)) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorUnsupportedFormat),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (!mounted) return;

      // Navigate to Confirmation & Preview Screen
      context.push(
        RouteNames.medicalRecordPreview,
        extra: {
          'patientId': widget.patientId,
          'isRegistration': widget.isRegistration,
          'category': category,
          'fileName': file.name,
          'fileSizeBytes': bytes.length,
          'mimeType': mimeType,
          'bytes': bytes,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CategoryScreen] File pick error: $e');
      }
      if (mounted) {
        setState(() => _isPicking = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.errorUnsupportedFormat),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          l10n.selectCategoryTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLg,
            vertical: AppTheme.spacingMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.selectCategorySubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.supportedFormatsNotice,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Category Selection Cards ──────────────────────────────────
              ...MedicalRecordCategory.values.map(
                (cat) => _CategoryCard(
                  category: cat,
                  title: cat.getLocalizedTitle(l10n),
                  subtitle: cat.getLocalizedSubtitle(l10n),
                  isLoading: _isPicking,
                  onTap: () => _handleCategorySelected(cat),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  final MedicalRecordCategory category;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: category.containerColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Center(
                    child: Icon(
                      category.icon,
                      color: category.accentColor,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: category.accentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
