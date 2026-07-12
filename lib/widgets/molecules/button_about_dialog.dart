import 'package:custom_clippers/custom_clippers.dart';
import 'package:flutter/material.dart';
// import 'package:link_chest/database/models/category_model.dart';
// import 'package:link_chest/providers/category_provider.dart';
// import 'package:link_chest/utils/shared/color_parse.dart';
// import 'package:provider/provider.dart';

class ButtonAboutDialog extends StatelessWidget {
  const ButtonAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: DirectionalWaveClipper(
        horizontalPosition: HorizontalPosition.left,
        verticalPosition: VerticalPosition.top,
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.redAccent),
        height: 90,
        padding: EdgeInsets.only(top: 25.0, right: 25.0),
        child: GestureDetector(
          onTap: () {
            //           Provider.of<CategoryProvider>(context, listen: false).updateDefault(CategoryModel(
            //   title: 'Default',
            //   icon: '📂',
            //   color: ColorParse().toColorString(Colors.redAccent),
            // ),);

            showAboutDialog(
              context: context,
              applicationIcon: FlutterLogo(size: 50.0),
              applicationName: "Link Chest",
              applicationVersion: "1.0.0",
              applicationLegalese: "${DateTime.now().year} Link Chest",
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18.0,
                    horizontal: 8.0,
                  ),
                  child: Text("Desarrollado por Fabian Lemus"),
                ),
              ],
            );
          },
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              Text(
                "Acerca de",
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
