# MemoriesApp

A Flutter app (pre-development scaffold). Product core **TBD** — see [PLAN.md](./PLAN.md).

## Status

- [x] Git repo initialized (`main`) + GitHub remote
- [x] Project config scaffolded (`.gitignore`, `analysis_options.yaml`)
- [ ] Flutter SDK + Dart installed
- [ ] `flutter create` scaffold (platform dirs, no feature screens)
- [ ] Firebase project + CLI configured
- [ ] Product core decision (drives the Feature Map in PLAN.md §3)

## Skills & conventions

This repo follows `PLAN.md` (architecture, naming, lint, Definition of Done).
Hermes auto-loads the relevant `flutter/*` and `superpowers/*` skills system-wide;
project-specific rules live in [`.hermes.md`](./.hermes.md).

## Setup (once the SDK is installed)

```bash
flutter pub get
flutter analyze
flutter test
```
