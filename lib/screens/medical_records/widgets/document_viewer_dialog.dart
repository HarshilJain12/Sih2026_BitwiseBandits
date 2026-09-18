import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/medical_record.dart';
import '../../../services/firestore/medical_record_service.dart';

/// Handles opening and viewing medical records safely without public URLs.
class DocumentViewerDialog {
  DocumentViewerDialog._();

  /// Opens a medical record based on its MIME type:
  /// - Image: In-app modal viewer with zoom/pan.
  /// - PDF: Writes to temp cache and launches system viewer with [OpenFilex].
  static Future<void> openRecord({
    required BuildContext context,
    required MedicalRecord record,
    required MedicalRecordService service,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final isPdf = record.mimeType.contains('pdf') ||
        record.originalFileName.toLowerCase().endsWith('.pdf');

    // Show loading snackbar / indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Text(l10n.openingDocument),
          ],
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final bytes = await service.getDocumentBytes(record);
      scaffoldMessenger.hideCurrentSnackBar();

      if (bytes == null || bytes.isEmpty) {
        if (!context.mounted) return;
        _showErrorSnackBar(scaffoldMessenger, l10n.errorOpenDocumentFailed);
        return;
      }

      if (isPdf) {
        // PDF: Save temporary copy in cache directory and open via OpenFilex
        final tempDir = await getTemporaryDirectory();
        final safeName = record.originalFileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final tempFile = File('${tempDir.path}/view_${record.recordId}_$safeName');
        await tempFile.writeAsBytes(bytes, flush: true);

        final result = await OpenFilex.open(tempFile.path);
        if (result.type != ResultType.done && kDebugMode) {
          debugPrint('[DocumentViewer] OpenFilex result: ${result.message}');
        }
      } else {
        // Image: Display in-app zoomable image viewer dialog
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => _ImageViewerDialog(
            record: record,
            imageBytes: bytes,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DocumentViewer] Error opening document: $e');
      }
      scaffoldMessenger.hideCurrentSnackBar();
      _showErrorSnackBar(scaffoldMessenger, l10n.errorOpenDocumentFailed);
    }
  }

  static void _showErrorSnackBar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ImageViewerDialog extends StatelessWidget {
  const _ImageViewerDialog({
    required this.record,
    required this.imageBytes,
  });

  final MedicalRecord record;
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.92),
      insetPadding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── App Bar / Header ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            color: Colors.black87,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    record.originalFileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // ── Interactive Zoomable Image ────────────────────────────────
          Flexible(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                imageBytes,
                fit: BoxFit.contain,
                errorBuilder: (ctx, error, stack) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),

          // ── Notes Footer if available ─────────────────────────────────
          if (record.notes != null && record.notes!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              color: Colors.black87,
              child: Text(
                record.notes!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
