import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  static const String _webDeviceIdKey = 'agri_pinoy_device_id';

  // Just fallback if ma detect na dili Android device
  static Future<String> getDeviceId() async {
    if (!kIsWeb && Platform.isAndroid) {
      return await _getAndroidId();
    }
    return await _getOrCreateWebId();
  }

  static Future<String> _getAndroidId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } catch (e) {
      print(
        'DeviceIdService: Failed to get Android ID, falling back to UUID — $e',
      );
      return await _getOrCreateWebId();
    }
  }

  // Generates a UUID on first run and persists it so the same ID is returned on every subsequent launch.
  static Future<String> _getOrCreateWebId() async {
    final prefs = await SharedPreferences.getInstance();
    String? existingId = prefs.getString(_webDeviceIdKey);
    if (existingId != null) return existingId;

    final newId = const Uuid().v4();
    await prefs.setString(_webDeviceIdKey, newId);
    return newId;
  }
}
