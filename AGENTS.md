# Agents

This repository owns only the EndlessNet Flutter Web admin console.

- Source is in `app`.
- Pinned backend contracts are in `contracts`.
- Generated output is written to `dist` and must not be committed.
- Do not inspect, build or test the EndlessNet Go backend for frontend-only
  changes. Validate the pinned OpenAPI contract and use mocks from the
  contract instead.

Required checks:

```powershell
Set-Location app
flutter analyze
flutter test
Set-Location ..
./scripts/build-pages-admin.ps1 -OutputPath dist -Clean -Standalone `
  -ApiBaseUrl https://api.endlessnet.ru `
  -SiteRoot https://endlessnet.ru/
```

API changes start in the producer OpenAPI document. Update the pinned contract
only after the backend contract change is reviewed and versioned.
