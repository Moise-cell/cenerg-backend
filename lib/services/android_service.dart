import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AndroidService {
  static Future<bool> checkAndRequestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.notification,
      Permission.internet,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;

    return {
      'model': deviceInfo.model,
      'brand': deviceInfo.brand,
      'androidVersion': deviceInfo.version.release,
      'sdkVersion': deviceInfo.version.sdkInt.toString(),
      'manufacturer': deviceInfo.manufacturer,
      'device': deviceInfo.device,
    };
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

  static Future<void> openAppSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:com.cenerg.app',
    );
    await intent.launch();
  }

  static Future<void> openLocationSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.LOCATION_SOURCE_SETTINGS',
    );
    await intent.launch();
  }

  static Future<void> openNotificationSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.APP_NOTIFICATION_SETTINGS',
      arguments: <String, String>{
        'android.provider.extra.APP_PACKAGE': 'com.cenerg.app',
      },
    );
    await intent.launch();
  }

  static Future<bool> isEmulator() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    return deviceInfo.isPhysicalDevice == false;
  }

  static Future<void> checkDeviceCompatibility() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    
    if (deviceInfo.version.sdkInt < 21) { // Android 5.0 minimum
      throw Exception('Cette application nécessite Android 5.0 ou supérieur');
    }

    if (await isEmulator()) {
      throw Exception('Cette application ne fonctionne pas sur un émulateur');
    }
  }
}
