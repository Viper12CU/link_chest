import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/widgets/atoms/confirm_dialog.dart';
import 'package:link_chest/widgets/molecules/active_sessions.dart';
import 'package:link_chest/widgets/molecules/profile_aplication.dart';
import 'package:link_chest/widgets/molecules/profile_export_data.dart';
import 'package:link_chest/widgets/molecules/profile_stats.dart';
import 'package:link_chest/widgets/molecules/web_access_banner.dart';
import 'package:link_chest/widgets/organisms/profile_header.dart';
import 'package:link_chest/widgets/pages/login_page.dart';

class ProfileTemplate extends StatefulWidget {
  const ProfileTemplate({super.key});

  @override
  State<ProfileTemplate> createState() => _ProfileTemplateState();
}

class _ProfileTemplateState extends State<ProfileTemplate> {
  late final AuthService _authService;


  @override
  void initState() {
    super.initState();
    _authService = AuthService.instance;
  }


  @override
  Widget build(BuildContext context) {
    final User currentUser = _authService.currentUser!;


    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
      child: Column(
        spacing: 24,
        children: [
          ProfileHeader(
            username: currentUser.displayName ?? 'Usuario',
            email: currentUser.email ?? 'usuario@email.com',
          ),
          const ProfileStats(),
          const WebAccessBanner(),
          const ActiveSessions(),
          const ProfileAplication(),
          const ProfileExportData(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red, width: 2),
              iconSize: 22,
              iconColor: Colors.red,
              foregroundColor: Colors.red,
              textStyle: Theme.of(context).textTheme.bodyMedium,
            ),
            onPressed: () {
              ConfirmDialog.show(
                context: context,
                title: "Cerrar la sesión actual",
                description: "Se terminará con la sesión en este dispositivo ",
                actions: [
                  ConfirmAction(
                    label: "Cerrar sesión",
                    onTap: () {
                      AuthService.instance.signOut();

                      AuthService.instance.authStateChanges.listen((user) {
                        if (user == null) {
                          if (context.mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                            );
                          }
                        }
                      });
                    },
                    style: ConfirmActionStyle.destructive,
                  ),
                ],
              );
            },
            label: Text("Cerrar sesión"),
            icon: Icon(Icons.logout_outlined),
          ),
        ],
      ),
    );
  }
}
