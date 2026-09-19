import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/hospital_result.dart';
import '../../../providers/app_state_provider.dart';
import '../../../services/ai/gemini_hospital_intent_service.dart';
import '../../../services/hospital/google_places_hospital_search_service.dart';
import '../../../services/hospital/hospital_search_service.dart';
import '../../../services/location/location_service.dart';
import '../../../services/speech/device_voice_input_service.dart';
import '../../../services/speech/speech_input_service.dart';
import 'hospital_result_card.dart';

/// Callback signature for opening the hospital map with live GPS coordinates.
typedef OnOpenHospitalMap = void Function(
  HospitalResult selected,
  List<HospitalResult> allResults,
  double? userLat,
  double? userLng,
);

/// Primary "Find the Hospital" interactive section.
///
/// Strictly uses LIVE CURRENT GPS coordinates for every search. Never uses registration location.
class FindHospitalSection extends StatefulWidget {
  const FindHospitalSection({
    super.key,
    required this.onOpenMap,
    required this.onGetDirections,
    this.searchService,
    this.speechService,
    this.locationService,
  });

  final OnOpenHospitalMap onOpenMap;
  final Function(HospitalResult hospital) onGetDirections;
  final HospitalSearchService? searchService;
  final SpeechInputService? speechService;
  final LocationService? locationService;

  @override
  State<FindHospitalSection> createState() => _FindHospitalSectionState();
}

class _FindHospitalSectionState extends State<FindHospitalSection> {
  final TextEditingController _queryController = TextEditingController();
  late final HospitalSearchService _searchService;
  late final SpeechInputService _speechService;
  late final LocationService _locationService;

  List<HospitalResult> _results = [];
  bool _isSearching = false;
  bool _isListening = false;
  String? _selectedCategory;
  String? _statusMessage;
  String? _errorMessage;
  String? _errorActionLabel;
  VoidCallback? _errorActionCallback;

  double? _currentGpsLat;
  double? _currentGpsLng;

  final List<Map<String, String>> _categories = [
    {'label': 'General & Emergency', 'category': HealthcareCategory.hospital},
    {'label': 'Dental Care', 'category': HealthcareCategory.dentist},
    {'label': 'Eye Care', 'category': HealthcareCategory.eyeCare},
    {'label': 'Pediatrics', 'category': HealthcareCategory.pediatrician},
    {'label': 'Skin Care', 'category': HealthcareCategory.dermatologist},
    {'label': 'Orthopedics', 'category': HealthcareCategory.orthopedics},
    {'label': 'Pharmacy', 'category': HealthcareCategory.pharmacy},
  ];

