## Project handover documentation (Flutter)

### Project overview

- **Project name**: `sc_appframework`
- **Repository type**: Flutter **plugin/package** (reusable framework utilities), with an `example/` Flutter app
- **Business purpose / goal**:
  - Provide a small “app framework” library for SymblCrowd apps: network layer, auth service wrapper, offline caching, internal storage utilities, logging, update handling, and an Android broadcast bridge.
- **Target platforms**:
  - **Flutter**: primarily **Android + iOS** (plugin has `android/` and `ios/` implementations)
  - **Web/Desktop**: not explicitly supported (contains `dart:io` usage in core modules; platform channel features are mobile-focused)
- **Current status**:
  - **Library in use / evolving** (versioned in `pubspec.yaml` as `0.4.5`)
  - The `example/` app is a minimal template and currently has outdated SDK constraints (see “Known technical debt”).

### What this repo contains (at a glance)

- **Flutter package** exporting:
  - `SCNetworkApi` (HTTP client + response mapping + caching/queueing)
  - `ScAuthService` (auth-related endpoints, special status code handling)
  - `SCSharedPrefStorage`, `SCInternalStorage` (key-value + file storage)
  - `SCOfflineDataCache` (write JSON “data” payloads to disk; read back and deserialize)
  - `SCUpdate` (check/download/install app updates; APK download/install flow)
  - `SCLogger` (CSV-based file logger)
  - `SCBroadcast` (Android broadcast via MethodChannel)
  - Various models (`Failure`, `SingleResponse`, `ListResponse`, …) and small utilities.

---

## Technical stack

### Flutter & Dart

- **Dart SDK constraint (package)**: `>=3.2.0 <4.0.0` (see root `pubspec.yaml`)
- **Flutter constraint (package)**: `>=1.20.0` (very broad; practically you need a Flutter version that includes **Dart 3.2+**)

### Key dependencies (root `pubspec.yaml`)

- **`http`**: REST API requests (`SCNetworkApi`)
- **`dartz`**: functional error handling via `Either<Failure, T>`
- **`shared_preferences`**: persistent key-value storage (`SCSharedPrefStorage`)
- **`hive_flutter`**: local storage used for GET response cache (`SCNetworkApi` GET cache box)
- **`path_provider` / `path`**: filesystem paths and file operations
- **`intl`**: date/time formatting utilities (exported via utils)
- **`geolocator` / `permission_handler` / `device_info_plus`**: mobile device utilities (exported utils; used by consumers)
- **`csv`**: CSV logging (`SCLogger`)
- **`share_plus`**: sharing utilities (exported)
- **`open_filex`**: opening downloaded APK / file (`SCUpdate.installUpdate`)
- **`enum_to_string`**: serializing enums for cached requests

### State management

- **None enforced**: this is a library/plugin, not an app. Consumers can use Bloc/Provider/Riverpod/etc.

### Architecture / patterns

- **“Utility framework” style**, not Clean Architecture:
  - Singleton-like services (e.g. `SCNetworkApi()` factory returns one instance)
  - Models with `fromJson` parsing
  - Reusable helper classes grouped by concern (`network/`, `services/`, `storage/`, `utils/`)
- **Error handling**:
  - Most API-facing methods return `Either<Failure, T>`
  - `Failure` wraps `(http statusCode, internalStatusCode, errorMessage)`
- **Backend response convention**:
  - Success: HTTP 200 and JSON field `status == 1`
  - Data: nested under `data` by default (configurable via `SCNetworkApi.jsonDataLevel`)

---

## Project structure

### Root layout

- **`lib/sc_appframework.dart`**: package entrypoint, exports all public API and defines the MethodChannel bridge.
- **`lib/src/`**: internal implementation, grouped by domain:
  - **`broadcast/`**: Android broadcast helper via platform channel
  - **`network/`**: HTTP wrapper, multipart, offline cache, update flows
  - **`services/`**: higher-level domain services (`ScAuthService`)
  - **`storage/`**: shared prefs + internal file storage
  - **`models/`**: request/response models and response mappers
  - **`utils/`**: small helper utilities (date/file/share/location/etc.)
