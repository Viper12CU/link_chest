import 'package:flutter/material.dart';
import 'package:link_chest/models/form_sizes.dart';
import 'package:link_chest/providers/login_provider.dart';
import 'package:link_chest/utils/shared/navigate_before_login.dart';
import 'package:link_chest/widgets/atoms/back_button.dart';
import 'package:link_chest/widgets/molecules/auth_choice_actions.dart';
import 'package:link_chest/widgets/molecules/welcome_hero.dart';
import 'package:link_chest/widgets/organisms/curved_auth_panel.dart';
import 'package:link_chest/widgets/organisms/login_form.dart';
import 'package:link_chest/widgets/organisms/sign_up_form.dart';
import 'package:provider/provider.dart';

class LoginTemplate extends StatefulWidget {
  const LoginTemplate({super.key});

  @override
  State<LoginTemplate> createState() => _LoginTemplateState();
}

class _LoginTemplateState extends State<LoginTemplate>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 450);
  static const Animation<double> _hidden = AlwaysStoppedAnimation(0.0);

  late final AnimationController _controller;
  late final CurvedAnimation _contentIn;
  late final CurvedAnimation _contentOut;
  late final Animation<double> _previousOpacity;

  // Bloques pre-montados y ocultos por opacidad: sin mount cost en el tap.
  late final Widget _choiceChild;
  late final Widget _loginChild;
  late final Widget _signUpChild;

  FormSizesType _type = FormSizesType.initial;
  FormSizesType? _previousType;
  FormSizes _from = FormSizesType.initial.sizes;
  FormSizes _to = FormSizesType.initial.sizes;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..value = 1.0;
    _contentIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    _contentOut = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeInCubic),
    );
    _previousOpacity = ReverseAnimation(_contentOut);
    _controller.addStatusListener(_handleAnimationStatus);

    _choiceChild = AuthChoiceActions(
      onLogin: () => handleTap(FormSizesType.login),
      onSignUp: () => handleTap(FormSizesType.signUp),
    );
    _loginChild = Padding(
      padding: const EdgeInsets.all(28.0),
      child: LoginForm(submit: () {}, onGoogleSignIn: _signInWithGoogle),
    );
    _signUpChild = Padding(
      padding: const EdgeInsets.all(28.0),
      child: SignUpForm(submit: () {}, onGoogleSignUp: _signUpWithGoogle),
    );
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatus);
    _contentIn.dispose();
    _contentOut.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousType != null) {
      setState(() => _previousType = null);
    }
  }

  void _signInWithGoogle() {
    Provider.of<LoginProvider>(context, listen: false).signInWithGoogle();
    navigateBeforeLogin(context);
  }

  void _signUpWithGoogle() {
    Provider.of<LoginProvider>(context, listen: false).signUpWithGoogle();
    navigateBeforeLogin(context);
  }

  void handleTap(FormSizesType type) {
    if (type == _type) return;

    final double t = Curves.easeOutCubic.transform(_controller.value);
    _from = _from.lerpTo(_to, t);
    _to = type.sizes;

    setState(() {
      _previousType = _type;
      _type = type;
    });
    _controller.forward(from: 0);
  }

  Widget _childFor(FormSizesType type) {
    switch (type) {
      case FormSizesType.initial:
        return _choiceChild;
      case FormSizesType.login:
        return _loginChild;
      case FormSizesType.signUp:
        return _signUpChild;
    }
  }

  Animation<double> _contentOpacity(FormSizesType type) {
    if (type == _type) return _contentIn;
    if (type == _previousType) return _previousOpacity;
    return _hidden;
  }

  bool _isLocked(FormSizesType type) =>
      _previousType != null || type != _type;

  /// Fade + micro-slide para los bloques superiores (Volver / bienvenida).
  Widget _contentTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  /// Viewport de altura fija por bloque: su layout no cambia con la animación.
  Widget _panelViewport(BuildContext context, double primary, Widget child) {
    final double height =
        MediaQuery.sizeOf(context).height * primary -
            CurvedAuthPanel.bottomPadding;

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [child],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedSwitcher(
          duration: _animationDuration,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: _contentTransition,
          child: _type != FormSizesType.initial
              ? Align(
                  alignment: Alignment.topLeft,
                  child: AuthBackButton(
                    onPressed: () => handleTap(FormSizesType.initial),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('back')),
        ),

        AnimatedSwitcher(
          duration: _animationDuration,
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: _contentTransition,
          child: _type == FormSizesType.initial
              ? const WelcomeHero(key: ValueKey('welcome'))
              : const SizedBox.shrink(key: ValueKey('welcome')),
        ),

        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: CurvedAuthPanel(
              animation: _controller,
              from: _from,
              to: _to,
              contentMax: FormSizesType.signUp,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  for (final FormSizesType type in FormSizesType.values)
                    IgnorePointer(
                      ignoring: _isLocked(type),
                      child: FadeTransition(
                        opacity: _contentOpacity(type),
                        child: KeyedSubtree(
                          key: ValueKey(type),
                          child: _panelViewport(
                            context,
                            type.primary,
                            _childFor(type),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
