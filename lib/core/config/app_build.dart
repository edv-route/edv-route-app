import 'package:package_info_plus/package_info_plus.dart';

/// Which build is installed, read from the package itself.
///
/// Every APK delivered so far was called `app-release.apk` and showed nothing
/// about itself, so a bug reported on an old build was indistinguishable from a
/// bug on the new one — we burned a round trip on exactly that. The profile now
/// prints this at the bottom.
class AppBuild {
  AppBuild._();

  static String _label = '';

  /// `1.0.0 (2)`. Empty until [load] runs; the UI simply shows nothing then.
  static String get label => _label;

  /// Reads it once at start-up. A failure is not worth blocking the app for.
  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _label = '${info.version} (${info.buildNumber})';
    } catch (_) {
      _label = '';
    }
  }
}