- **`android/`**: Android plugin implementation (Kotlin)
- **`ios/`**: iOS plugin implementation (Swift/ObjC wrapper)
- **`example/`**: sample Flutter app consuming the plugin via path dependency
- **`test/`**: basic plugin test scaffold

### Key entry points / important files

- **Public API**: `lib/sc_appframework.dart`
- **HTTP client**: `lib/src/network/sc_network_api.dart`
- **Auth service**: `lib/src/services/sc_auth_service.dart`
- **Update flow**: `lib/src/network/sc_update.dart`
- **Offline caching**: `lib/src/network/sc_offline_data_cache.dart`
- **Android broadcast bridge**: `lib/src/broadcast/sc_broadcast.dart` + `android/.../ScAppframeworkPlugin.kt`

### Conventions & patterns

- **Singleton services**: `SCNetworkApi()`, `SCSharedPrefStorage()`, `SCUpdate()`
- **Routes are strings** (defaults can be overridden per call)
- **Serialization is callback-based**: caller passes `serializer: (json) => Model.fromJson(json)`
- **ResponseType**: `SINGLE` vs `LIST` drives parsing via `SingleResponse` / `ListResponse`

---

## Build & Run (local development)

### Prerequisites

- **Flutter SDK** installed (recommended: current stable; must include **Dart 3.2+** to satisfy the package constraint)
- Platform toolchains (if you build/run the example app):
  - **Android**: Android Studio + SDK + emulator/device
  - **iOS** (macOS only): Xcode + CocoaPods (`pod`)

### Initial setup (package)

From repository root:

```bash
flutter --version
flutter pub get
flutter analyze
flutter test
```

### Running the example app

```bash
cd example
flutter pub get
flutter run
```

#### Important note: `example/` SDK constraint mismatch

`example/pubspec.yaml` currently declares:

- `sdk: ">=2.12.0 <3.0.0"`

This conflicts with the plugin’s Dart 3.2 requirement. To run the example with current Flutter/Dart, update the example’s SDK constraint to match the root (see “Known technical debt”).

### Debug/Release/Flavors

- **No flavors configured** in this repository by default.
- Standard Flutter modes apply:
  - Debug: `flutter run`
  - Release build (example app): `flutter build apk --release` / `flutter build ios --release`

---

## Configuration & environments

### Environments (Dev/Staging/Prod)

- **Not managed in this repo** (this is a plugin, not a full app).
- Consumers typically configure:
  - **API base URL** via `SCNetworkApi().init(baseUrl: ...)`
  - **Auth headers/tokens** by setting `SCNetworkApi().headers = {...}` or `addToHeader(...)`

### Relevant configuration code paths

- **Base URL validation**: `SCNetworkApi.baseUrl` only accepts values starting with `http:` or `https:`
- **Timeouts**: `SCNetworkApi.timeoutSeconds` (default 120s; per request override supported)
- **Data nesting**: `SCNetworkApi.jsonDataLevel` (default `["data"]`)
- **Request queueing**: `SCNetworkApi.request(..., cacheRequest: true, retry: true, requestId: ...)`
- **GET response caching**: `SCNetworkApi.request(..., enableGetCache: true)` uses Hive box `SCConstants.HIVE_BOX_GET_CACHE`

### Feature flags

- None built-in.

### Secrets / API keys

- **No secrets in repo**.
- Store secrets in the **consuming app** using platform-specific secret management (CI secrets, keystore/keychain, encrypted storage, etc.). Do not hardcode in this plugin.

---

## Backend & third-party integrations

### APIs

The networking layer assumes a backend with:

- HTTP status code **200** for success
- JSON field **`status`** equals **1** for success (internal status)
- JSON field **`data`** contains payload (default)

### Authentication

`ScAuthService` provides:

- **`loginQr`**: POST `/auth/login-qr` with `{ qr_code_data, pin }`
- **`loginPin`**: POST `/auth/login-pin` with `{ username, pin }`
- **Special internal status handling**:
  - **212**: password expired → returns `LoginResult` with `specialStatusCode = 212` and (best-effort) parsed `AuthAccount`
  - **213**: 2FA required → returns `LoginResult` with `specialStatusCode = 213` and (best-effort) parsed `AuthAccount`
