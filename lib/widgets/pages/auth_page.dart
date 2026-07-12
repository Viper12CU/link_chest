import 'package:flutter/material.dart';
import 'package:link_chest/widgets/templates/auth_template.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("VAULT PRIVADO", style: TextStyle(letterSpacing: 4.0),),
        centerTitle: true,
      ),
      body: AuthTemplate(),
    );
  }
}