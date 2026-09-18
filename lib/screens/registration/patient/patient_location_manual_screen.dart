import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/patient.dart';
import '../../../models/patient_location.dart';
import '../../../services/firestore/patient_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// Screen for manual patient address and location registration.
class PatientLocationManualScreen extends StatefulWidget {
  const PatientLocationManualScreen({super.key, required this.patient});

  final Patient patient;

  @override
  State<PatientLocationManualScreen> createState() =>
      _PatientLocationManualScreenState();
}

class _PatientLocationManualScreenState
    extends State<PatientLocationManualScreen> {
  final _formKey = GlobalKey<FormState>();

  final _villageController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController(text: 'Maharashtra');
  final _pincodeController = TextEditingController();
  final _addressController = TextEditingController();

  String? _villageError;
  String? _districtError;
  String? _stateError;
  String? _pincodeError;
  String? _errorMessage;

  bool _isLoading = false;

  @override
  void dispose() {
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _resolveValidationError(AppLocalizations l10n, String? key) {
    if (key == null) return null;
    switch (key) {
      case 'validation_village':
        return l10n.validationVillage;
      case 'validation_district':
        return l10n.validationDistrict;
      case 'validation_state':
        return l10n.validationState;
      case 'validation_pincode':
        return l10n.validationPincode;
      case 'validation_required':
        return l10n.validationRequired;
      default:
        return l10n.errorGeneric;
    }
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;

    final l10n = AppLocalizations.of(context)!;

    final villageVal = Validators.village(_villageController.text);
    final districtVal = Validators.district(_districtController.text);
    final stateVal = Validators.state(_stateController.text);
    final pincodeVal = Validators.pincode(_pincodeController.text);

    setState(() {
      _villageError = _resolveValidationError(l10n, villageVal);
      _districtError = _resolveValidationError(l10n, districtVal);
      _stateError = _resolveValidationError(l10n, stateVal);
      _pincodeError = _resolveValidationError(l10n, pincodeVal);
      _errorMessage = null;
    });

    if (villageVal != null ||
        districtVal != null ||
        stateVal != null ||
        pincodeVal != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final patientService = context.read<PatientService>();

      final location = PatientLocation(
        source: 'manual',
        village: _villageController.text.trim(),
        district: _districtController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
      );

      final updatedPatient = await patientService.updatePatientLocation(
        patientId: widget.patient.patientId,
        location: location,
      );

      if (!mounted) return;

      context.go(RouteNames.patientLocationSuccess, extra: updatedPatient);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientLocationManualScreen] Error saving location: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppTheme.spacingSm),

                // ── Header ──────────────────────────────────────────────
                Text(
                  l10n.enterLocationManually,
                  style: Theme.of(context).textTheme.displayMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  l10n.enterLocationManuallyDesc,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Village / Town ──────────────────────────────────────
                AppTextField(
                  controller: _villageController,
                  label: l10n.village,
                  hint: l10n.villageHint,
                  errorText: _villageError,
                  prefixIcon: Icons.home_work_outlined,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_villageError != null) {
                      setState(() => _villageError = null);
                    }
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── District ────────────────────────────────────────────
                AppTextField(
                  controller: _districtController,
                  label: l10n.district,
                  hint: l10n.districtHint,
                  errorText: _districtError,
                  prefixIcon: Icons.location_city_outlined,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_districtError != null) {
                      setState(() => _districtError = null);
                    }
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── State ───────────────────────────────────────────────
                AppTextField(
                  controller: _stateController,
                  label: l10n.state,
                  hint: l10n.stateHint,
                  errorText: _stateError,
                  prefixIcon: Icons.map_outlined,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_stateError != null) {
                      setState(() => _stateError = null);
                    }
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── PIN Code ────────────────────────────────────────────
                AppTextField(
                  controller: _pincodeController,
                  label: l10n.pincode,
                  hint: l10n.pincodeHint,
                  errorText: _pincodeError,
                  prefixIcon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) {
                    if (_pincodeError != null) {
                      setState(() => _pincodeError = null);
                    }
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Full Address (Optional) ─────────────────────────────
                AppTextField(
                  controller: _addressController,
                  label: l10n.fullAddress,
                  hint: l10n.fullAddressHint,
                  prefixIcon: Icons.notes_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onSubmit(),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Error Banner ─────────────────────────────────────────
                if (_errorMessage != null) ...[
                  ErrorMessage(message: _errorMessage!),
                  const SizedBox(height: AppTheme.spacingMd),
                ],

                // ── Submit Button ────────────────────────────────────────
                PrimaryButton(
                  label: l10n.saveLocationButton,
                  onPressed: _isLoading ? null : _onSubmit,
                  isLoading: _isLoading,
                  icon: Icons.check_circle_outline_rounded,
                ),

                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
