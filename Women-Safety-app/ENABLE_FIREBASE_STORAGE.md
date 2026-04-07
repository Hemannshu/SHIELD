# Enable Firebase Storage - Quick Guide

## 🔧 Fix: "firebase object not found failed to store"

This error means Firebase Storage needs to be enabled in your Firebase Console.

---

## ✅ Quick Fix (5 Minutes)

### Step 1: Go to Firebase Console

1. Visit: https://console.firebase.google.com/
2. Select your project: **sheild-d4bd4**

### Step 2: Enable Storage

1. Click **Storage** in the left menu
2. If you see "Get Started", click it
3. Choose **Start in test mode** (for development)
4. Click **Next** → **Done**

### Step 3: Set Storage Rules

1. Go to **Storage** → **Rules** tab
2. Replace with this (allows authenticated users):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to read/write their own evidence
    match /evidence/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default: deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **Publish**

### Step 4: Test Again

1. Run your app
2. Trigger SOS
3. Capture evidence
4. Should work now! ✅

---

## 🔍 Verify Storage is Enabled

After enabling, you should see:
- ✅ Storage section in Firebase Console
- ✅ "Files" tab shows uploaded files
- ✅ No "Get Started" button

---

## ⚠️ If Still Not Working

### Check 1: Storage Bucket
- Go to **Project Settings** → **General**
- Scroll to **Your apps**
- Check **Storage bucket** is set: `sheild-d4bd4.firebasestorage.app`

### Check 2: Authentication
- User must be logged in
- Check **Authentication** → **Users** in Firebase Console

### Check 3: Internet Connection
- Upload requires internet
- Check device has connection

---

## 🎯 Current Code Behavior

Even if Storage isn't enabled:
- ✅ **Hash is stored** (in Firestore)
- ✅ **Metadata is saved** (file info, timestamp)
- ✅ **Evidence record created**
- ⚠️ File upload will fail (but metadata saved)

**Enable Storage to upload files!**

---

## 📝 Alternative: Use Local Storage (Temporary)

If you want to test without Firebase Storage, the code now:
1. Stores hash in Firestore ✅
2. Stores metadata ✅
3. Shows confirmation ✅
4. File upload fails (but that's OK for testing)

You can enable Storage later and files will upload!

---

## ✅ After Enabling

1. Restart the app
2. Try capturing evidence again
3. Check Firebase Console → Storage → Files
4. Should see your uploaded files!

---

## 🆘 Still Having Issues?

Check the console logs for:
- "Uploading to Firebase Storage: ..."
- "Upload completed..."
- Or specific error messages

Share the error message and I can help fix it!

