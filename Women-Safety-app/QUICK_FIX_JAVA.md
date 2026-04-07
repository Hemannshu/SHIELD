# Quick Fix for JAVA_HOME Error

## Current Error
```
Value '' given for org.gradle.java.home Gradle property is invalid
```

## ✅ Fixed
- Removed the invalid empty `org.gradle.java.home=` line from `gradle.properties`
- Cleared JAVA_HOME in current session

## The Real Problem
JAVA_HOME is set at **System level** to invalid path: `C:\Program Files\Java\jdk-21`

## Permanent Solutions

### Option 1: Remove System JAVA_HOME (Quick)

**Run PowerShell as Administrator:**
```powershell
[Environment]::SetEnvironmentVariable("JAVA_HOME", $null, "Machine")
```

Then restart terminal and run:
```bash
flutter run -d JF89OBS8IRRW69ON
```

### Option 2: Install Java 17 JDK (Best)

1. Download: https://adoptium.net/temurin/releases/?version=17
   - Windows x64 JDK 17 (.msi)
2. Install - it sets valid JAVA_HOME automatically
3. Restart terminal
4. Run: `flutter run -d JF89OBS8IRRW69ON`

### Option 3: Manual System Environment Variable

1. `Win + X` → System
2. Advanced system settings
3. Environment Variables
4. System variables → Find `JAVA_HOME` → Delete
5. Restart terminal

## Temporary Workaround (Current Session Only)

```powershell
# Clear JAVA_HOME for this session
$env:JAVA_HOME = $null
Remove-Item Env:\JAVA_HOME -ErrorAction SilentlyContinue

# Run Flutter
cd "Women-Safety-app"
flutter run -d JF89OBS8IRRW69ON
```

**Note:** You'll need to do this every time you open a new terminal until you fix it permanently.

## Status
✅ Fixed gradle.properties (removed invalid line)
✅ Cleared JAVA_HOME in current session
🔄 Build running - should work if Gradle can find Java automatically

If it still fails, you MUST remove the system-level JAVA_HOME or install Java 17 JDK.




