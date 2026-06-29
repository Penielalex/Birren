import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _keyLoginType = 'loginType';
  static const _keyUserId = 'userId';
  static const _keyGoogleId = 'googleId';
  static const _keyPrefix = 'lastFetch_';
  static const _keyPinHash = 'pinHash';
  static const _keyPinEnabled = 'pinEnabled';

  Future<void> removeLastFetch(String bankAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$bankAddress');
  }

  Future<void> setLoginType(String type, String id, [String googleId = '']) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoginType, type);
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyGoogleId, googleId);
  }

  Future<DateTime?> getLastFetch(String bankAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt('$_keyPrefix$bankAddress');
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  Future<void> setLastFetch(String bankAddress, DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_keyPrefix$bankAddress',
      dateTime.millisecondsSinceEpoch,
    );
  }

  Future<DateTime> getFromDate(String bankAddress) async {
    final lastFetch = await getLastFetch(bankAddress);
    if (lastFetch != null) {
      return lastFetch;
    } else {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
  }

  Future<String?> getLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoginType);
  }

  Future<String?> getId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<String?> getGoogleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGoogleId);
  }

  Future<bool> isPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPinEnabled) ?? false;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPinHash, _hashPin(pin));
    await prefs.setBool(_keyPinEnabled, true);
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinHash);
    await prefs.setBool(_keyPinEnabled, false);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPinHash);
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  Future<Map<String, int>> exportSyncCheckpoints() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, int>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_keyPrefix)) {
        final value = prefs.getInt(key);
        if (value != null) {
          result[key] = value;
        }
      }
    }
    return result;
  }

  Future<void> importSyncCheckpoints(Map<String, dynamic>? checkpoints) async {
    if (checkpoints == null) return;
    final prefs = await SharedPreferences.getInstance();
    for (final entry in checkpoints.entries) {
      if (entry.value is int) {
        await prefs.setInt(entry.key, entry.value as int);
      }
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = prefs.getString(_keyPinHash);
    final pinEnabled = prefs.getBool(_keyPinEnabled);
    final checkpoints = await exportSyncCheckpoints();

    await prefs.clear();

    if (pinHash != null) {
      await prefs.setString(_keyPinHash, pinHash);
    }
    if (pinEnabled != null) {
      await prefs.setBool(_keyPinEnabled, pinEnabled);
    }
    await importSyncCheckpoints(
      checkpoints.map((key, value) => MapEntry(key, value)),
    );
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode('birren_pin_$pin');
    return sha256.convert(bytes).toString();
  }
}
