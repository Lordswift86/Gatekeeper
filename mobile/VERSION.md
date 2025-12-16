# Mobile Apps Versioning

## Versioning Scheme

We follow [Semantic Versioning](https://semver.org/) for our Flutter applications.

**Format**: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Incompatible API changes or major redesigns
- **MINOR**: New features added in a backward-compatible manner
- **PATCH**: Backward-compatible bug fixes
- **BUILD**: Incremental build number (increases with each build)

## Version History

### Estate Admin App

| Version | Build | Date | Changes |
|---------|-------|------|---------|
| 1.1.0 | 2 | 2025-12-16 | YourNotify SMS integration, dual-provider SMS broadcasting |
| 1.0.0 | 1 | - | Initial release |

### Resident App

| Version | Build | Date | Changes |
|---------|-------|------|---------|
| 1.1.0 | 2 | 2025-12-16 | Backend SMS improvements (kept in sync with estate admin) |
| 1.0.0 | 1 | - | Initial release |

## Building APKs

### Release Build
```bash
# Navigate to app directory
cd mobile/estate_admin  # or mobile/resident

# Build release APK
flutter build apk --release

# Output location
# build/app/outputs/flutter-apk/app-release.apk
```

### Renaming APKs
After building, rename the APK to include version information:
```bash
# Example
mv app-release.apk gatekeeper-estate-admin-v1.1.0-build2.apk
```
