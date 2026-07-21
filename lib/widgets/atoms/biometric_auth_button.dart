import 'package:flutter/material.dart';

class BiometricAuthButton extends StatelessWidget {
  final VoidCallback onCheck;
  const BiometricAuthButton({super.key, required this.onCheck});

  @override
  Widget build(BuildContext context) {
    const double containerSize = 100.0;
    const double totalSize = containerSize;

    return GestureDetector(
      onTap: onCheck,
      child: SizedBox(
        width: totalSize,
        height: totalSize,
        child: Container(
          height: containerSize,
          width: containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: const Color.fromARGB(255, 112, 112, 112), width: 2.0),
          ),
          child: const Center(
            child: Icon(Icons.fingerprint_rounded, size: 60.0),
          ),
        ),
      ),
    );
  }
}
