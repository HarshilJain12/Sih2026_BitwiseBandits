import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/asha_worker.dart';
import '../../../providers/asha_state_provider.dart';
import '../../../services/speech/real_speech_input_service.dart';
import '../../../services/speech/speech_input_service.dart';
import '../../../widgets/buttons/primary_button.dart';

class AshaReportIssueScreen extends StatefulWidget {
  const AshaReportIssueScreen({super.key});

  @override
  State<AshaReportIssueScreen> createState() => _AshaReportIssueScreenState();
}

class _AshaReportIssueScreenState extends State<AshaReportIssueScreen> {
  final _descriptionController = TextEditingController();
  final SpeechInputService _speechService = RealSpeechInputService();

  String _selectedIssueType = 'Water Contamination';
  String _selectedSeverity = 'Medium';
  bool _isListening = false;
  bool _isLoading = false;

  final List<String> _issueTypes = [
    'Dengue Concern',
    'Malaria Concern',
    'Fever Outbreak',
    'Diarrhea Cases',
    'Water Contamination',
    'Sanitation Problem',
    'Mosquito Breeding',
    'Vaccination Shortage',
    'Other'
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    setState(() => _isListening = true);

    try {
      final text = await _speechService.listenForSpeech(lang: 'en-IN');

      if (text != null && text.trim().isNotEmpty && mounted) {
        setState(() {
          _descriptionController.text = text;

          // NLP categorization based on real captured transcript
          final lower = text.toLowerCase();
          if (lower.contains('fever') || lower.contains('ताप')) {
            _selectedIssueType = 'Fever Outbreak';
          } else if (lower.contains('dengue') || lower.contains('mosquito') || lower.contains('डास')) {
            _selectedIssueType = 'Dengue Concern';
          } else if (lower.contains('malaria')) {
            _selectedIssueType = 'Malaria Concern';
          } else if (lower.contains('water') || lower.contains('पानी') || lower.contains('stomach') || lower.contains('उलट्या')) {
            _selectedIssueType = 'Water Contamination';
          } else if (lower.contains('rash') || lower.contains('skin') || lower.contains('खाज')) {
            _selectedIssueType = 'Other';
          } else if (lower.contains('vaccine') || lower.contains('लस')) {
            _selectedIssueType = 'Vaccination Shortage';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('permission')
                  ? 'Microphone permission needed. Please allow microphone access in your browser.'
                  : 'Speech recognition: $e',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker ?? AshaWorker.demoWorker;
    if (ashaProvider.currentWorker == null) {
      ashaProvider.setWorker(worker);
    }

    try {
      await ashaProvider.dataService.submitAlert(
        ashaId: worker.ashaId,
        ashaName: worker.name,
        issueType: _selectedIssueType,
        description: _descriptionController.text.trim(),
        village: worker.village,
        ward: worker.wardId,
        severity: _selectedSeverity.toLowerCase(),
        voiceTranscript: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Report Submitted',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'The community health alert has been sent to the Hospital Admin.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Report Village Issue',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg, vertical: AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Report outbreaks, sanitation issues, or health hazards directly to the Hospital Admin.',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Voice Input Button
              Center(
                child: Column(
                  children: [
                    InkWell(
                      onTap: _startListening,
                      borderRadius: BorderRadius.circular(50),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: _isListening ? 90 : 80,
                        height: _isListening ? 90 : 80,
                        decoration: BoxDecoration(
                          color: _isListening ? AppColors.error : AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening ? AppColors.error : AppColors.primary).withValues(alpha: 0.35),
                              blurRadius: _isListening ? 24 : 12,
                              spreadRadius: _isListening ? 6 : 2,
                            )
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isListening ? 'Listening to your voice... Speak now' : 'Tap to Speak',
                      style: TextStyle(
                        color: _isListening ? AppColors.error : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              // Description Text Area
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Issue Description',
                  labelStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  floatingLabelStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  hintText: 'Describe the issue or speak using the mic button...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Category Dropdown
              const Text(
                'Issue Category',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppColors.border, width: 1.2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedIssueType,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    items: _issueTypes
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedIssueType = v!),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLg),

              // Severity
              const Text(
                'Severity',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Low', 'Medium', 'High'].map((sev) {
                  final isSelected = _selectedSeverity == sev;
                  final Color selectedBg = sev == 'High'
                      ? AppColors.error
                      : (sev == 'Medium' ? const Color(0xFF0D7377) : AppColors.primaryLight);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedSeverity = sev),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? selectedBg : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: isSelected ? selectedBg : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check, color: Colors.white, size: 16),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                sev,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: AppTheme.spacingXl),

              PrimaryButton(
                label: 'Submit Report',
                onPressed: _submitReport,
                isLoading: _isLoading,
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],
          ),
        ),
      ),
    );
  }
}
