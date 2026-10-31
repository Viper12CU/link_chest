import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const GoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1.5, color: colorScheme.onSecondary),
          borderRadius: BorderRadiusGeometry.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/google.svg',
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: colorScheme.onSecondary),
          ),
        ],
      ),
    );
  }
}
