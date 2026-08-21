import 'package:flutter/material.dart';

import './app.dart';
import './core/config/app_build.dart';
import './core/push/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read which build this is before painting: the profile prints it, and a bug
  // report is worth little without knowing the version it came from.
  await AppBuild.load();
  // Firebase must be up before anything asks for a push token. It swallows its
  // own failures: a phone without Play Services still opens the app and still
  // has its inbox, which is the channel that never depends on a vendor.
  await PushService.initializeFirebase();
  runApp(const EdvRouteApp());
}
