import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final bool vault;
  const EmptyState({super.key, this.vault = false});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;


    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 38)),
          const SizedBox(height: 14),
          Text(
            'Sin links todavía',
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 5),
          Text(
            vault
                ? 'Aquí se muestran tus links privados '
                : 'Toca + para agregar tu primer link',
            style: textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
