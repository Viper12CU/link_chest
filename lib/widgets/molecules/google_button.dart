import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class GoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool loading;

  const GoogleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
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
      child: loading
          ? LoadingAnimationWidget.waveDots(
              color: colorScheme.onSecondary,
              size: 30,
            )
          : Row(
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
