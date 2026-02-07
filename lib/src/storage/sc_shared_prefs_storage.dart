import 'package:shared_preferences/shared_preferences.dart';

class SCSharedPrefStorage {
  late SharedPreferences _sharedPreferences;
  bool _initialized = false;

  static final SCSharedPrefStorage _instance = SCSharedPrefStorage._internal();
  factory SCSharedPrefStorage() => _instance;

  SCSharedPrefStorage._internal();

  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
    _initialized = true;
  }

  static Future<void> saveData(String key, dynamic value) async {
    if (value is int) {
      await _instance._sharedPreferences.setInt(key, value);
    } else if (value is String) {
      await _instance._sharedPreferences.setString(key, value);
    } else if (value is bool) {
      await _instance._sharedPreferences.setBool(key, value);
    } else if (value is double) {
      await _instance._sharedPreferences.setDouble(key, value);
    } else if (value is List<String>) {
      await _instance._sharedPreferences.setStringList(key, value);
    }
  }

  static String? readString(String key) {
    return _instance._sharedPreferences.getString(key);
  }

  static int? readInt(String key) {
    return _instance._sharedPreferences.getInt(key);
  }

  static bool? readBool(String key) {
    return _instance._sharedPreferences.getBool(key);
  }

  static double? readDouble(String key) {
    return _instance._sharedPreferences.getDouble(key);
  }

  static List<String>? readStringList(String key) {
    return _instance._sharedPreferences.getStringList(key);
  }

  static Future<bool> deleteData(String key) async {
    return await _instance._sharedPreferences.remove(key);
  }

  static bool isInitialized() {
    return _instance._initialized;
  }

  static Future<void> clearAll() async {
    await _instance._sharedPreferences.clear();
  }

  SharedPreferences get sharedPreferences {
    return _sharedPreferences;
  }
}
