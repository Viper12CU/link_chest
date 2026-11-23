import 'dart:async';

import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/services/sync/sync_service.dart';
import 'package:link_chest/widgets/organisms/account_prep_screen.dart';
import 'package:link_chest/widgets/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:link_chest/widgets/pages/verify_email_page.dart';

class AuthGate extends StatefulWidget {
  final Widget home;

  const AuthGate({super.key, required this.home});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  AppUser? _user;
  AppUser? _pendingUser;
  bool _initializing = false;
  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<AppUser?>? _pendingSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _user = AuthService.instance.currentUser;
    _pendingUser = AuthService.instance.pendingUser;
    _initializing = _user != null && !_user!.emailVerified;
    _userSubscription = AuthService.instance.userChanges.listen(
      _handleUserChanged,
    );
    _pendingSubscription = AuthService.instance.pendingUserChanges.listen(
      _handlePendingChanged,
    );

    // Sesión ya guardada al abrir la app.
    _syncHooks(_user);

    if (_initializing) {
      unawaited(_refreshInitialVerification());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userSubscription?.cancel();
    _pendingSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    final user = _user;
    if (user != null && user.emailVerified) {
      unawaited(SyncService.instance.syncNow());
      unawaited(_refreshVerification(silent: true));
      return;
    }

    // Registro pendiente de confirmación: el usuario pudo abrir el enlace del
    // correo mientras la app estaba en background.
    if (user == null && _pendingUser != null) {
      unawaited(_refreshVerification(silent: true));
    }
  }

  void _handleUserChanged(AppUser? user) {
    if (!mounted) return;

    setState(() {
      _user = user;
      if (user == null) _initializing = false;
    });
    _syncHooks(user);
  }

  /// Ganchos mínimos de sync con la sesión existente (plan fase 4).
  void _syncHooks(AppUser? user) {
    final sync = SyncService.instance;
    if (user != null && user.emailVerified) {
      unawaited(sync.start(user.id));
    } else if (user == null) {
      // No borra datos locales: solo se vacían al entrar otro usuario.
      sync.stop();
    }
  }

  void _handlePendingChanged(AppUser? pending) {
    if (!mounted) return;

    setState(() {
      _pendingUser = pending;
      if (pending == null && _user == null) _initializing = false;
    });
  }

  Future<void> _refreshInitialVerification() async {
    await _refreshVerification(silent: true);
    if (!mounted) return;
    setState(() => _initializing = false);
  }

  Future<bool> _refreshVerification({bool silent = false}) async {
    final AuthService service = AuthService.instance;
    final user = service.currentUser;
    final pending = service.pendingUser;
    if (user == null && pending == null) return false;

    try {
      final verified = await service.refreshEmailVerified();
      if (mounted) {
        setState(() {
          _user = service.currentUser;
          _pendingUser = service.pendingUser;
        });
      }
      if (verified && _user != null) {
        unawaited(SyncService.instance.start(_user!.id));
      }
      return verified;
    } on AuthFailure {
      if (silent) return user?.emailVerified ?? false;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    if (user == null) {
      // Registro a la espera de confirmar el correo: Supabase no entrega
      // sesión hasta que el usuario abre el enlace del correo.
      final pending = _pendingUser;
      if (pending != null) {
        return VerifyEmailPage(
          email: pending.email ?? 'tu correo',
          onCheckVerification: () => _refreshVerification(),
        );
      }
      return const LoginPage();
    }

    if (!user.emailVerified) {
      return VerifyEmailPage(
        email: user.email ?? 'tu correo',
        onCheckVerification: () => _refreshVerification(),
      );
    }

    // Primera sincronización pendiente: pantalla de preparación de cuenta.
    // Consumer reconstruye cuando SyncService notifica (initialSyncDone).
    return Consumer<SyncService>(
      builder: (context, sync, _) {
        if (!sync.initialSyncDone) {
          return const AccountPrepScreen();
        }
        return widget.home;
      },
    );
  }
}
