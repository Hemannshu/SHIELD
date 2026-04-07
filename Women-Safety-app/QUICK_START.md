# Quick Start Guide - SHEild App

## 🚀 Immediate Next Steps

### 1. Check Flutter Installation

Open a new terminal/command prompt and run:
```bash
flutter --version
```

If you see an error like "flutter is not recognized", you need to install Flutter first.

### 2. Install Flutter (if not installed)

**Windows Installation:**
1. Download Flutter SDK from: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter` (or another location without spaces)
3. Add to PATH:
   - Press `Win + X` and select "System"
   - Click "Advanced system settings"
   - Click "Environment Variables"
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\src\flutter\bin`
   - Click OK on all dialogs
4. **Restart your terminal/IDE**
5. Verify: `flutter --version`

### 3. Run Flutter Doctor

```bash
flutter doctor
```

This checks your setup. Install any missing components it suggests.

### 4. Navigate to Project

```bash
cd "C:\Users\HIMANSHU\Desktop\Himanshu\projects\SHEild final\Women-Safety-app"
```

### 5. Install Dependencies

```bash
flutter pub get
```

### 6. Check Available Devices

```bash
flutter devices
```

You should see:
- Connected physical devices
- Available emulators
- Chrome (for web)

### 7. Start an Android Emulator (if needed)

**Option A: Using Android Studio**
1. Open Android Studio
2. Tools → Device Manager
3. Create/Start an emulator

**Option B: Using Command Line**
```bash
flutter emulators
flutter emulators --launch <emulator-id>
```

### 8. Run the App

```bash
flutter run
```

Or specify a device:
```bash
flutter run -d <device-id>
```

## 📱 Running on Physical Device

### Android:
1. Enable Developer Options on your phone
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run`

### iOS (Mac only):
1. Connect iPhone via USB
2. Trust the computer on your phone
3. Run: `flutter run`

## 🔧 Common Issues & Solutions

### Issue: "flutter: command not found"
**Solution:** Flutter is not in PATH. Follow Step 2 above.

### Issue: "No devices found"
**Solution:** 
- For Android: Start an emulator or connect a physical device
- Check: `flutter devices`

### Issue: "Gradle build failed"
**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "Firebase initialization error"
**Solution:** The Firebase config is already set up. If issues persist:
- Check `lib/firebase_options.dart` exists
- Verify `android/app/google-services.json` exists

## 📋 Project Checklist

- [ ] Flutter installed and in PATH
- [ ] Flutter doctor shows no critical issues
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Device/Emulator available
- [ ] App runs successfully

## 🎯 Next Steps After Running

1. **Test the app features:**
   - Login/Registration
   - SOS functionality
   - Location services
   - Emergency contacts

2. **Configure API keys (if needed):**
   - Google Maps API key (for location features)
   - Twilio credentials (for SMS alerts)

3. **Set up Python API (optional):**
   - Install Python dependencies
   - Add model files for emotion prediction
   - Run the Flask server

## 📞 Need Help?

- Flutter Docs: https://docs.flutter.dev/
- Flutter Community: https://flutter.dev/community
- Check `README.md` for detailed information


