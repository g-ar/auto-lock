# auto_lock

This is an app to quickly lock the android screen by using accessibility service feature, to avoid using the power button, or if there's issue with the button.
Most of the android devices screen turn on by double tap, but to turn off the screen, there's no tap to turn off feature.
Since accessibilty feature needs swipes and taps to turn off the screen instead of a simple tap, 
this will provide such a feature!

## Usage

- `flutter build apk --release`<br/>
- `adb install build/app/outputs/flutter-apk/app-release.apk`
- Enable accessibility service after opening the app
- Add app to homescreen to quickly access to lock screen
- If supported by the device, gesture control can be added, so that double tapping the rear of the phone will open this app

