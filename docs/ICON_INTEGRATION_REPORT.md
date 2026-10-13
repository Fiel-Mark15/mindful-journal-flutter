# Approved icon integration — October 9, 2026

## Master artwork

`assets/images/app_icon.png` is the single master, copied byte-for-byte from the supplied `Glowing Folded Leaf Emblem.png`. Original dimensions: 1254×1254, RGB PNG, no alpha. No artwork generation, cropping, background removal, recoloring, added text or replacement symbol was performed. The existing source path also updates its existing in-app asset references without changing screen code.

SHA-256: `fdd1c997152dbf85014ad251bf4709231b2402e4db372bae11ddec266671d980`.

## Configuration and generated resources

Added `flutter_launcher_icons: ^0.14.4` to dev dependencies, resolved version 0.14.4. `pubspec.lock` includes its generation-only transitive dependencies. The [package configuration](https://pub.dev/packages/flutter_launcher_icons/versions/0.14.4) is:

```yaml
flutter_launcher_icons:
  ios: true
  android: false
  image_path: "assets/images/app_icon.png"
  remove_alpha_ios: true
```

Only an iOS runner exists. No unsupported runner was created or enabled.

| Platform | Result |
|---|---|
| iOS | Generated AppIcon PNGs and valid Contents.json at `ios/Runner/Assets.xcassets/AppIcon.appiconset/`; all 25 referenced slots validated for existence, dimensions and opacity, including 1024px marketing icon. |
| Android | No Android runner/resources in this project. No legacy/adaptive icons generated; adaptive mask testing is not applicable. |
| macOS | No macOS runner/catalog; no changes. |
| Windows | No Windows runner/resource file; no changes. |
| Web | No Web runner/manifest/favicon; no changes. |

The image's complete square frame and optical padding are preserved. All native sizes are generated directly from the full-resolution master, never from small derivatives. `CFBundleDisplayName` remains Mindful Journal; bundle identifier and AppIcon catalog selection remain unchanged.

The launch storyboard already uses an 80pt branded image. Its layout, centered placement and navy background were preserved; only its existing 80/160/240px image files were refreshed from the approved source. No new splash screen was introduced.

`tools/generate_branding.py` no longer draws the obsolete notebook. It invokes the configured launcher generator and scales the existing launch-image assets from the read-only master. Flutter/Dart and macOS `sips` must be on PATH. README and the design-system branding description now identify the authoritative asset.

## Commands and validation

Executed from the project folder, with the installed Flutter/Dart SDK:

```sh
rtk proxy /opt/homebrew/share/flutter/bin/flutter clean
rtk proxy /opt/homebrew/share/flutter/bin/flutter pub get
rtk proxy /opt/homebrew/share/flutter/bin/dart run flutter_launcher_icons
rtk proxy sips -z 80 80 assets/images/app_icon.png --out ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png
rtk proxy sips -z 160 160 assets/images/app_icon.png --out ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png
rtk proxy sips -z 240 240 assets/images/app_icon.png --out ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png
rtk proxy /opt/homebrew/share/flutter/bin/dart format .
rtk proxy /opt/homebrew/share/flutter/bin/flutter analyze
rtk proxy /opt/homebrew/share/flutter/bin/flutter test --no-pub --concurrency=1
```

The initial `flutter test --concurrency=1` attempt encountered a Flutter generated Swift-package cleanup error for `ios/Flutter/ephemeral/Packages/.packages`; the test suite was rerun with `--no-pub` after dependency resolution. `flutter pub get` was also rerun after cleaning completed, ensuring regenerated configuration was present.

- Launcher generation: successful.
- Asset audit: byte-exact master, valid JSON, 25 correctly sized opaque iOS slots, three correctly sized launch images.
- Formatting: 57 Dart files, zero changes to existing code.
- Analyzer: no issues found.
- Test result: 78 tests passed; two opt-in preview tests skipped.
- Native build/launch: successful on iPhone 18 Pro / iOS 27, exit 0. Xcode build completed in 46.6s; files synced in 192ms. The built Info.plist selects AppIcon and displays Mindful Journal. Its bundled Flutter asset remains byte-exact to the approved master.

Native command executed:

```sh
rtk proxy /opt/homebrew/share/flutter/bin/flutter run -d 9698B3A4-594A-4AE3-BD6C-6B7E83AC15F7 --no-resident --no-pub
```

## Exact simulator refresh instructions

A clean rebuild/reinstall usually refreshes the icon. If the simulator still displays a cached launcher image, run the following from this project folder. The uninstall step is only necessary if the launcher remains cached:

```sh
rtk proxy /opt/homebrew/share/flutter/bin/flutter clean
rtk proxy /opt/homebrew/share/flutter/bin/flutter pub get
rtk proxy /opt/homebrew/share/flutter/bin/dart run flutter_launcher_icons
rtk proxy xcrun simctl uninstall 9698B3A4-594A-4AE3-BD6C-6B7E83AC15F7 com.example.iosStyleJournal
rtk proxy /opt/homebrew/share/flutter/bin/flutter run -d 9698B3A4-594A-4AE3-BD6C-6B7E83AC15F7 --no-resident --no-pub
```

Then return to the simulator Home screen and inspect the Mindful Journal launcher. If SpringBoard still retains the old image, shut down and boot this same simulator through Simulator/Device Hub, then reinstall. For a physical iPhone, delete the installed app and reinstall a properly signed build if needed. Physical-device signing and store distribution are not performed here.

## Manual / future platforms

Android, macOS, Windows and Web require actual runners before icon generation and native validation can be performed. When Android is added, use a reviewed flattened/legacy configuration initially or a deliberately prepared adaptive asset; do not automatically cut the approved symbol out of this flattened master. Android adaptive circle/squircle/rounded-square mask review belongs to that platform integration. No native launcher Home-screen UI automation is claimed; build output, asset catalogs and display-name configuration are verified.

All journal functionality, screen source, editor, media features, themes, search, streaks and navigation remain unchanged by this branding pass.
