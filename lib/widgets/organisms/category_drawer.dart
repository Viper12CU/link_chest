import 'package:custom_clippers/custom_clippers.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/providers/onboarding_provider.dart';
import 'package:link_chest/providers/version_provider.dart';
import 'package:link_chest/widgets/molecules/category_items_group.dart';
import 'package:link_chest/widgets/organisms/add_category_sheet.dart';
import 'package:link_chest/widgets/pages/profile_page.dart';
import 'package:provider/provider.dart';

class CategoryDrawer extends StatefulWidget {
  const CategoryDrawer({super.key});

  @override
  State<CategoryDrawer> createState() => _CategoryDrawerState();
}

class _CategoryDrawerState extends State<CategoryDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          header(),
          Expanded(child: CategoryItemsGroup()),
          profileButton(context),
        ],
      ),
    );
  }

  Column profileButton(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: colors.outlineVariant.withValues(alpha: 0.5),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Material(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Scaffold.of(context).closeDrawer();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 22,
                      color: colors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mi perfil',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cuenta y ajustes',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget header() {
    final TextTheme textTheme = Theme.of(context).textTheme;

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
                Navigator.pop(context);

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
