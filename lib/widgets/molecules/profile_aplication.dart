import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import 'package:link_chest/providers/version_provider.dart';
import 'package:link_chest/widgets/atoms/profile_item.dart';
import 'package:link_chest/widgets/molecules/updates_modal.dart';
import 'package:provider/provider.dart';

class ProfileAplication extends StatelessWidget {
  const ProfileAplication({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String currentVersion = Provider.of<VersionProvider>(
      context,
    ).currentVersion;
    final VersionProvider versionProvider = Provider.of<VersionProvider>(
        context,
      );


    void aboutDialog() {
      showAboutDialog(
        context: context,
        applicationIcon: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/logo.png',
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        applicationName: "Link Chest",
        applicationVersion: currentVersion,
        applicationLegalese:
            "© ${DateTime.now().year} Link Chest. Todos los derechos reservados.",
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 18.0,
              horizontal: 8.0,
            ),
            child: Text(
              "Aquí no se pierden links. Link Chest te ayuda a ordenar tus enlaces favoritos para encontrarlos cuando de verdad los necesitas. ✨📌\n\nHecho para tí por Fabian Lemus.",
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium,
            ),
          ),
        ],
      );
    }

    return Column(
      spacing: 10.0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'APLICACIÓN',
          style: theme.textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                ProfileItem(
                  icon: Icons.file_download_outlined,
                  title: "Actualizaciones",
                  textLabel: "Instalada v$currentVersion",
                  action: badges.Badge(
                    position: badges.BadgePosition.topEnd(top: 7, end: 8),
                    showBadge: !versionProvider.isNotified,
                    child: IconButton(
                      onPressed: () => UpdatesModal.show(context: context),
                      icon: Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ),
                Divider(height: 1, color: theme.colorScheme.outline),

                ProfileItem(
                  icon: Icons.info_outline,
                  title: "Acerca de",
                  textLabel: "LinkChest",
                  action: IconButton(
                    onPressed: () {
                      aboutDialog();
                    },
                    icon: Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
