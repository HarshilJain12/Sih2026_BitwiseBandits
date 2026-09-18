import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/patient.dart';
import '../../../services/location/location_service.dart';
import '../../../widgets/common/error_message.dart';

/// Screen offering the user two clear choices for providing their location:
/// 1. Use Current Location (GPS + Google Maps)
/// 2. Enter Location Manually (Village, District, State, PIN)
class PatientLocationChoiceScreen extends StatefulWidget {
  const PatientLocationChoiceScreen({
    super.key,
    required this.patient,
    this.locationService = const LocationService(),
  });

  final Patient patient;
  final LocationService locationService;

  @override
  State<PatientLocationChoiceScreen> createState() =>
      _PatientLocationChoiceScreenState();
}

class _PatientLocationChoiceScreenState
    extends State<PatientLocationChoiceScreen> {
  bool _isFetchingGps = false;
  String? _errorMessage;

  Future<void> _onUseCurrentLocation() async {
    if (_isFetchingGps) return;

    setState(() {
      _isFetchingGps = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await widget.locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() => _isFetchingGps = false);

      switch (result.status) {
        case LocationFetchStatus.success:
          if (result.position != null) {
            context.push(
              RouteNames.patientLocationMap,
              extra: {
                'patient': widget.patient,
                'initialLat': result.position!.latitude,
                'initialLng': result.position!.longitude,
              },
            );
          }
          break;

        case LocationFetchStatus.servicesDisabled:
          _showLocationDialog(
            title: l10n.locationServicesDisabled,
            message: l10n.locationServicesDisabled,
            actionLabel: l10n.openSettings,
            onAction: () async {
              await widget.locationService.openLocationSettings();
            },
          );
          break;

        case LocationFetchStatus.permissionDenied:
          _showLocationDialog(
            title: l10n.locationPermissionRequired,
            message: l10n.locationPermissionRequired,
            actionLabel: l10n.tryAgain,
            onAction: _onUseCurrentLocation,
          );
          break;

        case LocationFetchStatus.permissionDeniedForever:
          _showLocationDialog(
            title: l10n.locationPermissionRequired,
            message: l10n.locationPermissionRequired,
            actionLabel: l10n.openSettings,
            onAction: () async {
              await widget.locationService.openAppSettings();
            },
          );
          break;

        case LocationFetchStatus.timeoutOrError:
          setState(() {
            _errorMessage = l10n.locationFetchFailed;
          });
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingGps = false;
          _errorMessage = l10n.locationFetchFailed;
        });
      }
    }
  }

  void _showLocationDialog({
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(
                RouteNames.patientLocationManual,
                extra: widget.patient,
              );
            },
            child: Text(
              l10n.enterLocationManually,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onAction();
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _onEnterManually() {
    context.push(RouteNames.patientLocationManual, extra: widget.patient);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTheme.spacingSm),

              // ── Header ──────────────────────────────────────────────
              Text(
                l10n.locationTitle,
                style: Theme.of(context).textTheme.displayMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                l10n.locationSubtitle,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary),
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Patient ID Pill ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.patient.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          Text(
                            'ID: ${widget.patient.patientId}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // ── Option A: Current Location ───────────────────────────
              _LocationOptionCard(
                title: l10n.useCurrentLocation,
                description: l10n.useCurrentLocationDesc,
                icon: Icons.my_location_rounded,
                iconColor: AppColors.primary,
                iconBgColor: AppColors.primaryLight,
                isLoading: _isFetchingGps,
                onTap: _isFetchingGps ? null : _onUseCurrentLocation,
              ),

              const SizedBox(height: AppTheme.spacingMd),

              // ── Option B: Enter Manually ─────────────────────────────
              _LocationOptionCard(
                title: l10n.enterLocationManually,
                description: l10n.enterLocationManuallyDesc,
                icon: Icons.edit_location_alt_rounded,
                iconColor: AppColors.secondary,
                iconBgColor: AppColors.secondaryLight,
                isLoading: false,
                onTap: _isFetchingGps ? null : _onEnterManually,
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // ── Error Message Banner (if any) ────────────────────────
              if (_errorMessage != null) ...[
                ErrorMessage(message: _errorMessage!),
                const SizedBox(height: AppTheme.spacingMd),
                OutlinedButton.icon(
                  onPressed: _onEnterManually,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(l10n.orEnterManually),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationOptionCard extends StatelessWidget {
  const _LocationOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.isLoading,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(icon, color: iconColor, size: 28),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
