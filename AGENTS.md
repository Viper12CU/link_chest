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

MultiProvider with `ChangeNotifier` registered in `main.dart`:
- `CategorySelectedProvider` — tracks selected category index and persists selection.
- `LoginProvider` — tracks authentication state and sessions.
- `CategoryProvider` — manages categories lifecycle and persistence.
- `LinkProvider` — manages links CRUD and filtering.
- `VersionProvider` — app version and update status.
- `OnboardingProvider` — tracks first-time user tour status.

## Database & Persistence

- Custom SQLite database via `DatabaseHelper` (`lib/database/database.dart`, `lib/database/database_helper.dart`).
- DAOs: `CategoryDao`, `LinkDao`.
- Models: `CategoryModel`, `LinkModel`.
- Initialized on app boot: `await DatabaseHelper().init()`.

## Pages & Navigation

Screen-level widgets in `lib/widgets/pages/`:
- `SplashPage` — entry point / splash screen and initial routing check.
- `LoginPage` — authentication screen with animated transitions via `LoginTemplate` (`LoginForm`, `SignUpForm`).
- `CategoryPage` — main screen showing link categories and links.
- `VaultPage` — protected/locked links area.
- `ProfilePage` — user settings, sessions, stats, and export.

Navigation uses `Navigator.pushReplacement` / `Navigator.push` with `navigatorKey`.

## Gotchas

- **`widget_test.dart`** is the default counter test. It will fail. Delete or rewrite before running `flutter test`.
- **UI strings are in Spanish** (e.g., "Nuevo link", "Agregar categoría", "Iniciar sesión"). Maintain this convention for new UI.
- **Theme** uses `PlusJakartaSans` and `Sora` fonts (Light) and `Poppins` (Dark). Always use `Theme.of(context)` and `theme.colorScheme` — do not hardcode colors. Remember contrast when placing elements inside colored containers (e.g. `onPrimary` on `primary`, `onSecondary` on `secondary`).
- **FeatureDiscovery** wraps `App()` in `main.dart` for guided onboarding tooltips.
- **`custom_clippers`** package is used for custom wave clipping in headers.
- **`share_plus`** is used for sharing links. Requires full app restart (not hot reload) to load the native plugin.
- **`CardMenu`** (`lib/widgets/molecules/link_card_menu.dart`) defines `MenuAction` enum with 5 actions: copy, share, lock, move, delete.
- **`LinkCard`** (`lib/widgets/organisms/link_card.dart`) composes `CardMenu` and accepts callbacks: `onOpen`, `onCopy`, `onShare`, `onLock`, `onDelete`, `onMoveTo`.
