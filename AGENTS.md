# AGENTS.md

## Project

`link_chest` — Flutter mobile app for collecting and organizing links. Single package, not a monorepo.

## Quick commands

```
flutter analyze
flutter test
dart run flutenv run # injects .env as --dart-define (required for Supabase config)
dart run flutenv build apk --release
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
Config lives in `lib/core/config/app_config.dart`; secure storage adapters in `lib/core/storage/`.

## State management

MultiProvider with `ChangeNotifier` registered in `main.dart`:
- `CategorySelectedProvider` — tracks selected category index and persists selection.
- `CategoryProvider` — manages categories lifecycle and persistence.
- `LinkProvider` — manages links CRUD and filtering.
- `VersionProvider` — app version and update status.
- `OnboardingProvider` — tracks first-time user tour status.

Auth state does **not** live in a provider: `AuthService` (`lib/services/auth_service.dart`) is a
singleton over Supabase Auth and `AuthGate` (`lib/widgets/organisms/auth_gate.dart`) is the
reactive bridge via `userChanges` / `pendingUserChanges`.

## Authentication (Supabase)

- `AuthService` wraps `supabase_flutter`: email+password, native Google (`google_sign_in` →
  `signInWithIdToken`), email verification, password reset/change, account deletion.
- **Email confirmation**: currently `mailer_autoconfirm: true` (debug convenience), so `signUp`
  returns a session directly. With autoconfirm **OFF** (production link flow), `signUp` returns
  **no session**: `AuthService` keeps the account in `pendingUser`, `AuthGate` renders
  `VerifyEmailPage`, and "Ya verifiqué mi correo" retries `signInWithPassword` (fails with
  `email_not_confirmed` until the user opens the link).
- **Config** (`AppConfig`, resolved from `--dart-define` first, then `.env`):
  `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_SERVER_CLIENT_ID` (Web client id).
  iOS Google client id not configured (out of scope); `GOOGLE_CLIENT_ID` resolve empty.
- **Session persistence** uses `SecureLocalStorage` (`flutter_secure_storage`), not
  SharedPreferences.
- **Account deletion** calls the `delete-account` Edge Function (`supabase/functions/delete-account`),
  because `auth.admin.deleteUser` requires the service_role key.
- **Google provider** must be enabled in the Supabase dashboard (Client ID = Web client id +
  Client secret + "Skip nonce check"). Same Google Cloud project needs an **Android** client
  with package `com.example.link_chest` + debug SHA-1, or native `google_sign_in` fails.

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
- **Supabase default SMTP only emails project team members, 2/hour.** Real users need a custom SMTP provider.
