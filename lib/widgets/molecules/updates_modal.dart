import 'package:flutter/material.dart';
import 'package:link_chest/providers/version_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdatesModal extends StatelessWidget {
  const UpdatesModal({super.key});

  static Future<T?> show<T>({
    required BuildContext context,
    String? description,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => UpdatesModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final VersionProvider versionProvider = Provider.of<VersionProvider>(
      context,
    );
    final bool hasUpdate = versionProvider.hasUpdate;
    final ThemeData theme = Theme.of(context);

    return versionProvider.isLoading
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              spacing: 12.0,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 8.0,
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(Icons.download_rounded, color: Colors.white),
                    ),
                    Column(
                      spacing: 3,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasUpdate
                              ? "!Mantente al día¡"
                              : "Info de actualización",
                          style: theme.textTheme.headlineSmall,
                        ),
                        badge(theme, hasUpdate),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12),
                hasUpdate
                    ? hasUpdateInfo(theme, versionProvider)
                    : notUpdateInfo(theme, versionProvider),
                SizedBox(height: 20.0),
                Row(
                  spacing: 3,
                  children: [
                    if (hasUpdate) ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.scaffoldBackgroundColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 3,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: theme.textTheme.labelLarge!.color,
                              ),
                              Text(
                                "Más tarde",
                                style: theme.textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!hasUpdate) {
                            await versionProvider.checkForUpdateManually();
                          } else {
                            final uri = Uri.parse(
                              "https://viper12cu.github.io/Link-Chest-Release-Web/",
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 3,
                          children: [
                            Icon(
                              hasUpdate
                                  ? Icons.download_rounded
                                  : Icons.replay_rounded,
                            ),
                            Text(
                              hasUpdate
                                  ? "Descargar"
                                  : "Comprobar actualizaciones",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
  }

  Column hasUpdateInfo(ThemeData theme, VersionProvider versionProvider) {
    return Column(
      spacing: 2.0,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Instalda", style: theme.textTheme.labelMedium),
                  Text(
                    "v${versionProvider.currentVersion}",
                    style: theme.textTheme.labelLarge,
                  ),
                ],
              ),
              Icon(Icons.keyboard_double_arrow_right_rounded, size: 30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Disponible",
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    "v${versionProvider.latestVersion}",
                    style: theme.textTheme.labelLarge!.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (versionProvider.latestReleaseDate.isNotEmpty) ...[
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 4.0,
            children: [
              Icon(Icons.calendar_month_rounded, size: 16),
              Text(
                "Fecha de publicación: ${versionProvider.latestReleaseDate}",
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget notUpdateInfo(ThemeData theme, VersionProvider versionProvider) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Instalda", style: theme.textTheme.labelMedium),
              Text(
                "v${versionProvider.currentVersion}",
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Fecha",
                style: theme.textTheme.labelMedium,
              ),
              Text(
                versionProvider.latestReleaseDate,
                style: theme.textTheme.labelLarge
              ),
            ],
          ),
        ],
      ),
    );
  }

  Container badge(ThemeData theme, bool hasUpdate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        spacing: 3.0,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.green),
          Text(
            hasUpdate ? "Nueva actualización disponible" : "Versión al día",
            style: theme.textTheme.labelMedium!.copyWith(color: Colors.green),
          ),
        ],
      ),
    );
  }
}
