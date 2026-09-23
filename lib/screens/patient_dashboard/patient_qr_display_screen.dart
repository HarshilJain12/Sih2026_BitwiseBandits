import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/patient.dart';
import '../../services/firestore/patient_qr_service.dart';
import '../../services/firestore/patient_service.dart';

/// Displays the patient's unique QR code for doctor scanning.
///
/// The QR encodes only `SIH_PATIENT:<qrToken>` — no medical data.
/// Works identically when displayed on phone screen or printed on OPD slip.
class PatientQrDisplayScreen extends StatefulWidget {
  const PatientQrDisplayScreen({super.key, this.patient});

  final Patient? patient;

  @override
  State<PatientQrDisplayScreen> createState() => _PatientQrDisplayScreenState();
}

class _PatientQrDisplayScreenState extends State<PatientQrDisplayScreen> {
  Patient? _patient;
  String? _qrPayload;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final patientService = context.read<PatientService>();

      Patient? patient = widget.patient;
      if (patient == null) {
        final linked = await patientService.getLinkedPatients();
        if (linked.isNotEmpty) {
          patient = linked.first;
        }
      }

      if (patient == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No patient profile found.';
        });
        return;
      }

      setState(() {
        _patient = patient;
        _qrPayload = patient!.patientId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load QR code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('My Patient QR'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
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
                          onPressed: _loadQr,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildQrContent(),
    );
  }

  Widget _buildQrContent() {
    final patient = _patient!;
    
    Widget qrWidget;
    if (patient.qrCodeBase64 != null && patient.qrCodeBase64!.isNotEmpty) {
      try {
        final b64 = patient.qrCodeBase64!.split(',').last;
        qrWidget = Image.memory(
          base64Decode(b64),
          width: 240,
          height: 240,
          fit: BoxFit.contain,
        );
      } catch (e) {
        // Fallback to generating it if base64 is malformed
        qrWidget = QrImageView(
          data: _qrPayload!,
          version: QrVersions.auto,
          size: 240,
          backgroundColor: Colors.white,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          padding: const EdgeInsets.all(8),
        );
      }
    } else {
      // Fallback if not generated yet
      qrWidget = QrImageView(
        data: _qrPayload!,
        version: QrVersions.auto,
        size: 240,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        padding: const EdgeInsets.all(8),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacingMd),

            // Patient name
            Text(
              patient.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),

            // Patient ID
            Text(
              'Patient ID: ${patient.patientId}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // QR Code Card — high contrast for print & screen
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: qrWidget,
                    ),

                    const SizedBox(height: AppTheme.spacingLg),

                    Text(
                      patient.patientId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Instruction text
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      'Show this QR code to your doctor or hospital OPD for quick record access.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
