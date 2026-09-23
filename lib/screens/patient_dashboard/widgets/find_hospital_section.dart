import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/hospital_result.dart';
import '../../../models/patient_location.dart';
import '../../../services/hospital/hospital_search_service.dart';
import '../../../services/hospital/mock_hospital_search_service.dart';
import '../../../services/speech/real_speech_input_service.dart';
import '../../../services/speech/speech_input_service.dart';
import 'hospital_result_card.dart';

/// Primary "Find the Hospital" interactive section.
class FindHospitalSection extends StatefulWidget {
  const FindHospitalSection({
    super.key,
    this.patientLocation,
    required this.onOpenMap,
    required this.onGetDirections,
    this.searchService,
    this.speechService,
  });

  final PatientLocation? patientLocation;
  final Function(HospitalResult selected, List<HospitalResult> allResults) onOpenMap;
  final Function(HospitalResult hospital) onGetDirections;
  final HospitalSearchService? searchService;
  final SpeechInputService? speechService;

  @override
  State<FindHospitalSection> createState() => _FindHospitalSectionState();
}

class _FindHospitalSectionState extends State<FindHospitalSection> {
  final TextEditingController _queryController = TextEditingController();
  late final HospitalSearchService _searchService;
  late final SpeechInputService _speechService;

  List<HospitalResult> _results = [];
  bool _isSearching = false;
  bool _isListening = false;
  String? _selectedCategory;

  final List<Map<String, String>> _categories = [
    {'label': 'General & Emergency', 'query': 'general emergency'},
    {'label': 'Dental Care', 'query': 'tooth dental'},
    {'label': 'Pediatrics', 'query': 'child baby'},
    {'label': 'Skin Care', 'query': 'skin rash'},
    {'label': 'Cardiology', 'query': 'heart chest'},
  ];

  @override
  void initState() {
    super.initState();
    _searchService = widget.searchService ?? MockHospitalSearchService();
    _speechService = widget.speechService ?? RealSpeechInputService();
    _performSearch('');
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _searchService.searchHospitals(
        query: query,
        location: widget.patientLocation,
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _handleVoiceInput() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isListening = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.listeningVoiceInput),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );

    final text = await _speechService.listenForSpeech();
    if (mounted) {
      setState(() => _isListening = false);
      if (text != null && text.isNotEmpty) {
        _queryController.text = text;
        _performSearch(text);
      }
    }
  }

  void _onCategorySelected(String query, String label) {
    if (_selectedCategory == label) {
      setState(() => _selectedCategory = null);
      _queryController.clear();
      _performSearch('');
    } else {
      setState(() => _selectedCategory = label);
      _queryController.text = label;
      _performSearch(query);
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
            Column(
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
                  l10n.findHospitalSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
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
                  onSubmitted: _performSearch,
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
                    _performSearch('');
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
                      _onCategorySelected(cat['query']!, label),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: AppTheme.spacingMd),

        // ── Search Results List ────────────────────────────────────────
        if (_isSearching) ...[
          const Padding(
            padding: EdgeInsets.all(AppTheme.spacingXl),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ] else if (_results.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                l10n.noHospitalsFound,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ] else ...[
          ..._results.map(
            (hospital) => HospitalResultCard(
              hospital: hospital,
              onViewMap: () => widget.onOpenMap(hospital, _results),
              onGetDirections: () => widget.onGetDirections(hospital),
            ),
          ),
        ],
      ],
    );
  }
}
