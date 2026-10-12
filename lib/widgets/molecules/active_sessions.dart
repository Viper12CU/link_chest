import 'package:flutter/material.dart';
import 'package:toastify_flutter/toastify_flutter.dart';

class SessionItem {
  final String id;
  final String device;
  final IconData icon;
  final String lastActivity;
  final bool isCurrent;

  const SessionItem({
    required this.id,
    required this.device,
    required this.icon,
    required this.lastActivity,
    this.isCurrent = false,
  });
}

class ActiveSessions extends StatefulWidget {
  const ActiveSessions({super.key});

  @override
  State<ActiveSessions> createState() => _ActiveSessionsState();
}

class _ActiveSessionsState extends State<ActiveSessions> {
  // Lista estática de ejemplo
  final List<SessionItem> _sessions = [
    const SessionItem(
      id: 'mobile',
      device: 'Pixel 7 · Android',
      icon: Icons.smartphone_rounded,
      lastActivity: 'Activa ahora',
      isCurrent: true,
    ),
    const SessionItem(
      id: 'web',
      device: 'Chrome · Windows',
      icon: Icons.desktop_windows_outlined,
      lastActivity: 'Hace 2 horas',
    ),
    const SessionItem(
      id: 'linux',
      device: 'Firefox · Linux',
      icon: Icons.desktop_windows_outlined,
      lastActivity: 'Hace 3 días',
    ),
  ];

  void _closeSession(SessionItem s) {
    setState(() => _sessions.removeWhere((e) => e.id == s.id));
    ToastifyFlutter.success(
      context,
      message: "Cerrada la sesión ${s.device} ",
      duration: 3,
      style: ToastStyle.flat
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasOthers = _sessions.any((s) => !s.isCurrent);
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado: etiqueta + contador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SESIONES ACTIVAS',
                style: theme.textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '${_sessions.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Tarjeta con todas las filas
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var i = 0; i < _sessions.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: theme.colorScheme.outline),
                  _SessionRow(
                    session: _sessions[i],
                    onClose: () => _closeSession(_sessions[i]),
                  ),
                ],
                if (!hasOthers) ...[
                  Divider(height: 1, color: theme.colorScheme.outline),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No hay otras sesiones abiertas. Cuando entres desde otro dispositivo, aparecerá aquí.',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.45,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onClose});

  final SessionItem session;
  final VoidCallback onClose;

  static const _line = Color(0xFF2A3443);
  static const _muted = Color(0xFF93A0B3);
  static const _live = Color(0xFF4FD1B5);
  static const _danger = Color(0xFFFF7B72);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          // Icono en recuadro
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(session.icon, size: 22),
          ),
          const SizedBox(width: 12),

          // Dispositivo + actividad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.device,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (session.isCurrent) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _live,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        session.lastActivity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: _muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Etiqueta o botón
          if (session.isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0x404FD1B5)),
              ),
              child: const Text(
                'Este dispositivo',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _live,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                side: const BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Cerrar'),
            ),
        ],
      ),
    );
  }
}
