import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? country;
  final String? region;
  final String? city;
  final String? district;
  final String? ward;
  final String? street;
  final String? postalCode;
  final String? landmark;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.country,
    this.region,
    this.city,
    this.district,
    this.ward,
    this.street,
    this.postalCode,
    this.landmark,
  });
}

class LocationService {
  Future<bool> _handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable in settings.');
    }

    return true;
  }

  Future<LocationResult> getCurrentLocation() async {
    await _handlePermission();

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          country: p.country?.isNotEmpty == true ? p.country : null,
          region: p.administrativeArea?.isNotEmpty == true ? p.administrativeArea : null,
          city: p.locality?.isNotEmpty == true ? p.locality : null,
          district: p.subAdministrativeArea?.isNotEmpty == true ? p.subAdministrativeArea : null,
          ward: p.subLocality?.isNotEmpty == true ? p.subLocality : null,
          street: p.street?.isNotEmpty == true ? p.street : null,
          postalCode: p.postalCode?.isNotEmpty == true ? p.postalCode : null,
          landmark: p.name?.isNotEmpty == true ? p.name : null,
        );
      }
    } catch (_) {}

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
