# ReLog2

Travel-album app — every memory is a map pin. Tier 1 MVP built.
See [PLAN.md](./PLAN.md) for architecture + feature map.

## Status

- [x] Git repo (`main`) + GitHub remote
- [x] Flutter SDK 3.44+ + deps
- [x] Product core locked (PLAN.md §3)
- [x] Supabase all-in (auth + data + storage)
- [x] R2 photo storage (S3v4)
- [x] 5 features: auth, albums, map, capture, notes
- [x] `flutter analyze` = 0 errors
- [ ] Supabase schema (paste `supabase/schema.sql` once in SQL Editor)

## Setup

```bash
flutter pub get
flutter analyze                         # 0 errors
cp scripts/run_dev.sh.sample scripts/run_dev.sh  # fill R2 keys
./scripts/run_dev.sh                    # build + run
```
