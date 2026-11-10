import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/widgets/pages/login_page.dart';
import 'package:link_chest/widgets/pages/verify_email_page.dart';

class AuthGate extends StatefulWidget {
  final Widget home;

  const AuthGate({super.key, required this.home});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  User? _user;
  bool _initializing = false;
  StreamSubscription<User?>? _userSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _user = AuthService.instance.currentUser;
    _initializing = _user != null && !_user!.emailVerified;
    _userSubscription = AuthService.instance.userChanges.listen(
      _handleUserChanged,
    );

    if (_initializing) {
      unawaited(_refreshInitialVerification());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final user = _user;
    if (user != null && !user.emailVerified) {
      unawaited(_refreshVerification(silent: true));
    }
  }

  void _handleUserChanged(User? user) {
    if (!mounted) return;

    setState(() {
      _user = user;
      if (user == null) _initializing = false;
    });
  }

  Future<void> _refreshInitialVerification() async {
    await _refreshVerification(silent: true);
    if (!mounted) return;
    setState(() => _initializing = false);
  }

  Future<bool> _refreshVerification({bool silent = false}) async {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    try {
      final verified = await AuthService.instance.refreshEmailVerified();
      if (mounted) {
        setState(() => _user = AuthService.instance.currentUser);
      }
      return verified;
    } on AuthFailure {
      if (silent) return user.emailVerified;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) return const LoginPage();

    if (!user.emailVerified) {
      return VerifyEmailPage(
        email: user.email ?? 'tu correo',
        onCheckVerification: () => _refreshVerification(),
      );
    }

    return widget.home;
  }
}