  @override
  void initState() {
    super.initState();
    _searchService = widget.searchService ?? GooglePlacesHospitalSearchService();
    _speechService = widget.speechService ?? DeviceVoiceInputService();
    _locationService = widget.locationService ?? const LocationService();

    // Initial nearby hospital search using fresh live GPS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch('', explicitCategory: HealthcareCategory.hospital);
    });
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechService.cancelListening();
    }
    _queryController.dispose();
    super.dispose();
  }

  /// Obtains fresh live GPS coordinates and executes Google Places search.
  Future<void> _performSearch(String query, {String? explicitCategory}) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
      _results = []; // Never show old/mock results during new search
      _errorMessage = null;
      _errorActionLabel = null;
      _errorActionCallback = null;
      _statusMessage = 'Checking location services...';
    });

    try {
      // 1. Check whether device location services (GPS) are enabled
      final isServiceEnabled = await _locationService.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage = 'Please enable location services to find hospitals near you.';
            _errorActionLabel = 'Open Location Settings';
            _errorActionCallback = () async {
              await _locationService.openLocationSettings();
              _performSearch(query, explicitCategory: explicitCategory);
            };
          });
        }
        return;
      }

      // 2. Check and request location permission
      var permission = await _locationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage = 'Location permission is required to find hospitals near you.';
            _errorActionLabel = 'Open App Settings';
            _errorActionCallback = () async {
              await _locationService.openAppSettings();
            };
          });
        }
        return;
      }

      // 3. Acquire fresh current device GPS position
      if (mounted) {
        setState(() {
          _statusMessage = 'Getting your current location...';
        });
      }

      final fetchResult = await _locationService.getCurrentLocation();
      if (!fetchResult.isSuccess || fetchResult.position == null) {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _errorMessage = "We couldn't determine your current location. Please try again.";
            _errorActionLabel = 'Retry';
            _errorActionCallback = () => _performSearch(query, explicitCategory: explicitCategory);
          });
        }
        return;
      }

      final liveLat = fetchResult.position!.latitude;
      final liveLng = fetchResult.position!.longitude;
      _currentGpsLat = liveLat;
      _currentGpsLng = liveLng;

      // 4. Query Google Places with live GPS coordinates
      final targetSearchTerm = explicitCategory ?? query.trim();
      if (mounted) {
        setState(() {
          _statusMessage = targetSearchTerm.isNotEmpty
              ? 'Finding nearby healthcare facilities...'
              : 'Finding nearby hospitals...';
        });
      }

      final results = await _searchService.searchHospitals(
        query: targetSearchTerm,
        latitude: liveLat,
        longitude: liveLng,
      );

      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          _statusMessage = null;
          if (results.isEmpty) {
            _errorMessage = 'No nearby healthcare facilities found.\nTry another category or expand your search.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _statusMessage = null;
          _errorMessage = "We couldn't load nearby healthcare facilities. Please check your internet connection and try again.";
          _errorActionLabel = 'Retry';
          _errorActionCallback = () => _performSearch(query, explicitCategory: explicitCategory);
        });
      }
    }
  }

  Future<void> _handleVoiceInput() async {
    if (_isListening) {
      await _speechService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    final l10n = AppLocalizations.of(context);
    final appLocale = context.read<AppStateProvider?>()?.locale ??
        Localizations.localeOf(context);
    final targetLocaleId =
        _speechService.resolveLocaleId(appLocale.languageCode);

    setState(() => _isListening = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n?.listeningVoiceInput ?? 'Listening... Speak now'),
          ],
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.primary,
      ),
    );

    final started = await _speechService.startListening(
      localeId: targetLocaleId,
      onResult: (recognizedWords, isFinal) {
        if (!mounted) return;
        setState(() {
          _queryController.text = recognizedWords;
          _queryController.selection = TextSelection.fromPosition(
            TextPosition(offset: recognizedWords.length),
          );
          if (isFinal) {
            _isListening = false;
            // Execute search on finalized speech input
            _performSearch(recognizedWords);
          }
        });
      },
      onError: (errorMessage) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice input unavailable or permission denied. You can still type your search.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );

    if (!started && mounted) {
      setState(() => _isListening = false);
    }
  }

  void _onCategorySelected(String categoryKey, String label) {
    if (_selectedCategory == label) {
      setState(() => _selectedCategory = null);
      _queryController.clear();
      _performSearch('', explicitCategory: HealthcareCategory.hospital);
    } else {
      setState(() => _selectedCategory = label);
      _queryController.text = label;
      _performSearch('', explicitCategory: categoryKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section Title ──────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.findHospitalTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    'Real healthcare facilities near your current location',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingMd),

        // ── Input Field + Voice Button ─────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: AppTheme.spacingMd),
              const Icon(Icons.search_rounded, color: AppColors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: TextField(
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (val) => _performSearch(val),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.describeHealthProblemHint,
                    hintStyle: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_queryController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _queryController.clear();
                    setState(() => _selectedCategory = null);
                    _performSearch('', explicitCategory: HealthcareCategory.hospital);
                  },
                ),
              // Prominent Microphone Button for low-literacy users
              GestureDetector(
                onTap: _handleVoiceInput,
                child: Container(
                  margin: const EdgeInsets.all(6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? AppColors.secondary
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),

        // ── Quick Category Chips ───────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final label = cat['label']!;
              final isSelected = _selectedCategory == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                  onSelected: (_) =>
                      _onCategorySelected(cat['category']!, label),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),

        // ── Progressive Loading State ─────────────────────────────────
        if (_isSearching) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXl),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  _statusMessage ?? 'Searching nearby healthcare...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else if (_errorMessage != null) ...[
          // ── Explicit Error / Empty State (No Fake Data Fallback) ──────
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  _errorMessage!.contains('permission') || _errorMessage!.contains('Location')
                      ? Icons.location_off_rounded
                      : Icons.info_outline_rounded,
                  color: AppColors.secondary,
                  size: 36,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (_errorActionLabel != null && _errorActionCallback != null) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  ElevatedButton(
                    onPressed: _errorActionCallback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: Text(_errorActionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ] else if (_results.isNotEmpty) ...[
          // ── Real Google Places Results List ──────────────────────────
          ..._results.map(
            (hospital) => HospitalResultCard(
              hospital: hospital,
              onViewMap: () => widget.onOpenMap(
                hospital,
                _results,
                _currentGpsLat,
                _currentGpsLng,
              ),
              onGetDirections: () => widget.onGetDirections(hospital),
            ),
          ),
        ],
      ],
    );
  }
}
