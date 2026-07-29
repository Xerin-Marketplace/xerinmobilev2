import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const String _pinKey = 'app_pin_hash';
  static const String _pinEnabledKey = 'pin_lock_enabled';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  String? _cachedPinHash;

  SecurityService(this._prefs, this._secureStorage);

  Future<void> initialize() async {
    _cachedPinHash = await _secureStorage.read(key: _pinKey);
  }

  bool get isPinLockEnabled => _prefs.getBool(_pinEnabledKey) ?? false;

  bool get hasPinSet => _cachedPinHash != null;

  Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    _cachedPinHash = hash;
    await _secureStorage.write(key: _pinKey, value: hash);
    await _prefs.setBool(_pinEnabledKey, true);
  }

  Future<void> disablePin() async {
    _cachedPinHash = null;
    await _secureStorage.delete(key: _pinKey);
    await _prefs.setBool(_pinEnabledKey, false);
  }

  bool verifyPin(String pin) {
    if (_cachedPinHash == null) return false;
    return _hashPin(pin) == _cachedPinHash;
  }

  String _hashPin(String pin) {
    int hash = 5381;
    for (int i = 0; i < pin.length; i++) {
      hash = ((hash << 5) + hash) + pin.codeUnitAt(i);
    }
    return hash.toRadixString(16);
  }
}
