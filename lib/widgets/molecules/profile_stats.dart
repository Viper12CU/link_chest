import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';
import 'package:link_chest/providers/category_provider.dart';
import 'package:link_chest/providers/link_provider.dart';
import 'package:link_chest/utils/shared/color_parse.dart';
import 'package:provider/provider.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);
    final CategoryProvider categoryProvider = Provider.of<CategoryProvider>(
      context,
    );

    final int totalLinks = linkProvider.links.length;
    final int totalCategories = categoryProvider.categories.length;

    Widget buildStat() {
      final visible = categoryProvider.categories;
      if (visible.isEmpty) return const SizedBox.shrink();

      return Column(
        spacing: 18,
        children: [
          SizedBox(
            height: 12,
            child: Row(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (linkProvider.byCategory(visible[i].id!).isNotEmpty)
                    if (i > 0)
                      const SizedBox(width: 1.5), // separación entre segmentos
                  Expanded(
                    flex: linkProvider.byCategory(visible[i].id!).length,
                    child: Container(
                      decoration: BoxDecoration(
                        color: ColorParse().toColor(visible[i].color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Leyenda en 2 columnas iguales
          Column(
            children: [
              for (var i = 0; i < visible.length; i += 2)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: Row(
                    children: [
                      Expanded(child: _LegendItem(category: visible[i])),
                      const SizedBox(width: 16),
                      Expanded(
                        child: i + 1 < visible.length
                            ? _LegendItem(category: visible[i + 1])
                            : const SizedBox.shrink(), // columna vacía si la cantidad es impar
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Text(
          'TUS ESTADÍSTICAS',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15.0),
          ),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          totalLinks > 1 ? "Links" : "Link",
                          totalLinks.toString(),
                          theme,
                        ),
                      ),
                      VerticalDivider(
                        color: theme.colorScheme.onSurfaceVariant,
                        width: 1,
                        thickness: 1,
                        indent: 2,
                        endIndent: 2,
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        child: _buildStatItem(
                          totalCategories > 1 ? "Categorías" : "Categoría",
                          totalCategories.toString(),
                          theme,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
                buildStat(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: theme.textTheme.displayLarge),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium!.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final LinkProvider linkProvider = Provider.of<LinkProvider>(context);


    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color:  ColorParse().toColor(category.color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            category.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${linkProvider.byCategory(category.id!).length}',
          style: theme.textTheme.labelSmall
        ),
      ],
    );
  }
}
