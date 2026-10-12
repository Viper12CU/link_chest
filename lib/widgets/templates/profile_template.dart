import 'package:flutter/material.dart';
import 'package:link_chest/providers/login_provider.dart';
import 'package:link_chest/widgets/atoms/confirm_dialog.dart';
import 'package:link_chest/widgets/molecules/active_sessions.dart';
import 'package:link_chest/widgets/molecules/profile_aplication.dart';
import 'package:link_chest/widgets/molecules/profile_export_data.dart';
import 'package:link_chest/widgets/molecules/profile_stats.dart';
import 'package:link_chest/widgets/molecules/web_access_banner.dart';
import 'package:link_chest/widgets/organisms/profile_header.dart';
import 'package:link_chest/widgets/pages/login_page.dart';
import 'package:provider/provider.dart';

class ProfileTemplate extends StatelessWidget {
  const ProfileTemplate({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
      child: Column(
        spacing: 24,
        children: [
          const ProfileHeader(
            username: 'Nombre de Usuario',
            email: 'usuario@email.com',
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
                      Provider.of<LoginProvider>(context, listen: false).signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginPage()),
                      );
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
