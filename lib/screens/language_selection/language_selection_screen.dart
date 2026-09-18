import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/language_option.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/cards/language_card.dart';

/// Screen 1 — Language Selection.
///
/// First screen shown on launch (when no language is persisted).
/// Displays 3 large language cards. On selection, persists the locale
/// and navigates to role selection.
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedCode;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onLanguageSelected(LanguageOption language) async {
    if (_isNavigating) return;
    setState(() {
      _selectedCode = language.code;
      _isNavigating = true;
    });

    // Brief pause for the selection animation to be visible
    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;
    await context.read<AppStateProvider>().setLocale(language.locale);
    if (!mounted) return;
    context.go(RouteNames.roleSelection);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
                vertical: AppTheme.spacingMd,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      AppTheme.spacingMd * 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.04),

                    // ── Healthcare Icon ──────────────────────────────────
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.04),

                    // ── Heading ──────────────────────────────────────────
                    Text(
                      l10n.chooseLanguage,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),

                    const SizedBox(height: AppTheme.spacingSm),

                    // ── Multilingual subtitle ────────────────────────────
                    Text(
                      l10n.chooseLanguageSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(color: AppColors.textSecondary),
                    ),

                    SizedBox(height: size.height * 0.05),

                    // ── Language Cards ───────────────────────────────────
                    ...LanguageOption.supportedLanguages.map((lang) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppTheme.spacingMd,
                        ),
                        child: LanguageCard(
                          language: lang,
                          isSelected: _selectedCode == lang.code,
                          onTap: () => _onLanguageSelected(lang),
                        ),
                      );
                    }),

                    SizedBox(height: size.height * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
