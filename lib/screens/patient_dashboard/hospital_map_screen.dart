import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/hospital_result.dart';

/// Screen presenting Google Map with nearby hospital markers and patient location.
class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({
    super.key,
    required this.selectedHospital,
    required this.allHospitals,
    this.userLat,
    this.userLng,
  });

  final HospitalResult selectedHospital;
  final List<HospitalResult> allHospitals;
  final double? userLat;
  final double? userLng;

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  late HospitalResult _currentSelected;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedHospital;
    _buildMarkers();
  }

  void _buildMarkers() {
    _markers.clear();

    // User location marker
    if (widget.userLat != null && widget.userLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(widget.userLat!, widget.userLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Hospital markers
    for (final hospital in widget.allHospitals) {
      final isSelected = hospital.id == _currentSelected.id;
      _markers.add(
        Marker(
          markerId: MarkerId(hospital.id),
          position: LatLng(hospital.latitude, hospital.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: '${hospital.formattedDistance} • ${hospital.specialty}',
          ),
          onTap: () {
            setState(() {
              _currentSelected = hospital;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(hospital.latitude, hospital.longitude),
              ),
            );
          },
        ),
      );
    }
  }

  Future<void> _launchDirections(HospitalResult hospital) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${hospital.latitude},${hospital.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open map directions for ${hospital.name}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final initialTarget = LatLng(
      _currentSelected.latitude,
      _currentSelected.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.findHospitalTitle),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 14.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Bottom card overlay displaying active hospital details
          Positioned(
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            bottom: AppTheme.spacingLg,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: const Icon(
                            Icons.local_hospital_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentSelected.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                '${_currentSelected.formattedDistance} • ${_currentSelected.specialty}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      _currentSelected.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    ElevatedButton.icon(
                      onPressed: () => _launchDirections(_currentSelected),
                      icon: const Icon(Icons.directions_rounded),
                      label: Text(l10n.getDirections),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
