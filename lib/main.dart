import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:js' as js; // Restore for web logic

import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/planner/planner_web_shell.dart';
import 'screens/auth/login_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    webProvider: ReCaptchaV3Provider(dotenv.env['RECAPTCHA_SITE_KEY'] ?? 'your-key'), 
  );

  // Restore Web-Specific Initialization
  // if (kIsWeb) {
  //   js.context['dartMapsReady'] = () {
  //     debugPrint('Dart knows Google Maps is ready!');
  //   };
  //   final mapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  //   if (mapsApiKey.isNotEmpty) {
  //     js.context.callMethod('loadMapsScript', [mapsApiKey]);
  //   }
  // }

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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          final User user = snapshot.data!;
          final String userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
          return kIsWeb ? PlannerWebShell(userName: userName) : HomeScreen(userName: userName);
        }
        return const LoginScreen();
      },
    );
  }
}