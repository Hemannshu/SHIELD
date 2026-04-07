# Complete Fix for JAVA_HOME Error

## The Problem
JAVA_HOME is set at **System level** to an invalid directory: `C:\Program Files\Java\jdk-21`

## Solution Options (Choose One)

### ✅ Option 1: Remove System JAVA_HOME (Recommended - Quick Fix)

**Run as Administrator:**

1. Right-click **PowerShell** → **Run as Administrator**
2. Navigate to project:
   ```powershell
   cd "C:\Users\HIMANSHU\Desktop\Himanshu\projects\SHEild final\Women-Safety-app"
   ```
3. Run the script:
   ```powershell
   .\remove_java_home_system.ps1
   ```
4. **Restart your terminal/IDE**
5. Run Flutter:
   ```bash
   flutter run -d JF89OBS8IRRW69ON
   ```

**OR Manual Method:**
1. Press `Win + X` → **System**
2. Click **Advanced system settings**
3. Click **Environment Variables**
4. Under **System variables**, find `JAVA_HOME`
5. Click **Delete**
6. Click **OK** on all dialogs
7. **Restart terminal/IDE**

### ✅ Option 2: Install Java 17 JDK (Best Long-term Solution)

This will set a **valid** JAVA_HOME automatically:

1. **Download Java 17 JDK:**
   - Visit: https://adoptium.net/temurin/releases/?version=17
   - Download: **Windows x64 JDK 17** (.msi installer)

2. **Install:**
   - Run the installer
   - It will automatically set JAVA_HOME to the correct location
   - ✅ Check "Set JAVA_HOME variable" during installation

3. **Restart terminal/IDE**

4. **Verify:**
   ```bash
   java -version  # Should show Java 17
   echo $env:JAVA_HOME  # Should show valid path
   ```

5. **Run Flutter:**
   ```bash
   flutter run -d JF89OBS8IRRW69ON
   ```

### Option 3: Override in Current Session Only

For a quick test (temporary fix):

```powershell
# Clear JAVA_HOME for this session
$env:JAVA_HOME = $null
Remove-Item Env:\JAVA_HOME -ErrorAction SilentlyContinue

# Navigate to project
cd "C:\Users\HIMANSHU\Desktop\Himanshu\projects\SHEild final\Women-Safety-app"

# Run Flutter
flutter run -d JF89OBS8IRRW69ON
```

**Note:** This only works for the current terminal session. You'll need to do this every time you open a new terminal.

## What I've Already Done

1. ✅ Cleared JAVA_HOME in current session
2. ✅ Updated `android/gradle.properties` to help Gradle find Java
3. ✅ Created `remove_java_home_system.ps1` script (run as admin)
4. ✅ Started a build attempt

## Recommended Action

**I recommend Option 2 (Install Java 17 JDK)** because:
- ✅ Sets a valid JAVA_HOME automatically
- ✅ Provides the correct JDK (not just JRE) needed for Android
- ✅ Works permanently
- ✅ No manual configuration needed

## After Fixing

Once JAVA_HOME is fixed, run:

```bash
cd "Women-Safety-app"
flutter clean
flutter pub get
flutter run -d JF89OBS8IRRW69ON
```

## Verify It's Fixed

Check JAVA_HOME:
```powershell
echo $env:JAVA_HOME
```

Should show:
- ✅ A valid path to a JDK (like `C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot`)
- ✅ OR nothing/null (Gradle will find Java automatically)

Should NOT show:
- ❌ `C:\Program Files\Java\jdk-21` (invalid)

## Still Having Issues?

If Gradle still can't find Java after removing JAVA_HOME:

1. Install Java 17 JDK (Option 2 above)
2. Or manually set JAVA_HOME to a valid JDK:
   ```powershell
   [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\path\to\valid\jdk", "User")
   ```





