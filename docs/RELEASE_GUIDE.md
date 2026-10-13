# Run and release

## Current iOS target

Verified toolchain: Flutter 3.44.4, Dart 3.12.2, local Xcode with an iPhone 18 Pro / iOS 27.0 simulator. The app uses its existing bundle identifier, `com.example.iosStyleJournal`; only the display name and branding changed.

```sh
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <simulator-id>
```

The device-specific `flutter run -d 9698B3A4-594A-4AE3-BD6C-6B7E83AC15F7 --no-resident` compiled, installed, and launched the application. A generic `flutter build ios --simulator` attempt failed because this Flutter/Xcode combination passed the combined architecture string `arm64 x86_64` to Flutter's thinning step despite both architectures existing in the engine. Use a specific simulator target for the checked debug workflow; do not mistake this for a successful generic simulator build.

For physical devices and archives, open `ios/Runner.xcworkspace`, choose your signing team and a unique bundle identifier if distribution is intended, and use the appropriate device/archive destination. `flutter build ipa --release` requires configured signing and distribution credentials; release signing, TestFlight and App Store distribution were not performed.

## Other platforms

Only iOS has a native platform folder. First back up the complete source and any custom native configuration. Generate only the platform needed, review new files, then test on the relevant host:

```sh
flutter create --platforms=android .
# or --platforms=web / macos / windows / linux on a suitable host
```

This generates the selected runner and may update project metadata. Do not blindly regenerate iOS or run an all-target command over custom files. No Android/iOS universal installer exists.

Once the corresponding folders and SDKs are present:

| Target | Command | Requirements / current status |
| --- | --- | --- |
| Android APK | `flutter build apk --release` | Android SDK; not generated or tested |
| Android AAB | `flutter build appbundle --release` | Android SDK and release signing; not tested |
| Web | `flutter build web` | Web target; not generated or tested |
| macOS | `flutter build macos --release` | macOS host/Xcode; not generated or tested |
| Windows | `flutter build windows --release` | Windows host/toolchain; not generated or tested |
| Linux | `flutter build linux --release` | Linux host/toolchain; not generated or tested |

Desktop/window and web behavior currently have shared-widget layout tests, not native build certification. Future distribution requires each platform's launcher assets and signing/packaging. Do not submit hypothetical build outputs.

## Preview captures

```sh
flutter test test/screenshots_test.dart --dart-define=CAPTURE_SCREENS=true
```

This opt-in test writes real Flutter-rendered screen previews at phone and desktop logical sizes. It loads fonts from the local Flutter SDK (FLUTTER_ROOT or the documented local path); it does not bundle system fonts into the app. The test is skipped in normal CI. These previews are labeled separately from the native simulator capture.

## Photo-picker integration

The sole added functionality dependency is [Flutter file_selector](https://pub.dev/packages/file_selector). The current iOS runner successfully builds with its plugin. Choose photo opens a system image-file chooser, not direct camera or Photos-library access; no Photos usage permission is claimed. Manually check selection, cancellation, invalid images and errors on a native device before submission. A future sandboxed macOS runner needs the user-selected read entitlement documented by that package; other native targets still need generation and verification.

The multimedia upgrade reuses that same image-file chooser for avatars and entry photos. Drawing export stays in memory and needs no extra permission. No Info.plist or Android permission change is required for the implemented file-import workflow. Direct Photos/camera integration is a separate future feature.
