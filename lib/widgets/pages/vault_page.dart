import 'package:flutter/material.dart';
import 'package:link_chest/widgets/templates/vault_template.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    List<BoxShadow> boxShadow = [
      BoxShadow(
        color: const Color.fromARGB(144, 134, 134, 134),
        offset: Offset(2, 4),
        blurRadius: 5.0,
      ),
    ];

    Expanded title(BuildContext context) {
      return Expanded(
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            boxShadow: boxShadow,
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Row(
            spacing: 12.0,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Vault Privado",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget backButton() {
      return Container(
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: theme.colorScheme.primary,
          boxShadow: boxShadow,
        ),
        child: Center(
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22.0,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    Container appBar(
      Widget Function() backButton,
      Expanded Function(BuildContext context) title,
      BuildContext context,
    ) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
        height: kToolbarHeight,
        color: Colors.transparent,
        child: Row(spacing: 8, children: [backButton(), title(context)]),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            appBar(backButton, title, context),
            Expanded(child: VaultTemplate()),
          ],
        ),
      ),
    );
  }
}
