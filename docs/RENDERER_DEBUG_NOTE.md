# Android emulator renderer note

For debug/profile builds only, Impeller is disabled via the Android manifest.
This works around a cyan/blue compositor artifact observed while scrolling on
the Pixel 8a Android 14 (API 34) emulator.

Release builds are unchanged and keep Flutter's platform-default renderer.

For a one-off diagnostic run without relying on the manifest:

    flutter run -d emulator-5554 --no-enable-impeller
