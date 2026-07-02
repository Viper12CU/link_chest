import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String? description;
  final List<ConfirmAction> actions;

  const ConfirmDialog({
    super.key,
    required this.title,
    this.description,
    required this.actions,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    required List<ConfirmAction> actions,
  }) {
    return showDialog<T>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        description: description,
        actions: actions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: description != null ? Text(description!) : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ...actions.map(
          (action) => switch (action.style) {
            ConfirmActionStyle.normal => TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  action.onTap();
                },
                child: Text(action.label),
              ),
            ConfirmActionStyle.destructive => SizedBox(
              width: 140,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    action.onTap();
                  },
                  child: Text(action.label, style: const TextStyle(color: Colors.white)),
                ),
            ),
            ConfirmActionStyle.primary => SizedBox(
              width: 140,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    Navigator.pop(context);
                    action.onTap();
                  },
                  child: Text(action.label),
                ),
            ),
          },
        ),
      ],
    );
  }
}

enum ConfirmActionStyle { normal, primary, destructive }

class ConfirmAction {
  final String label;
  final VoidCallback onTap;
  final ConfirmActionStyle style;

  const ConfirmAction({
    required this.label,
    required this.onTap,
    this.style = ConfirmActionStyle.normal,
  });
}