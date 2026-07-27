import 'package:flutter/material.dart';


class ButtonAboutDialog extends StatelessWidget {
  const ButtonAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
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
          applicationVersion: "0.2.0",
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
                style: textTheme.labelMedium,
              ),
              
            ),
          ],
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Divider(height: 1, color: Colors.grey[300], endIndent: 3, indent: 3),
    
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
              child: Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.grey,),
                  Text(
                    "ACERCA DE",
                    style: textTheme.bodyLarge!.copyWith(
                      color: Colors.grey,
                      letterSpacing: 2,
                    ),
                    
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
