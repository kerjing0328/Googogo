import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/planner/planner_web_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load Environment Variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    webProvider: ReCaptchaV3Provider('your-recaptcha-site-key'), 
  );

  // Web-Specific Initialization
  if (kIsWeb) {
    js.context['dartMapsReady'] = () {
      print('Dart knows Google Maps is ready!');
    };
    // Retrieve the API Key securely from .env
    final mapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (mapsApiKey.isNotEmpty) {
      js.context.callMethod('loadMapsScript', [mapsApiKey]);
    } else {
      debugPrint('WARNING: GOOGLE_MAPS_API_KEY not found in .env');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AidCess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
          primary: Colors.indigo.shade900,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: kIsWeb ? const PlannerWebShell() : const HomeScreen(),
    );
  }
}