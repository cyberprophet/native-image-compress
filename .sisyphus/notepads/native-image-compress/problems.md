# Native Image Compress - Problems & Blockers

## Current Blockers
- Android build blocked: SDK directory not writable (`/usr/lib/android-sdk`), Gradle fails installing NDK.
- iOS/macOS builds require macOS with Xcode; cannot verify on Linux host.
- Windows build requires Windows host; cannot verify on Linux.
- Integration tests cannot run here (no supported device; web devices unsupported for integration_test).

## Resolved Issues

## Open Questions

## Dependency Tracking
- Task 1 → Task 2 → Task 3 → Tasks 4-7 (parallel) → Task 9 → Task 10
