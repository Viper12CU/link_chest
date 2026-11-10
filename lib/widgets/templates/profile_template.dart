import 'package:flutter/material.dart';
import 'package:link_chest/services/auth_service.dart';
import 'package:link_chest/widgets/molecules/active_sessions.dart';
import 'package:link_chest/widgets/molecules/profile_account.dart';
import 'package:link_chest/widgets/molecules/profile_aplication.dart';
import 'package:link_chest/widgets/molecules/profile_export_data.dart';
import 'package:link_chest/widgets/molecules/profile_stats.dart';
import 'package:link_chest/widgets/molecules/web_access_banner.dart';
import 'package:link_chest/widgets/organisms/profile_header.dart';

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
    final user = _authService.currentUser;
    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
      child: Column(
        spacing: 24,
        children: [
          ProfileHeader(
            username: user.displayName ?? 'Usuario',
            email: user.email ?? 'usuario@email.com',
          ),
          const ProfileStats(),
          const WebAccessBanner(),
          const ActiveSessions(),
          ProfileAccount(
            email: user.email ?? 'usuario@email.com',
            isVerified: user.emailVerified,
          ),
          const ProfileAplication(),
          const ProfileExportData(),
        ],
      ),
    );
  }
}
