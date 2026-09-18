import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/patient.dart';
import '../../../services/ai/health_message_generator.dart';
import '../../../services/ai/local_health_message_generator.dart';

/// Friendly AI Nurse Companion section with visual nurse avatar and speech bubble.
class NurseCompanionWidget extends StatefulWidget {
  const NurseCompanionWidget({
    super.key,
    required this.patient,
    this.messageGenerator,
  });

  final Patient patient;
  final HealthMessageGenerator? messageGenerator;

  @override
  State<NurseCompanionWidget> createState() => _NurseCompanionWidgetState();
}

class _NurseCompanionWidgetState extends State<NurseCompanionWidget> {
  late final HealthMessageGenerator _generator;
  String? _nurseMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generator = widget.messageGenerator ?? LocalHealthMessageGenerator();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNurseMessage();
  }

  Future<void> _loadNurseMessage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final localeCode = Localizations.localeOf(context).languageCode;
    try {
      final msg = await _generator.generateMessage(
        patient: widget.patient,
        localeCode: localeCode,
      );
      if (mounted) {
        setState(() {
          _nurseMessage = msg;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nurseMessage =
              'Welcome! I am here to help you stay healthy and find care. 💚';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F6F6), Color(0xFFD0F0EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Nurse Visual Avatar ───────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.face_3_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.spacingMd),

              // ── Speech Bubble Content ─────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(AppTheme.radiusLg),
                          bottomLeft: Radius.circular(AppTheme.radiusLg),
                          bottomRight: Radius.circular(AppTheme.radiusLg),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Sister Anjali (AI Nurse)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: _loadNurseMessage,
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingXs),
                          if (_isLoading) ...[
                            const SizedBox(
                              height: 24,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Thinking...',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Text(
                              _nurseMessage ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 15,
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
