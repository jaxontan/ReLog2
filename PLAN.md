# ReLog2 — Build Plan

> Status: **Foundations locked. Product core = TBD (jaxon will define).** Do not run `flutter create` or write feature code until the core is confirmed and the Feature Map (§3) is filled in.

---

## 0. Environment Setup (pre-project, not yet executed)

These are ONE-TIME setup steps. They install the toolchain but do **not** start the project.

- [ ] **Flutter SDK + Dart** — not installed on this machine yet.
      Install via `flutter` official archive or `git clone` + `flutter doctor`. Target stable channel.
- [ ] **Firebase CLI + FlutterFire CLI** — `npm i -g firebase-tools`, then `dart pub global activate flutterfire_cli`.
- [ ] **IDE** — VS Code with `Flutter` + `Dart` extensions (or Android Studio). Optional: enable the `dart`/`flutter-driver` MCP server for the `flutter-add-integration-test` skill.
- [ ] **Firebase project** — create project in Firebase console; register app IDs for the platforms we ship (Android / iOS / Web).
- [ ] **Enable Firebase services** — Authentication (email+password + Google), Cloud Firestore, Cloud Storage (for media), Firebase Crashlytics.

---

## 1. Architecture Standard (LOCKED)

Follows the Flutter team's recommended layered MVVM + the `flutter-apply-architecture-best-practices` skill.

### 1.1 Directory structure — Feature-First
```
lib/
├── main.dart                      # entry: init Firebase, set up Riverpod + go_router
├── app/
│   ├── router/                    # go_router config, route definitions
│   └── theme/                     # app theme / design tokens
├── core/                          # cross-feature: errors, result types, utils, di
│   ├── error/                     # Failure, Result<E>
│   └── di/                        # Riverpod provider bindings (optional)
└── features/
    └── <feature_name>/
        ├── data/
        │   ├── models/            # raw API/Firestore models (freezed / json_serializable)
        │   ├── services/          # stateless: wrap Firebase SDK (AuthService, FirestoreService, StorageService)
        │   └── repositories/      # consume services -> domain models, caching, offline
        ├── domain/                # pure entities + (optional) use cases
        └── presentation/
            ├── views/             # screens & pages (lean widgets)
            ├── widgets/           # reusable, small StatelessWidgets
            └── view_models/       # Riverpod StateNotifier / Notifier (+ freezed state)
```
Layer flow: **View → ViewModel → Repository → Service → Firebase SDK**.

### 1.2 Naming & lint conventions (LOCKED)
- `analysis_options.yaml` extends `package:flutter_lints` (strict). Enforce via CI.
- UpperCamelCase: classes, enums, extensions, typedefs (`class MemoryCard {}`).
- lowerCamelCase: variables, params, methods (`void saveMemory() {}`).
- snake_case: **all** file & directory names (`memory_repository.dart`, `auth_feature/`).

### 1.3 Widget optimization rules (LOCKED)
- Use `const` constructors whenever properties are static (build-time compile, skips rebuild).
- No `build()` method > ~100 lines — split into small `StatelessWidget` subclasses.
- Use `SizedBox` for spacing/spacing-only sizing, not `Container`.
- Long/unknown lists → `ListView.builder` / `GridView.builder` (lazy). Never eager `ListView`.

### 1.4 State & routing
- **State:** Riverpod — view models are `StateNotifier`/`Notifier`/`AsyncNotifier` (compile-safe, DI-free).
- **Routing:** `go_router` — declarative routes, deep links, shell routes for tab nav.

---

## 2. Skill Stack (INSTALLED ✓)

These are loaded into `~/.hermes/skills` (and the Ponytail plugin is enabled). They trigger automatically when a task matches.

### 2.1 Flutter skill pack (10) — `flutter/*`
| Skill | Use when |
|---|---|
| `flutter-apply-architecture-best-practices` | scaffolding a new feature / refactoring |
| `flutter-setup-declarative-routing` | building `go_router` routes |
| `flutter-implement-json-serialization` | defining Firestore models |
| `flutter-add-widget-test` | unit/widget tests for a widget |
| `flutter-add-integration-test` | end-to-end flows (needs flutter-driver MCP) |
| `flutter-fix-layout-issues` | layout overflow / render errors |
| `flutter-build-responsive-layout` | tablet/phone adaptive layouts |
| `flutter-setup-localization` | i18n |
| `flutter-use-http-package` | REST calls outside Firebase |
| `flutter-add-widget-preview` | widget previews |

### 2.2 Ponytail plugin (enabled) — lean discipline
- Always-on "lazy senior dev": before writing code, check the YAGNI ladder (need it? exists? stdlib? native? dep? one-liner? minimum). Keeps the 100-line `build()` rule and `const` rules honest. Commands: `/ponytail`, `/ponytail-review`, `/ponytail-audit`.

### 2.3 Superpowers skill pack (14) — `superpowers/*` — SDLC workflow
`using-superpowers` → `brainstorming` → `writing-plans` → `subagent-driven-development` / `executing-plans` → `test-driven-development` → `requesting-code-review` → `finishing-a-development-branch`. Plus `systematic-debugging`, `verification-before-completion`, `using-git-worktrees`.

---

## 3. Feature Map (TBD — fill once jaxon defines the core)

> Pending product core decision. When defined, enumerate features here, each as:
> `feature_name` → screens, view models, repositories, services, Firestore collections.

Placeholder skeleton (will be replaced):
- `auth` — login / register / password reset (Firebase Auth).
- `memories` — CRUD on memory entities (Firestore), media upload (Storage).
- `home` / `profile` — shell + navigation.

---

## 4. Development Workflow (LOCKED)

1. **Brainstorm** (`superpowers:brainstorming`) — pin the feature's spec in chunks, get sign-off.
2. **Plan** (`superpowers:writing-plans`) — bite-sized tasks with exact file paths + verification.
3. **TDD** (`superpowers:test-driven-development`) — RED → GREEN → REFACTOR per feature.
4. **Lean check** (`/ponytail-review`) — before merge, delete over-built code.
5. **Review** (`superpowers:requesting-code-review`) — spec + quality gate.
6. **Branch** (`superpowers:using-git-worktrees`) — isolate each feature on its own branch.
7. **Finish** (`superpowers:finishing-a-development-branch`) — merge/PR, clean up.

---

## 5. Quality Gates (Definition of Done)
- `flutter analyze` clean (strict lints).
- `flutter test` green (widget + unit; integration for critical flows).
- Every feature: ViewModel covered by a test, Repository covered by a test.
- No `build()` > 100 lines; `const` used where static; lists lazy.
- Ponytail review passed (no over-engineering).

---

## 6. Next Steps
- [ ] **jaxon defines the product core** → I fill §3 Feature Map.
- [ ] On core confirmation: run §0 environment setup.
- [ ] Then scaffold `lib/` per §1 and build feature-by-feature per §4.
