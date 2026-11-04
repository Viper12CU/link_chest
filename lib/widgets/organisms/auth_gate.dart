import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/widgets/pages/login_page.dart';

class AuthGate extends StatelessWidget {
  final Widget home;
  const AuthGate({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        debugPrint('AuthGate -> state=${snapshot.connectionState} uid=${snapshot.data?.uid} error=${snapshot.error}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.hasData ? home : const LoginPage();
      },
    );
  }
}
