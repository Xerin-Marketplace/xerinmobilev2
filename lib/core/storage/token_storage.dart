import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _guestModeKey = 'guest_mode';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  String? _accessToken;
  String? _refreshToken;

  TokenStorage(this._prefs, this._secureStorage);

  Future<void> initialize() async {
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    // One-time migration path from legacy shared preferences token storage.
    if (_accessToken == null) {
      final legacyAccessToken = _prefs.getString(_accessTokenKey);
      if (legacyAccessToken != null) {
        _accessToken = legacyAccessToken;
        await _secureStorage.write(
          key: _accessTokenKey,
          value: legacyAccessToken,
        );
        await _prefs.remove(_accessTokenKey);
      }
    }

    if (_refreshToken == null) {
      final legacyRefreshToken = _prefs.getString(_refreshTokenKey);
      if (legacyRefreshToken != null) {
        _refreshToken = legacyRefreshToken;
        await _secureStorage.write(
          key: _refreshTokenKey,
          value: legacyRefreshToken,
        );
        await _prefs.remove(_refreshTokenKey);
      }
    }
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get hasTokens => accessToken != null;
  bool get isGuestMode => _prefs.getBool(_guestModeKey) ?? false;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
    await _prefs.setBool(_guestModeKey, false);
  }

  Future<void> setGuestMode(bool value) async {
    await _prefs.setBool(_guestModeKey, value);
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);

    // Clean up any legacy token values if they still exist.
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_guestModeKey);
  }
}
