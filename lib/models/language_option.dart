import 'package:flutter/material.dart';

/// Represents a selectable language option on the Language Selection screen.
///
/// Adding a new language requires only:
/// 1. Adding a new [LanguageOption] to the list in [AppConstants] / provider.
/// 2. Creating the corresponding .arb file.
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.nativeName,
    required this.locale,
    required this.letterSymbol,
  });

  /// BCP-47 language code, e.g. 'en', 'hi', 'mr'
  final String code;

  /// Name of the language written in its own script, e.g. 'हिन्दी'
  final String nativeName;

  /// Flutter Locale for this language
  final Locale locale;

  /// A single representative character displayed large on the card, e.g. 'A', 'अ'
  final String letterSymbol;

  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: 'en',
      nativeName: 'English',
      locale: Locale('en'),
      letterSymbol: 'A',
    ),
    LanguageOption(
      code: 'hi',
      nativeName: 'हिन्दी',
      locale: Locale('hi'),
      letterSymbol: 'अ',
    ),
    LanguageOption(
      code: 'mr',
      nativeName: 'मराठी',
      locale: Locale('mr'),
      letterSymbol: 'अ',
    ),
  ];
}
