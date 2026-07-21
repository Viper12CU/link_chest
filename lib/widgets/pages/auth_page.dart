import 'package:flutter/material.dart';
import 'package:link_chest/widgets/templates/auth_template.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 70,
        automaticallyImplyLeading: false,
        title: Text("VAULT PRIVADO", style: TextStyle(letterSpacing: 4.0)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22.0),
        ),
      ),
      body: AuthTemplate(),
    );
  }
}
