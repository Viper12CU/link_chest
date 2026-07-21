# AGENTS.md

## Project

`link_chest` — Flutter mobile app for collecting and organizing links. Single package, not a monorepo.

## Quick commands

```
flutter analyze
flutter test
flutter run
```

## Architecture

**Atomic design** for widgets:

```
lib/widgets/
  atoms/       → small, reusable UI pieces (e.g., CategoryDrawerItem)
  molecules/   → composed from atoms (e.g., CategoryItemsGroup)
  organisms/   → full UI sections (e.g., CategoryDrawer)
  templates/   → layout shells (e.g., CategoryTemplate)
  pages/       → screen-level widgets (e.g., CategoryPage)
```

Providers live in `lib/providers/`. Theme lives in `lib/utils/theme.dart`.

## State management

Provider with `ChangeNotifier`. Single provider registered in `main.dart`:
- `CategorySelectedProvider` — tracks selected category index.

## Gotchas

- **`widget_test.dart`** is the default counter test. It will fail. Delete or rewrite before running `flutter test`.
- **UI strings are in Spanish** (e.g., "Nuevo link", "Agregar categoría"). Maintain this convention for new UI.
- **`sqlite3`** is in `pubspec.yaml` but not yet imported anywhere. Database layer is not started.
- **Theme** uses `Poppins` font family. Use `Theme.of(context)` — do not hardcode colors.
- **`custom_clippers`** package is used for the wave clipper in `CategoryDrawer` header.
- Navigation uses `Navigator.pushReplacement` (not named routes or go_router).
- **`share_plus`** is used for sharing links. Requires full app restart (not hot reload) to load the native plugin.
- **`CardMenu`** (`lib/widgets/molecules/link_card_menu.dart`) defines `MenuAction` enum with 5 actions: copy, share, lock, move, delete. Each has a handler in `CategoryTemplate` (currently `debugPrint` stubs).
- **`LinkCard`** (`lib/widgets/organisms/link_card.dart`) composes `CardMenu` and accepts callbacks: `onOpen`, `onCopy`, `onShare`, `onLock`, `onDelete`, `onMoveTo`.
