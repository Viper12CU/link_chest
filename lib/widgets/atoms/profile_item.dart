import 'package:flutter/material.dart';

class ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? widgetLabel;
  final String? textLabel;
  final Widget action;
  const ProfileItem({super.key, required this.icon, required this.title, this.widgetLabel, this.textLabel, required this.action});

  @override
  Widget build(BuildContext context) {
     final ThemeData theme = Theme.of(context);

      if(widgetLabel != null && textLabel != null) {
        throw Exception('ProfileItem: Only one of widgetLabel or textLabel can be provided.');
      }


    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          // Icono en recuadro
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if(textLabel != null) ...[
                  Text(
                    textLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF93A0B3),
                    ),
                  ),
                ],
                if(widgetLabel != null) ...[
                  widgetLabel!,
                ],
               
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Etiqueta o botón
          action,
        ],
      ),
    );
  }
}