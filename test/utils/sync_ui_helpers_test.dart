import 'package:flutter_test/flutter_test.dart';
import 'package:link_chest/utils/shared/sync_ui_helpers.dart';

void main() {
  group('humanSyncError', () {
    test('traduce código 23* (violación de restricciones)', () {
      expect(
        humanSyncError(
          'PostgrestException(message: Duplicate key, code: 23505, details: null, hint: null)',
        ),
        'El servidor rechazó este cambio porque no cumple las reglas de datos',
      );
      expect(
        humanSyncError('PostgrestException(23503): FK violation'),
        'El servidor rechazó este cambio porque no cumple las reglas de datos',
      );
    });

    test('traduce 42501 (sin permiso)', () {
      expect(
        humanSyncError(
          'PostgrestException(message: RLS, code: 42501, details: null, hint: null)',
        ),
        'No tienes permiso para este cambio',
      );
      expect(
        humanSyncError('PostgrestException(42501): denied'),
        'No tienes permiso para este cambio',
      );
    });

    test('fallback genérico sin código o con código desconocido', () {
      expect(humanSyncError('boom'), 'No se pudo sincronizar');
      expect(humanSyncError(''), 'No se pudo sincronizar');
      expect(
        humanSyncError(
          'PostgrestException(message: x, code: 500, details: null, hint: null)',
        ),
        'No se pudo sincronizar',
      );
    });

    test('ignora code: null', () {
      expect(
        humanSyncError(
          'PostgrestException(message: x, code: null, details: null, hint: null)',
        ),
        'No se pudo sincronizar',
      );
    });
  });

  group('relativeSyncTime', () {
    test('null o vacío → aún no sincronizado', () {
      expect(relativeSyncTime(null), 'Aún no se ha sincronizado');
      expect(relativeSyncTime(''), 'Aún no se ha sincronizado');
      expect(relativeSyncTime('no-es-fecha'), 'Aún no se ha sincronizado');
    });

    test('menos de 1 min → Hace un momento', () {
      final iso = DateTime.now().toUtc().toIso8601String();
      expect(relativeSyncTime(iso), 'Hace un momento');
    });

    test('minutos', () {
      final iso = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .toUtc()
          .toIso8601String();
      expect(relativeSyncTime(iso), 'Hace 5 min');
    });

    test('horas', () {
      final iso = DateTime.now()
          .subtract(const Duration(hours: 3))
          .toUtc()
          .toIso8601String();
      expect(relativeSyncTime(iso), 'Hace 3 h');
    });

    test('ayer (1 día)', () {
      final iso = DateTime.now()
          .subtract(const Duration(days: 1))
          .toUtc()
          .toIso8601String();
      expect(relativeSyncTime(iso), 'Ayer');
    });

    test('días', () {
      final iso = DateTime.now()
          .subtract(const Duration(days: 3))
          .toUtc()
          .toIso8601String();
      expect(relativeSyncTime(iso), 'Hace 3 días');
    });
  });
}
