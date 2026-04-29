import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// Provides stable device identification and human-readable device model.
///
/// device_id:
///   UUID v4, generated once on first use and stored in SharedPreferences.
///   This is a per-app-install identifier (not hardware IMEI/serial).
///   It persists across sessions and resets only on app uninstall.
///   Used in backup metadata to identify which device created the backup.
///
/// device_model:
///   Human-readable model string from the OS.
///   Android: "{manufacturer} {model}", e.g., "Google Pixel 7a"
///   iOS: hardware machine string, e.g., "iPhone14,2"
///   Falls back to "unknown" on error or unsupported platform.
///
/// Multi-device conflict resolution policy: last-write-wins.
/// The device_id + device_model fields are informational only
/// and do NOT participate in merge logic.
class DeviceInfoService {
  static const _keyDeviceId = 'device_unique_id';

  final DeviceInfoPlugin _plugin;

  DeviceInfoService({DeviceInfoPlugin? plugin})
      : _plugin = plugin ?? DeviceInfoPlugin();

  /// Get or generate a stable per-install device ID.
  /// Stored in SharedPreferences; generated once on first call.
  Future<String> getDeviceId(SharedPreferences prefs) async {
    var id = prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = _generateUuidV4();
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  /// Get a human-readable device model string.
  /// Returns 'unknown' if platform is unsupported or an error occurs.
  Future<String> getDeviceModel() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _plugin.androidInfo;
        return '${info.manufacturer} ${info.model}'.trim();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _plugin.iosInfo;
        return info.utsname.machine; // e.g., "iPhone14,2"
      }
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  /// Generate a RFC 4122 UUID v4 using Dart's cryptographically secure RNG.
  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    // Set version 4 bits
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant bits
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
