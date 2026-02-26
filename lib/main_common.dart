import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/auth/login_screen.dart';

class MyApp extends StatelessWidget {
  final Widget home; 

  const MyApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Googogo', 
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
      home: home, 
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Widget Function(String userName) authenticatedBuilder;

  const AuthWrapper({super.key, required this.authenticatedBuilder});

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
          return authenticatedBuilder(userName);
        }
        return const LoginScreen();
      },
    );
  }
}