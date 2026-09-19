import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_state_provider.dart';
import '../../services/firestore/patient_qr_service.dart';

/// QR scanner screen for doctors to scan patient QR codes.
///
/// Uses `mobile_scanner` for camera-based QR detection.
/// One-shot scan: camera stops immediately upon valid detection to prevent
/// duplicate database queries. Includes manual entry fallback for
/// desktop/simulator testing.
class DoctorQrScannerScreen extends StatefulWidget {
  const DoctorQrScannerScreen({super.key});

  @override
  State<DoctorQrScannerScreen> createState() => _DoctorQrScannerScreenState();
}

class _DoctorQrScannerScreenState extends State<DoctorQrScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_hasScanned || _isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _hasScanned = true;
      _isProcessing = true;
      _errorMessage = null;
    });

    // Stop scanning immediately to prevent duplicate queries
    _controller?.stop();

    await _processQrPayload(rawValue);
  }

  Future<void> _processQrPayload(String rawPayload) async {
    final appState = context.read<AppStateProvider>();

    // Verify doctor authorization
    if (!appState.isDoctorSession) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Doctor authorization required.';
      });
      return;
    }

    try {
      if (!mounted) return;

      final payload = rawPayload.trim();
      String? resolvedPatientId;

      if (payload.startsWith('SIH_PATIENT:')) {
        // Backwards compatibility for original/legacy QR codes
        final qrService = context.read<PatientQrService>();
        final result = await qrService.validateAndResolveQr(payload);
        if (result.success && result.patientId != null) {
          resolvedPatientId = result.patientId;
        } else {
          setState(() {
            _isProcessing = false;
            _errorMessage = result.errorMessage ?? 'Invalid legacy QR code.';
          });
          return;
        }
      } else if (payload.isNotEmpty) {
        // New static QR code format (raw patientId)
        resolvedPatientId = payload;
      }

      if (resolvedPatientId != null && resolvedPatientId.isNotEmpty) {
        setState(() {
          _isProcessing = false;
          _successMessage = 'Patient found';
        });

        // Short delay to show success before navigating
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          context.pushReplacement(
            RouteNames.doctorPatientRecord,
            extra: resolvedPatientId,
          );
        }
      } else {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Invalid patient QR code format.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Unable to verify QR code. Please try again.';
        });
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _isProcessing = false;
      _errorMessage = null;
      _successMessage = null;
    });
    _controller?.start();
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manual QR Entry'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter QR payload (SIH_PATIENT:...)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final value = textController.text.trim();
              if (value.isNotEmpty) {
                setState(() {
                  _hasScanned = true;
                  _isProcessing = true;
                  _errorMessage = null;
                });
                _controller?.stop();
                _processQrPayload(value);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Patient QR'),
        actions: [
          // Torch toggle
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            tooltip: 'Toggle Flashlight',
            onPressed: () => _controller?.toggleTorch(),
          ),
          // Switch camera
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded),
            tooltip: 'Switch Camera',
            onPressed: () => _controller?.switchCamera(),
          ),
          // Manual entry (for testing)
          IconButton(
            icon: const Icon(Icons.keyboard_rounded),
            tooltip: 'Manual Entry',
            onPressed: _showManualEntryDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onBarcodeDetected,
            ),

          // Scanning reticle overlay
          if (!_hasScanned)
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
              ),
            ),

          // Processing / Result overlay
          if (_isProcessing || _errorMessage != null || _successMessage != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(AppTheme.spacingXl),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isProcessing) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppTheme.spacingLg),
                          const Text('Verifying QR code...'),
                        ],
                        if (_successMessage != null) ...[
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 56,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            _successMessage!,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.error,
                            size: 56,
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                          ElevatedButton.icon(
                            onPressed: _resetScanner,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Scan Again'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 48),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom instruction
          if (!_hasScanned)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Text(
                    'Point camera at patient QR code',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
