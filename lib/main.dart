import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'state/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF030507),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final controller = AppController();
  await controller.loadPreferences();
  runApp(GymRecordsApp(controller: controller));
}