- **`changePassword`**: POST `/auth/accounts/change-password`
- **`changePin`**: POST `/auth/accounts/change-pin`
- **`uploadDeviceLogs`**: MULTIPART `/auth/apis/device-logs/upload` (field name `file`)

### Update service

`SCUpdate`:

- Calls GET `/auth/apps/check` with `version_code`
- If update available, downloads from `client_url` and saves `app.apk`
- Installs via `OpenFilex.open(path)`

Notes:

- The current implementation is **Android-centric** (APK download/install).

### Push notifications / Firebase / Supabase / AWS

- No integrations present in this repo.

---

## Important business logic (domain behavior)

### Network request lifecycle (`SCNetworkApi`)

- Builds URL: `baseUrl + route + queryParams`
- Supports:
  - query params, paging (`page`, `per_page`)
  - searching (`search`, `search_in`)
  - filter entries (`filter=key,value`)
  - repeatable params
- Failure cases:
  - Non-200 HTTP codes → `Failure(statusCode, status??0, response.body)`
  - 200 but `status != 1` → same `Failure` path
  - JSON decode errors → `SCConstants.JsonFailure`
  - timeout/network exceptions → `SCConstants.NetworkFailure` with `errorMessage` set
- Optional behaviors:
  - **retry**: re-attempt once after 5 seconds if result is Left
  - **cacheRequest**: serialize request to SharedPreferences so it can be replayed later via `deSerializeRequests()`
  - **enableGetCache**: store GET responses in Hive; on request exception it can serve cached response if present

### Offline data cache (`SCOfflineDataCache`)

- Stores `json['data']` as `"<model>.json"` in app documents directory.
- Reads and optionally deserializes into `SingleResponse`/`ListResponse` using provided serializer.

### Logging (`SCLogger`)

- Stores logs in `logs.csv` in internal storage.
- Filtered by `SCLogger.logLevel`.
- Useful for `uploadDeviceLogs()` (consumer must supply file paths; `SCLogger.logFile.path` can be one of them).

### Android broadcasts (`SCBroadcast`)

- Sends broadcasts to Android via MethodChannel method `sendBroadcast`.
- Convenience: `disableSCLauncherRestart(packageName)` sends action `de.symblcrowd.sc_launcher.broadcast.ABORT`.

---

## Testing

### Test types

- **Unit tests**: minimal scaffold only
- **Widget/Integration tests**: none in this repo

### Current coverage (rough)

- Very low. The existing `test/sc_appframework_test.dart` only sets up a mock MethodChannel handler.

### Running tests

From repo root:

```bash
flutter test
```

---

## Deployment & release

### CI/CD

- **No CI pipelines found** (no GitHub Actions / GitLab CI / fastlane in this repo).

### Publishing / distribution

- This is a Flutter package; typical release options:
  - **Internal Git dependency** (recommended for private use)
  - Publish to **pub.dev** (requires cleanup of metadata like `homepage`, iOS podspec fields, etc.)

### Versioning

- Root `pubspec.yaml` version: **0.4.5**
- Changelog exists in `CHANGELOG.md` and follows SemVer-style entries.

### Suggested release flow (if used as internal dependency)

- Tag releases in git (e.g. `v0.4.6`)
- Update `pubspec.yaml` version and `CHANGELOG.md`
- Consumers pin a git tag/commit in their `pubspec.yaml`

---

## Additional knowledge & pointers

### Where implicit knowledge currently lives

- **Routes and backend contracts** are embedded as defaults in:
  - `lib/src/services/sc_auth_service.dart` (auth endpoints and status code interpretation)
  - `lib/src/network/sc_update.dart` (update check/download assumptions)
  - `lib/src/network/sc_network_api.dart` (status/data conventions)

### Useful files to read first as a new maintainer

- `lib/sc_appframework.dart`
- `lib/src/network/sc_network_api.dart`
- `lib/src/services/sc_auth_service.dart`
- `lib/src/network/sc_update.dart`
- `lib/src/models/*` (response parsing and models)

