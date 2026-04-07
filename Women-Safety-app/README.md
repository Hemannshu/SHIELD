# SHEield
# Women Safety Application

## Introduction

The **Women Safety Application** is a mobile app designed to provide safety features to women, ensuring their security in critical situations. The app includes features such as an emergency alert system, location tracking, and the ability to send instant alerts to friends or family members in case of distress.

## Features

- **SOS Alert**: Sends an emergency message with location details to pre-selected contacts.
- **Real-time Location Tracking**: Track the user’s location and share it with trusted contacts.
- **Quick Emergency Call**: Call emergency services directly with a single tap.
- **Geo-fencing**: Set safe zones, and receive alerts when the user exits these zones.
- **Voice Command**: Activate SOS alerts using voice commands.
- **Chat Support**: Get live assistance from support teams or friends in case of an emergency.

## Tech Stack

- **Flutter**: For building the cross-platform mobile app.
- **Firebase**: For user authentication, real-time database, and cloud functions.
- **Google Maps API**: For location tracking and geo-fencing features.
- **Twilio**: For sending SMS alerts (optional based on project requirements).
- **Speech-to-Text**: For voice command integration.

## Setup Instructions

### Prerequisites

Before setting up the project, make sure you have the following installed on your machine:
- [Flutter](https://flutter.dev/docs/get-started/install) (with Flutter SDK) - **REQUIRED**
- [Dart](https://dart.dev/get-dart) (comes with Flutter)
- [Android Studio](https://developer.android.com/studio) or [Visual Studio Code](https://code.visualstudio.com/) with Flutter plugin installed
- [Firebase](https://firebase.google.com/) account for configuring the backend
- Google Maps API key (if using location tracking)
- Python 3.x (optional, for emotion prediction API)

### Step 1: Install Flutter

If Flutter is not installed:

1. **Download Flutter SDK:**
   - Visit: https://docs.flutter.dev/get-started/install/windows
   - Download the latest stable Flutter SDK zip file
   - Extract it to a location like `C:\src\flutter` (avoid spaces in path)

2. **Add Flutter to PATH:**
   - Open System Environment Variables
   - Add `C:\src\flutter\bin` to your PATH
   - Restart your terminal/command prompt

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```
   This will check your setup and show what else needs to be configured.

4. **Install Required Tools:**
   - Follow the `flutter doctor` recommendations
   - Install Android Studio if you plan to run on Android
   - Accept Android licenses: `flutter doctor --android-licenses`

### Step 2: Clone/Navigate to Project

```bash
cd "Women-Safety-app"
```

### Step 3: Install Dependencies

```bash
flutter pub get
```

This will download all the required packages listed in `pubspec.yaml`.

### Step 4: Check Connected Devices

```bash
flutter devices
```

This shows available devices (emulators, physical devices, etc.)

### Step 5: Run the Application

**For Android:**
```bash
flutter run
```

**For a specific device:**
```bash
flutter run -d <device-id>
```

**For Web (if supported):**
```bash
flutter run -d chrome
```

### Step 6: Build the Application

**Build APK for Android:**
```bash
flutter build apk
```

**Build App Bundle for Play Store:**
```bash
flutter build appbundle
```

**Build for iOS (Mac only):**
```bash
flutter build ios
```

## Optional: Python API Setup (Emotion Prediction)

The project includes a Flask API for emotion prediction (`assets/api.py`). To use it:

1. **Install Python dependencies:**
   ```bash
   pip install flask joblib numpy
   ```

2. **Note:** The API requires model files:
   - `emotion_model.pkl`
   - `tfidf_vectorizer.pkl`
   - `label_encoder.pkl`
   
   These files need to be in the same directory as `api.py` or the path needs to be updated.

3. **Run the API:**
   ```bash
   cd assets
   python api.py
   ```
   The API will run on `http://localhost:5000`

## Firebase Configuration

The app is already configured with Firebase. The configuration is in:
- `lib/firebase_options.dart`
- `android/app/google-services.json`

If you need to reconfigure Firebase:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create/select your project
3. Run: `flutterfire configure`

## Troubleshooting

### Flutter not recognized
- Ensure Flutter is added to your PATH
- Restart your terminal/IDE after adding to PATH

### Dependencies issues
```bash
flutter clean
flutter pub get
```

### Android build issues
- Ensure Android SDK is installed
- Check `android/local.properties` for SDK path
- Run `flutter doctor` to diagnose issues

### Firebase issues
- Verify `google-services.json` is in `android/app/`
- Check Firebase project settings match `firebase_options.dart`

## Project Structure

```
Women-Safety-app/
├── lib/
│   ├── main.dart              # App entry point
│   ├── child/                 # Child/user screens
│   ├── parent/                # Parent screens
│   ├── components/            # Reusable components
│   ├── services/              # Business logic services
│   ├── utils/                 # Utilities and constants
│   └── widgets/               # Custom widgets
├── assets/                    # Images, sounds, data files
├── android/                   # Android-specific files
├── ios/                       # iOS-specific files
└── pubspec.yaml              # Dependencies and assets
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
