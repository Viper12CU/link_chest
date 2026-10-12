import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

class WebAccessBanner extends StatelessWidget {
  const WebAccessBanner({super.key});

  static const String _webUrl =
      'https://viper12cu.github.io/Link-Chest-Release-Web/';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color surface = theme.colorScheme.surface;
    final Color accent = theme.colorScheme.primary;
    final Color accentInk = theme.colorScheme.onPrimary;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(22),
            border: Border(left: BorderSide(color: accent, width: 2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const _MiniBrowser(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tus links también en el ordenador',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Entra a la versión web con tu cuenta y mira todos tus links en pantalla grande.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _copyWebUrl(context),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text('Copiar url'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: accentInk,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
      
      ],
    );
  }

  void _copyWebUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _webUrl));
    ToastifyFlutter.success(
      context,
      message: 'Link copiado al portapapeles',
      duration: 3,
      style: ToastStyle.flat,
    );
  }
}

/// Ventanita de navegador con tarjetas de colores
class _MiniBrowser extends StatelessWidget {
  const _MiniBrowser();

  @override
  Widget build(BuildContext context) {
    final List<Color> browserButtonColor = [
      Colors.redAccent,
      Colors.yellowAccent,
      Colors.green,
    ];

    return Container(
      width: 78,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior con 3 puntos
          Container(
            height: 10,
            color: Theme.of(context).colorScheme.secondary,
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: List.generate(
                3,
                (index) => Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: browserButtonColor[index],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Cuadrícula tipo masonry
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Tile(color: Color(0xFF4FD1B5), height: 20),
                      SizedBox(width: 4),
                      _Tile(color: Color(0xFFA78BFA), height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Tile(color: Color(0xFFFF8A7A), height: 12),
                      SizedBox(width: 4),
                      _Tile(color: Color(0xFF6CB6FF), height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
