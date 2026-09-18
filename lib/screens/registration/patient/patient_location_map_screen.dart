import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/patient.dart';
import '../../../models/patient_location.dart';
import '../../../services/firestore/patient_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/error_message.dart';

/// Screen allowing the user to visually select and confirm their location on a Google Map
/// using a center-fixed pin picker.
class PatientLocationMapScreen extends StatefulWidget {
  const PatientLocationMapScreen({
    super.key,
    required this.patient,
    required this.initialLat,
    required this.initialLng,
  });

  final Patient patient;
  final double initialLat;
  final double initialLng;

  @override
  State<PatientLocationMapScreen> createState() =>
      _PatientLocationMapScreenState();
}

class _PatientLocationMapScreenState extends State<PatientLocationMapScreen> {
  late LatLng _currentCenter;
  GoogleMapController? _mapController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentCenter = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
  }

  Future<void> _onConfirmLocation() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final patientService = context.read<PatientService>();

      final location = PatientLocation(
        source: 'gps',
        latitude: _currentCenter.latitude,
        longitude: _currentCenter.longitude,
      );

      final updatedPatient = await patientService.updatePatientLocation(
        patientId: widget.patient.patientId,
        location: location,
      );

      if (!mounted) return;

      context.go(RouteNames.patientLocationSuccess, extra: updatedPatient);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientLocationMapScreen] Error saving location: $e');
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = l10n.errorGeneric;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Google Map (Full screen background) ─────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initialLat, widget.initialLng),
              zoom: 15.0,
            ),
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
          ),

          // ── Fixed Center Pin ─────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 36.0,
              ), // Align pin tip with center
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Top Navigation & Instruction Bar ─────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.adjustPinPrompt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Recenter FAB Button ──────────────────────────────────────
          Positioned(
            right: AppTheme.spacingMd,
            bottom: 220,
            child: FloatingActionButton.small(
              heroTag: 'recenter_gps_fab',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(widget.initialLat, widget.initialLng),
                  ),
                );
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // ── Bottom Information & Confirmation Card ───────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Text(
                          l10n.selectedLocation,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                          ),
                          child: const Text(
                            'GPS',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      '${widget.patient.name} (${widget.patient.patientId})',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    if (_errorMessage != null) ...[
                      ErrorMessage(message: _errorMessage!),
                      const SizedBox(height: AppTheme.spacingSm),
                    ],
                    PrimaryButton(
                      label: l10n.confirmLocation,
                      onPressed: _isSaving ? null : _onConfirmLocation,
                      isLoading: _isSaving,
                      icon: Icons.check_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
