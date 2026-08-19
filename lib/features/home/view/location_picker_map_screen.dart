import 'dart:async';
import 'package:cabme/common/widget/button.dart';
import 'package:cabme/common/widget/custom_text.dart';
import 'package:cabme/core/themes/constant_colors.dart';
import 'package:cabme/core/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class LocationPickerResult {
  final LatLng latLng;
  final String address;
  LocationPickerResult({required this.latLng, required this.address});
}

class LocationPickerMapScreen extends StatefulWidget {
  final LatLng? initialPosition;
  const LocationPickerMapScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerMapScreen> createState() =>
      _LocationPickerMapScreenState();
}

class _LocationPickerMapScreenState extends State<LocationPickerMapScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(29.3759, 47.9774); // Kuwait City fallback
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _center = widget.initialPosition!;
      _isLoadingLocation = false;
      _reverseGeocode(_center);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _reverseGeocode(_center);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _reverseGeocode(_center);
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      _center = LatLng(position.latitude, position.longitude);
    } catch (_) {
      // fall back to default center
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        _mapController
            ?.animateCamera(CameraUpdate.newLatLngZoom(_center, 16));
        _reverseGeocode(_center);
      }
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality, p.country]
            .where((e) => e != null && e.isNotEmpty)
            .toList();
        _address = parts.isNotEmpty ? parts.join(', ') : 'Selected Location'.tr;
      }
    } catch (_) {
      _address = 'Selected Location'.tr;
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _center = position.target;
  }

  void _onCameraIdle() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _reverseGeocode(_center);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDarkMode = themeChange.getThem();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),
          // Fixed center pin (tip sits at exact map center)
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 55),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: AppThemeData.primary200,
                ),
              ),
            ),
          ),
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15), blurRadius: 6),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() => _isLoadingLocation = true);
                _getCurrentLocation();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15), blurRadius: 6),
                  ],
                ),
                child: Icon(Icons.my_location, color: AppThemeData.primary200),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: isDarkMode ? AppThemeData.surface50Dark : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: 'Selected Location'.tr,
                    size: 12,
                    color: AppThemeData.grey500,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: AppThemeData.primary200, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoadingAddress
                            ? Text('location Searching....'.tr)
                            : Text(
                                _address.isNotEmpty
                                    ? _address
                                    : 'Selected Location'.tr,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    btnName: 'confirm_location'.tr,
                    ontap: () {
                      if (_isLoadingAddress) return;
                      Get.back(
                        result: LocationPickerResult(
                          latLng: _center,
                          address:
                              _address.isNotEmpty ? _address : 'Selected Location'.tr,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}