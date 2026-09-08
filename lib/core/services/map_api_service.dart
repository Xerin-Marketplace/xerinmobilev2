import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../config/constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../network/api_client.dart';

class MapPrediction {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  const MapPrediction({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });
}

class MapResolvedLocation {
  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final String? placeId;
  final String? country;
  final String? region;
  final String? district;
  final String? ward;
  final String? city;
  final String? street;
  final String? postalCode;
  final String? provider;

  const MapResolvedLocation({
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.placeId,
    this.country,
    this.region,
    this.district,
    this.ward,
    this.city,
    this.street,
    this.postalCode,
    this.provider,
  });
}

class MapApiService {
  final ApiClient _client;
  String? _sessionToken;

  MapApiService(this._client);

  String _ensureSessionToken() {
    _sessionToken ??= const Uuid().v4();
    return _sessionToken!;
  }

  void resetSession() => _sessionToken = null;

  Future<bool> isMapEnabled() async {
    try {
      final res = await _client.get(ApiConstants.mapConfig);
      return res.data['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<MapPrediction>> autocomplete({
    required String query,
    String? countryCode,
    String? language,
  }) async {
    try {
      final res = await _client.get(
        ApiConstants.mapAutocomplete,
        queryParameters: {
          'query': query,
          'session_token': _ensureSessionToken(),
          if (countryCode != null) 'country_code': countryCode,
          if (language != null) 'language': language,
        },
      );
      final results = res.data['results'] as List? ?? [];
      return results
          .map((e) => MapPrediction(
                placeId: e['place_id']?.toString() ?? '',
                description: e['description']?.toString() ?? '',
                mainText: e['main_text']?.toString(),
                secondaryText: e['secondary_text']?.toString(),
              ))
          .where((p) => p.placeId.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<MapResolvedLocation> getPlaceDetails({
    required String placeId,
    String? language,
  }) async {
    try {
      final res = await _client.get(
        ApiConstants.mapPlaceDetails(placeId),
        queryParameters: {
          'session_token': _sessionToken,
          if (language != null) 'language': language,
        },
      );
      resetSession();
      return _parseResolved(res.data);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  Future<MapResolvedLocation> reverseGeocode({
    required double latitude,
    required double longitude,
    String? language,
  }) async {
    try {
      final res = await _client.get(
        ApiConstants.mapReverseGeocode,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          if (language != null) 'language': language,
        },
      );
      return _parseResolved(res.data);
    } on DioException catch (e) {
      throw ServerException(_client.getErrorMessage(e));
    }
  }

  MapResolvedLocation _parseResolved(dynamic data) {
    final m = data as Map<String, dynamic>;
    return MapResolvedLocation(
      latitude: (m['latitude'] is num)
          ? (m['latitude'] as num).toDouble()
          : double.tryParse(m['latitude']?.toString() ?? '') ?? 0,
      longitude: (m['longitude'] is num)
          ? (m['longitude'] as num).toDouble()
          : double.tryParse(m['longitude']?.toString() ?? '') ?? 0,
      formattedAddress: m['formatted_address']?.toString(),
      placeId: m['place_id']?.toString(),
      country: m['country']?.toString(),
      region: m['region']?.toString(),
      district: m['district']?.toString(),
      ward: m['ward']?.toString(),
      city: m['city']?.toString(),
      street: m['street']?.toString(),
      postalCode: m['postal_code']?.toString(),
      provider: m['provider']?.toString(),
    );
  }
}
