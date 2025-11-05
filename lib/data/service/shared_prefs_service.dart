import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _keyLoginType = 'loginType';
  static const _keyUserId = 'userId';
  static const _keyGoogleId = "googleId";
  static const _keyPrefix ="lastFetch_";

  Future<void> removeLastFetch(String bankAddress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$bankAddress');
  }

  Future<void> setLoginType(String type, String id, String googleId) async {
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

  /// Set last fetch time for a bank
   Future<void> setLastFetch(String bankAddress, DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix$bankAddress', dateTime.millisecondsSinceEpoch);
  }

  /// Get the 'fromDate' to use when fetching transactions
   Future<DateTime> getFromDate(String bankAddress) async {
    final lastFetch = await getLastFetch(bankAddress);
    if (lastFetch != null) {
      // Existing bank: fetch from last fetch
      return lastFetch;
    } else {
      // New bank: fetch from start of today
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


  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
