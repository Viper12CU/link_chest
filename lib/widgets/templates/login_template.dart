import 'package:flutter/material.dart';
import 'package:link_chest/models/form_sizes.dart';
import 'package:link_chest/widgets/organisms/login_form.dart';
import 'package:link_chest/widgets/organisms/sign_up_form.dart';

class LoginTemplate extends StatefulWidget {
  const LoginTemplate({super.key});

  @override
  State<LoginTemplate> createState() => _LoginTemplateState();
}

class _LoginTemplateState extends State<LoginTemplate> {
  FormSizes _formSizes = FormSizes(
    type: FormSizesType.initial,
    primary: 0.34,
    firstShadow: -60,
    secondShadow: -120,
  );

  void handleTap(FormSizesType type) {
    switch (type) {
      case FormSizesType.login:
        setState(() {
          _formSizes = _formSizes.copyWith(
            type: type,
            primary: 0.62,
            firstShadow: -40,
            secondShadow: -80,
          );
        });
        break;
      case FormSizesType.signUp:
        setState(() {
          _formSizes = _formSizes.copyWith(
            type: type,
            primary: 0.85,
            firstShadow: -30,
            secondShadow: -60,
          );
        });
        break;

      case FormSizesType.initial:
        setState(() {
          _formSizes = _formSizes.copyWith(
            type: type,
            primary: 0.34,
            firstShadow: -60,
            secondShadow: -120,
          );
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final ThemeData theme = Theme.of(context);

     Widget buildChild(FormSizesType type) {
     switch (type) {
       case FormSizesType.initial:
         return Column(
                spacing: 15.0,
              
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: screenWidth * 0.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(24),
                        ),
                      ),
                      onPressed: () {
                        handleTap(FormSizesType.login);
                      },
                      child: Text(
                        "Inicia Sesión",
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth * 0.5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: theme.colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 2,
                            color: theme.colorScheme.secondary,
                          ),
                          borderRadius: BorderRadiusGeometry.circular(24),
                        ),
                      ),
                      onPressed: () {
                        handleTap(FormSizesType.signUp);
                      },
                      child: Text(
                        "Crea una cuenta",
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
         case FormSizesType.login:
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: LoginForm(submit: () {}, onGoogleSignIn: () {}),
          );
         
         case FormSizesType.signUp:
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: SignUpForm(submit: () {}, onGoogleSignUp: () {}),
          );
         
       
     }
  }

    return Column(
      children: [
        if (_formSizes.type != FormSizesType.initial) ...[
          Align(
            alignment: AlignmentGeometry.topLeft,
            child: TextButton.icon(
              onPressed: () {
                handleTap(FormSizesType.initial);
              },
              label: Text("Volver", style: theme.textTheme.bodyLarge),
              icon: Icon(Icons.arrow_back_ios_new_rounded),
            ),
          ),
        ],

        if (_formSizes.type == FormSizesType.initial) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: screenHeight * 0.25),
              Text("Bienvenido a Link Chest", textAlign: TextAlign.center),
            ],
          ),
        ],

        Expanded(
          child: Align(
            alignment: AlignmentGeometry.bottomCenter,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 450),
              padding: EdgeInsets.only(bottom: 35),
              width: screenWidth,
              height: screenHeight * _formSizes.primary,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(411, 211),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDADBDC),
                    offset: Offset(0, _formSizes.secondShadow),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0xFFD0D3D4),
                    offset: Offset(0, _formSizes.firstShadow),
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child:  Align(alignment: AlignmentGeometry.bottomCenter, child: buildChild(_formSizes.type))
            ),
          ),
        ),
      ],
    );
  }

 
}

class TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 60);
    // Curva tipo cúpula: el punto de control sube el centro
    path.quadraticBezierTo(size.width / 2, -60, size.width, 60);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
