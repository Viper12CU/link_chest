import 'package:badges/badges.dart' as badges;
import 'package:badges/badges.dart';
import 'package:custom_clippers/custom_clippers.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/providers/onboarding_provider.dart';
import 'package:link_chest/providers/version_provider.dart';
import 'package:link_chest/widgets/molecules/button_about_dialog.dart';
import 'package:link_chest/widgets/molecules/updates_modal.dart';
import 'package:link_chest/widgets/molecules/category_items_group.dart';
import 'package:link_chest/widgets/organisms/add_category_sheet.dart';
import 'package:provider/provider.dart';

class CategoryDrawer extends StatefulWidget {
  const CategoryDrawer({super.key});

  @override
  State<CategoryDrawer> createState() => _CategoryDrawerState();
}

class _CategoryDrawerState extends State<CategoryDrawer> {
  @override
  Widget build(BuildContext context) {
    final VersionProvider versionProvider = Provider.of<VersionProvider>(
      context,
    );

    return Drawer(
      child: Column(
        children: [
          header(),
          Expanded(child: CategoryItemsGroup()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ButtonAboutDialog(),
                IconButton(
                  onPressed: () => {
                    Scaffold.of(context).closeDrawer(),
                    UpdatesModal.show(context: context),
                  },
                  icon: badges.Badge(
                    position: BadgePosition.topStart(),
                    badgeStyle: BadgeStyle(badgeColor: Colors.red),
                    showBadge: versionProvider.hasUpdate,
                    child: Icon(Icons.update_rounded),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget header() {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final OnboardingProvider onboardingProvider =
        Provider.of<OnboardingProvider>(context);

    return ClipPath(
      clipBehavior: Clip.hardEdge,
      clipper: DirectionalWaveClipper(
        horizontalPosition: HorizontalPosition.right,
      ),

      child: Container(
        padding: EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 6.0),
        height: 270.0,
        width: double.infinity,
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Link Chest",
              style: textTheme.displayMedium!.copyWith(color: Colors.white),
            ),
            Text(
              "Tú colección personal de links",
              style: textTheme.labelLarge!.copyWith(color: Colors.white),
            ),
            SizedBox(height: 20.0),
            DescribedFeatureOverlay(
              overflowMode: OverflowMode.wrapBackground,
              featureId: OnboardingProvider.stepAddCategory,
              tapTarget: Icon(Icons.add, size: 30.0),
              onComplete: () async {
                onboardingProvider.scaffoldKey.currentState?.closeDrawer();

                return true;
              },
              onDismiss: () async {
                return false;
              },
              title: Text(
                "Agrega una categoría",
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              description: Text(
                "Crea una nueva categoría para organizar tus links.",
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
              child: addCategoryButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget addCategoryButton() {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white, width: 2),
      ),
      onPressed: () {
        AddCategorySheet.show(context);
      },
      child: Row(
        spacing: 10.0,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: Colors.white),

          Text(
            "Agregar categoría",
            style: textTheme.labelLarge!.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
