# Fix JAVA_HOME Error

## Problem
```
ERROR: JAVA_HOME is set to an invalid directory: C:\Program Files\Java\jdk-21
```

## Quick Fix (Try This First)

I've already cleared the invalid JAVA_HOME. Try running:
```bash
flutter run -d JF89OBS8IRRW69ON
```

Gradle might be able to find Java automatically or use a bundled JDK.

## If That Doesn't Work: Install Java 17 JDK

### Option 1: Download Installer (Recommended)

1. **Visit:** https://adoptium.net/temurin/releases/?version=17
2. **Download:** Windows x64 JDK 17 (.msi installer)
3. **Run the installer** - it will set JAVA_HOME automatically
4. **Restart your terminal**
5. **Run:** `flutter run -d JF89OBS8IRRW69ON`

### Option 2: Use Package Manager

**If you have Chocolatey:**
```bash
choco install temurin17jdk
```

**If you have Scoop:**
```bash
scoop install temurin17-jdk
```

### Option 3: Manual Configuration

1. Download JDK 17 from Adoptium
2. Extract to `C:\Program Files\Java\jdk-17` (or your preferred location)
3. Set JAVA_HOME:
   ```powershell
   [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jdk-17", "User")
   ```
4. Restart terminal
5. Verify: `java -version`

### Option 4: Configure Gradle Directly

Edit `android/gradle.properties` and add:
```properties
org.gradle.java.home=C:/Program Files/Java/jdk-17
```

## Verify Installation

After installing, verify:
```bash
java -version
echo $env:JAVA_HOME  # PowerShell
```

You should see Java 17 output.

## Then Run Flutter

```bash
cd "Women-Safety-app"
flutter clean
flutter pub get
flutter run -d JF89OBS8IRRW69ON
```

## Why Java 17?

- Flutter/Android requires JDK (not just JRE)
- Java 17 is the recommended LTS version
- Java 8 might work but Java 17 is better
- Java 21 might have compatibility issues with some Android tools





