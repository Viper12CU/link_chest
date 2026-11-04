import 'dart:async';

import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/widgets/templates/verify_email_template.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

class VerifyEmailPage extends StatefulWidget {
  final String email;
  final Future<bool> Function() onCheckVerification;

  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.onCheckVerification,
  });

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _checking = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCheck() async {
    if (_checking) return;

    setState(() => _checking = true);
    try {
      final verified = await widget.onCheckVerification();
      if (!mounted) return;

      if (!verified) {
        ToastifyFlutter.info(
          context,
          message:
              'Aún no detectamos la verificación. Revisa tu correo e inténtalo de nuevo.',
          duration: 3,
        );
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ToastifyFlutter.error(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      ToastifyFlutter.error(
        context,
        message: 'No pudimos comprobar tu correo. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _handleResend() async {
    if (_resending || _cooldown > 0) return;

    setState(() => _resending = true);
    try {
      await AuthService.instance.sendEmailVerification();
      if (!mounted) return;

      ToastifyFlutter.success(
        context,
        message: 'Correo reenviado a ${widget.email}.',
      );
      _startCooldown();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ToastifyFlutter.error(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      ToastifyFlutter.error(
        context,
        message: 'No pudimos reenviar el correo. Inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _handleSignOut() async {
    try {
      await AuthService.instance.signOut();
    } on AuthFailure catch (e) {
      if (!mounted) return;
      ToastifyFlutter.error(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      ToastifyFlutter.error(
        context,
        message: 'No pudimos cerrar la sesión. Inténtalo de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VerifyEmailTemplate(
        email: widget.email,
        isChecking: _checking,
        isResending: _resending,
        resendCooldown: _cooldown,
        onCheck: _handleCheck,
        onResend: _handleResend,
        onSignOut: _handleSignOut,
      ),
    );
  }
}
