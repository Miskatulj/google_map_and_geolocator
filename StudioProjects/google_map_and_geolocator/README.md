# Google Map and Geolocator

A Flutter/Dart Android application that displays a Google Map and tracks the
device's current location.

## Features

- Requests location permission and detects the current location.
- Animates the map camera to the current location.
- Updates the location, marker, and route every 10 seconds.
- Shows a marker info window with latitude and longitude.
- Draws a polyline connecting successive location updates.

## Local setup

1. Install Flutter and configure the Android SDK in Android Studio.
2. In `android/local.properties`, retain the existing Flutter and SDK entries,
   then add your Google Maps Android API key:

   ```properties
   GOOGLE_MAPS_API_KEY=your_google_maps_android_api_key
   ```

   This file is intentionally Git-ignored. Restrict the key in Google Cloud to
   this Android app's package name and signing-certificate SHA-1.
3. Run:

   ```bash
   flutter pub get
   flutter run
   ```

Before publishing the repository, verify that no API key, signing file, or
local configuration file is staged.
