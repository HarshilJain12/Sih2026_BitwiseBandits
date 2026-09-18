import 'package:firebase_auth/firebase_auth.dart';
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
import '../../../services/firestore/patient_service.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/error_message.dart';
import '../../../widgets/inputs/app_text_field.dart';

/// Screen for basic civilian/patient profile registration.
///
/// Prompts the authenticated user for:
/// - Full Name (multilingual support)
/// - Age (years)
/// - Weight (kg)
/// - Height (cm)
///
/// The phone number is read-only and sourced directly from [FirebaseAuth].
class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});

  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String? _nameError;
  String? _ageError;
  String? _weightError;
  String? _heightError;
  String? _errorMessage;

  bool _isLoading = false;
  bool _isCheckingExisting = true;

  @override
  void initState() {
    super.initState();
    _checkExistingProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  /// Verifies if a patient profile already exists for this account.
  /// If it does, routes directly to avoid duplicate creation.
  Future<void> _checkExistingProfile() async {
    try {
      final patientService = context.read<PatientService>();
      final hasProfile = await patientService.hasPatientProfile();

      if (!mounted) return;

      if (hasProfile) {
        final existingPatients = await patientService.getLinkedPatients();
        if (!mounted) return;

        if (existingPatients.isNotEmpty) {
          context.go(
            RouteNames.patientRegistrationSuccess,
            extra: existingPatients.first,
          );
          return;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientRegistrationScreen] Error checking profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingExisting = false);
      }
    }
  }

  String? _resolveValidationError(AppLocalizations l10n, String? key) {
    if (key == null) return null;
    switch (key) {
      case 'validation_name':
        return l10n.validationName;
      case 'validation_age':
        return l10n.validationAge;
      case 'validation_weight':
        return l10n.validationWeight;
      case 'validation_height':
        return l10n.validationHeight;
      case 'validation_required':
        return l10n.validationRequired;
      default:
        return l10n.errorGeneric;
    }
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;

    final l10n = AppLocalizations.of(context)!;

    final nameVal = Validators.name(_nameController.text);
    final ageVal = Validators.age(_ageController.text);
    final weightVal = Validators.weight(_weightController.text);
    final heightVal = Validators.height(_heightController.text);

    setState(() {
      _nameError = _resolveValidationError(l10n, nameVal);
      _ageError = _resolveValidationError(l10n, ageVal);
      _weightError = _resolveValidationError(l10n, weightVal);
      _heightError = _resolveValidationError(l10n, heightVal);
      _errorMessage = null;
    });

    if (nameVal != null ||
        ageVal != null ||
        weightVal != null ||
        heightVal != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final patientService = context.read<PatientService>();
      final trimmedName = _nameController.text.trim();
      final parsedAge = int.parse(_ageController.text.trim());
      final parsedWeight = double.parse(_weightController.text.trim());
      final parsedHeight = double.parse(_heightController.text.trim());

      final createdPatient = await patientService.createPatient(
        name: trimmedName,
        age: parsedAge,
        weightKg: parsedWeight,
        heightCm: parsedHeight,
        relationship: 'self',
      );

      if (!mounted) return;

      context.go(RouteNames.patientRegistrationSuccess, extra: createdPatient);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PatientRegistrationScreen] Registration failed: $e');
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final phone = currentUser?.phoneNumber ?? '';

    if (_isCheckingExisting) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  l10n.createPatientProfileTitle,
                  style: Theme.of(context).textTheme.displayMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  l10n.createPatientProfileSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.textSecondary),
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Verified Phone Banner (Read-only) ────────────────────
                if (phone.isNotEmpty)
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
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.verifiedPhone,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            Text(
                              phone,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppTheme.spacingLg),

                // ── Full Name Field ──────────────────────────────────────
                AppTextField(
                  controller: _nameController,
                  label: l10n.fullName,
                  hint: l10n.fullNameHint,
                  errorText: _nameError,
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Age Field ────────────────────────────────────────────
                AppTextField(
                  controller: _ageController,
                  label: l10n.age,
                  hint: l10n.ageHint,
                  errorText: _ageError,
                  prefixIcon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  suffixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Align(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.years,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_ageError != null) setState(() => _ageError = null);
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Weight Field ─────────────────────────────────────────
                AppTextField(
                  controller: _weightController,
                  label: l10n.weight,
                  hint: l10n.weightHint,
                  errorText: _weightError,
                  prefixIcon: Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  suffixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Align(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.kg,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_weightError != null) {
                      setState(() => _weightError = null);
                    }
                  },
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // ── Height Field ─────────────────────────────────────────
                AppTextField(
                  controller: _heightController,
                  label: l10n.height,
                  hint: l10n.heightHint,
                  errorText: _heightError,
                  prefixIcon: Icons.height_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  suffixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Align(
                      widthFactor: 1.0,
                      heightFactor: 1.0,
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.cm,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  onChanged: (_) {
                    if (_heightError != null) {
                      setState(() => _heightError = null);
                    }
                  },
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
                  label: l10n.createProfileButton,
                  onPressed: _isLoading ? null : _onSubmit,
                  isLoading: _isLoading,
                  icon: Icons.person_add_rounded,
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
