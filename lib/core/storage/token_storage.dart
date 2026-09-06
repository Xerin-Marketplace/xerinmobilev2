import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/models/user_model.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isGuestKey = 'is_guest';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  String? _accessToken;
  String? _refreshToken;
  UserModel? _currentUser;
  bool _isGuest = false;

  TokenStorage(this._prefs, this._secureStorage);

  Future<void> initialize() async {
    _accessToken = await _secureStorage.read(key: _accessTokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    _isGuest = _prefs.getBool(_isGuestKey) ?? false;
    await _loadUserData();

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
  bool get isAuthenticated => accessToken != null;
  bool get isGuest => false;
  UserModel? get currentUser => _currentUser;

  Future<void> setGuest() async {
    _isGuest = true;
    await _prefs.setBool(_isGuestKey, true);
  }

  Future<void> clearGuest() async {
    _isGuest = false;
    await _prefs.remove(_isGuestKey);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    UserModel? user,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);

    if (user != null) {
      await saveUser(user);
    }
  }

  Future<void> saveUser(UserModel user) async {
    _currentUser = user;
    final json = jsonEncode(user.toJson());
    await _prefs.setString(_userDataKey, json);
  }

  Future<void> _loadUserData() async {
    final raw = _prefs.getString(_userDataKey);
    if (raw != null) {
      try {
        _currentUser = UserModel.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _isGuest = false;

    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);

    // Clean up any legacy token values if they still exist.
    await _prefs.remove(_accessTokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_userDataKey);
    await _prefs.remove(_isGuestKey);
  }
}
