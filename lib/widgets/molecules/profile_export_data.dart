import 'package:flutter/material.dart';
import 'package:link_chest/widgets/atoms/profile_item.dart';

class ProfileExportData extends StatelessWidget {
  const ProfileExportData({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      spacing: 10.0,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MIS DATOS',
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
          child: ProfileItem(
            icon: Icons.cloud_download_outlined,
            title: "Exporta tus links",
            textLabel: "Link en formato JSON",
            action: IconButton(
              onPressed: () => {},
              icon: Icon(Icons.chevron_right_rounded),
            ),
          ),
        ),
      ],
    );
  }
}
