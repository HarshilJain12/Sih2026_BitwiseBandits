import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/family.dart';
import '../../../providers/asha_state_provider.dart';

class AshaHomeVisitScreen extends StatefulWidget {
  const AshaHomeVisitScreen({super.key});

  @override
  State<AshaHomeVisitScreen> createState() => _AshaHomeVisitScreenState();
}

class _AshaHomeVisitScreenState extends State<AshaHomeVisitScreen> {
  bool _isLoading = true;
  List<Family> _families = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  Future<void> _loadFamilies() async {
    setState(() => _isLoading = true);
    final ashaProvider = context.read<AshaStateProvider>();
    final worker = ashaProvider.currentWorker;
    
    if (worker != null) {
      try {
        final families = await ashaProvider.dataService.getFamiliesByVillage(worker.village);
        if (mounted) {
          setState(() {
            _families = families;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFamilies = _families.where((f) => 
      f.headOfFamilyName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      f.address.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Start Home Visit'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by family head name or address...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredFamilies.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.family_restroom_outlined, size: 48, color: AppColors.textHint),
                          const SizedBox(height: 16),
                          const Text('No families found.', style: TextStyle(color: AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push(RouteNames.ashaFamilyRegistration).then((_) => _loadFamilies()),
                            icon: const Icon(Icons.add),
                            label: const Text('Register New Family'),
                          )
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                      itemCount: filteredFamilies.length,
                      itemBuilder: (context, index) {
                        final family = filteredFamilies[index];
                        return FamilyVisitCard(
                          family: family,
                          onVisit: () {
                            context.push(RouteNames.ashaHealthSurvey, extra: family);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card showing one family with a compact Visit action.
///
/// Layout is intentionally explicit (avatar + expanded text column + fixed
/// button) so the title can never collapse to zero width on web.
class FamilyVisitCard extends StatelessWidget {
  const FamilyVisitCard({
    super.key,
    required this.family,
    required this.onVisit,
  });

  final Family family;
  final VoidCallback onVisit;

  @override
  Widget build(BuildContext context) {
    final initial = family.headOfFamilyName.isNotEmpty
        ? family.headOfFamilyName[0].toUpperCase()
        : '?';
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                initial,
                style: const TextStyle(
                    color: AppColors.primaryDark, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    family.headOfFamilyName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.home_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          family.address,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (family.contactNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            family.contactNumber,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onVisit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roleAsha,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusFull),
                ),
              ),
              child: const Text('Visit'),
            ),
          ],
        ),
      ),
    );
  }
}
