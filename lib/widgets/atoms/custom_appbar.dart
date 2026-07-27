import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/services/local_auth.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:link_chest/widgets/pages/auth_page.dart';

class CustomAppbar extends StatelessWidget {
  final CategoryModel category;

  const CustomAppbar({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = ColorParse().toColor(category.color);
    final ColorScheme cs = Theme.of(context).colorScheme;

    Color getContrastColor(Color background) {
      final brightness = ThemeData.estimateBrightnessForColor(background);
      return brightness == Brightness.dark ? cs.onPrimary : cs.onSurface;
    }

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
            color: categoryColor,
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: GestureDetector(
            onLongPress: () async {
              final bool canAuth = await LocalAuthService.canAuthenticate();

              if (context.mounted) {
                canAuth
                    ? Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AuthPage()),
                      )
                    : null;
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                
                spacing: 12.0,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(category.icon, style: TextStyle(fontSize: 18)),
                  Flexible(
                    child: Text(
                      category.title,
                      style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        color: getContrastColor(categoryColor),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget drawerButton() {
      return Container(
        width: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: categoryColor,
          boxShadow: boxShadow,
        ),
        child: Center(
          child: IconButton(
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: Icon(
              Icons.menu_rounded,
              size: 28.0,
              color: getContrastColor(categoryColor),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      height: kToolbarHeight,
      color: Colors.transparent,
      child: Row(spacing: 8.0, children: [drawerButton(), title(context)]),
    );
  }
}
