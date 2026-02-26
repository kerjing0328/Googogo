import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:js' as js; 

import 'firebase_options.dart';
import 'main_common.dart';
import 'screens/planner/planner_web_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    webProvider: ReCaptchaV3Provider(dotenv.env['RECAPTCHA_SITE_KEY'] ?? 'your-key'), 
  );

  js.context['dartMapsReady'] = () {
    debugPrint('Dart knows Google Maps is ready!');
  };
  
  final mapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  if (mapsApiKey.isNotEmpty) {
    js.context.callMethod('loadMapsScript', [mapsApiKey]);
  }

  runApp(const MyApp(
    home: PlannerWebShell(userName: 'Authority Admin'),
  ));
}