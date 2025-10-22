import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const _keyLoginType = 'loginType';
  static const _keyUserId = 'userId';
  static const _keyGoogleId = "googleId";


  Future<void> setLoginType(String type, String id, String googleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLoginType, type);
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyGoogleId, googleId);
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
