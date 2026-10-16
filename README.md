# Starfall

A small Flutter arcade shooter for Android. Drag across the play field to steer
your ship; its cannons fire automatically. Destroy incoming ships, protect your
hull, and redeploy after a run ends.

## Run locally

```sh
flutter pub get
flutter run
```

## Checks and release build

```sh
flutter analyze
flutter test
flutter build apk --release
```

The release APK is written to
`build/app/outputs/flutter-apk/app-release.apk`. The GitHub Actions workflow
builds this APK on pushes to `main` and on manual runs; download it from the
workflow run's **Artifacts** section.