import 'package:flutter/material.dart';
import 'package:link_chest/database/models/link_model.dart';

class VisibilitySwitch extends StatelessWidget {
  final LinkStatus status;
  final ValueChanged<LinkStatus> onChanged;

  const VisibilitySwitch({super.key, required this.status, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = status == LinkStatus.private
        ? cs.tertiaryContainer
        : cs.tertiary;

    return GestureDetector(
      onTap: () => onChanged(
        status == LinkStatus.public ? LinkStatus.private : LinkStatus.public,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.ease,
        height: 48,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline),
        ),
        child: Stack(
          children: [
            // ── Labels ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Public',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: status == LinkStatus.public
                            ? Colors.white
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Private',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: status == LinkStatus.private
                            ? Colors.white
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Thumb ──────────────────────────────────────
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              alignment: status == LinkStatus.private
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          status == LinkStatus.private
                              ? Icons.lock
                              : Icons.lock_open,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status == LinkStatus.private ? 'Private' : 'Public',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
