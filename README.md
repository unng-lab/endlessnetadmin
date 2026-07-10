# EndlessNet admin console

This repository owns the Flutter Web admin console source, its frontend API
consumer contract, tests, build and GitHub Pages deployment.

- Flutter source: `app/`
- Pinned producer contracts: `contracts/`
- Reproducible Pages build: `scripts/build-pages-admin.ps1`
- Generated output: `dist/` (not committed)

Run locally:

```powershell
Set-Location app
flutter pub get
flutter analyze
flutter test
Set-Location ..
./scripts/build-pages-admin.ps1 -OutputPath dist -Clean -Standalone `
  -ApiBaseUrl https://api.endlessnet.ru `
  -SiteRoot https://endlessnet.ru/
```

The backend repository owns the producer OpenAPI document. This repository
pins a reviewed version and verifies that every API operation used by the UI
exists in that contract.
