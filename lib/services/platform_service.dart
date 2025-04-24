import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:platform_device_id/platform_device_id.dart';

class PlatformService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, String>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return {
        'platform': 'Android',
        'model': androidInfo.model,
        'version': androidInfo.version.release,
        'manufacturer': androidInfo.manufacturer,
        'device': androidInfo.device,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return {
        'platform': 'iOS',
        'model': iosInfo.model,
        'version': iosInfo.systemVersion,
        'device': iosInfo.name,
        'manufacturer': 'Apple',
      };
    }
    return {'platform': 'Unknown'};
  }

  static Future<String?> getDeviceId() async {
    return await PlatformDeviceId.getDeviceId;
  }

  static Future<bool> checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      return _checkAndroidPermissions();
    } else if (Platform.isIOS) {
      return _checkIosPermissions();
    }
    return true;
  }

  static Future<bool> _checkAndroidPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.notification,
      Permission.internet,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  static Future<bool> _checkIosPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.notification,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  static Future<Map<String, String>> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }

  static Future<void> checkDeviceCompatibility() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt < 21) {
        throw Exception('Cette application nécessite Android 5.0 ou supérieur');
      }
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      // Vérifie si l'iOS version est inférieure à iOS 12
      final version = double.tryParse(iosInfo.systemVersion.split('.').first) ?? 0;
      if (version < 12) {
        throw Exception('Cette application nécessite iOS 12.0 ou supérieur');
      }
    }
  }
}
