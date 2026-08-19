import 'package:flutter/material.dart';

import './app.dart';
import './core/config/app_build.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Read which build this is before painting: the profile prints it, and a bug
  // report is worth little without knowing the version it came from.
  await AppBuild.load();
  runApp(const EdvRouteApp());
}
