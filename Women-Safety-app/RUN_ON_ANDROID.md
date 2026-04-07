# 📱 Running SHEild App on Android Phone

## Your Device
- **Device:** RMX2161
- **Device ID:** JF89OBS8IRRW69ON
- **Android Version:** Android 12 (API 31)
- **Status:** ✅ Detected

## 🚀 Quick Start

### Step 1: Enable USB Debugging (if not already done)

1. **Enable Developer Options:**
   - Go to **Settings** → **About Phone**
   - Tap **Build Number** 7 times
   - You'll see "You are now a developer!"

2. **Enable USB Debugging:**
   - Go to **Settings** → **Developer Options**
   - Turn on **USB Debugging**
   - Turn on **Install via USB** (if available)

3. **Connect Phone:**
   - Connect your phone to PC via USB cable
   - On your phone, you'll see a popup: **"Allow USB debugging?"**
   - Check **"Always allow from this computer"**
   - Tap **Allow**

### Step 2: Verify Connection

```bash
flutter devices
```

You should see your device listed. If it shows "not authorized", check your phone for the authorization dialog.

### Step 3: Run the App

**Option A: Direct Command**
```bash
flutter run -d JF89OBS8IRRW69ON
```

**Option B: Let Flutter Choose**
```bash
flutter run
```
(Flutter will use the first available device)

**Option C: Using Device Name**
```bash
flutter run -d RMX2161
```

## 📋 Step-by-Step Instructions

### 1. Navigate to Project
```bash
cd "C:\Users\HIMANSHU\Desktop\Himanshu\projects\SHEild final\Women-Safety-app"
```

### 2. Check Device Connection
```bash
flutter devices
```

### 3. Run the App
```bash
flutter run -d JF89OBS8IRRW69ON
```

The app will:
- Build the APK
- Install it on your phone
- Launch automatically
- Show logs in terminal

## 🔧 Troubleshooting

### Issue: Device Not Detected

**Solution 1: Check USB Connection**
- Try a different USB cable
- Try a different USB port
- Ensure cable supports data transfer (not just charging)

**Solution 2: Check USB Debugging**
- Settings → Developer Options → USB Debugging (ON)
- Revoke USB debugging authorizations and reconnect

**Solution 3: Install USB Drivers**
- Install device-specific USB drivers
- Or install [Universal ADB Drivers](https://adb.clockworkmod.com/)

**Solution 4: Use ADB**
```bash
# Check if device is recognized
adb devices

# If device shows as "unauthorized", check phone for popup
# If device not listed, install drivers
```

### Issue: "Device Not Authorized"

**Solution:**
1. Disconnect phone
2. On phone: Settings → Developer Options → Revoke USB debugging authorizations
3. Reconnect phone
4. Allow the authorization popup on phone

### Issue: Build Errors

**Solution:**
```bash
# Clean build
flutter clean
flutter pub get

# Try again
flutter run -d JF89OBS8IRRW69ON
```

### Issue: "Gradle Build Failed"

**Solution:**
```bash
cd android
.\gradlew clean
cd ..
flutter clean
flutter pub get
flutter run -d JF89OBS8IRRW69ON
```

### Issue: App Installs But Doesn't Open

**Solution:**
- Check phone storage space
- Check if app is blocked by security settings
- Manually open the app from app drawer

## 🎯 Alternative: Wireless Debugging (Android 11+)

If you prefer wireless connection:

1. **Enable Wireless Debugging:**
   - Settings → Developer Options → Wireless debugging
   - Turn it ON

2. **Pair Device:**
   - Tap "Pair device with pairing code"
   - Note the IP address and port

3. **Connect via ADB:**
   ```bash
   adb pair <IP>:<PORT>
   # Enter pairing code when prompted
   adb connect <IP>:<PORT>
   ```

4. **Run App:**
   ```bash
   flutter run -d <device-id>
   ```

## 📱 First Run Tips

1. **Allow Permissions:**
   - The app will request permissions (Location, Contacts, etc.)
   - Grant all necessary permissions for full functionality

2. **Check Internet:**
   - Ensure phone has internet for Firebase features

3. **Battery Optimization:**
   - Disable battery optimization for the app (for background features)

## 🚀 Quick Command Reference

```bash
# List devices
flutter devices

# Run on your phone
flutter run -d JF89OBS8IRRW69ON

# Run and show verbose output
flutter run -d JF89OBS8IRRW69ON -v

# Build APK only (without running)
flutter build apk

# Install APK manually
flutter install -d JF89OBS8IRRW69ON
```

## ✅ Success Indicators

When running successfully, you'll see:
- ✅ "Running Gradle task 'assembleDebug'..."
- ✅ "Installing build/app/outputs/flutter-apk/app.apk..."
- ✅ "Flutter run key commands" menu
- ✅ App launches on your phone
- ✅ Hot reload available (press `r` in terminal)

## 🎉 You're Ready!

Your device is detected and ready. Just run:
```bash
flutter run -d JF89OBS8IRRW69ON
```

The app will build, install, and launch on your phone automatically!





