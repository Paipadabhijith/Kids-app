# ✅ Complete Fix Guide - Enable Google Sign-In

## Your SHA-1 Fingerprint (Already Found!)
```
E2:3C:36:C5:6B:5B:C4:22:9A:85:2B:94:23:B2:25:7B:D0:34:5F:9C
```

## Step-by-Step Instructions

### Step 1: Enable Google Sign-In in Firebase Console ⭐ (MOST IMPORTANT)

1. **Open browser** → Go to: https://console.firebase.google.com/
2. **Sign in** with your Google account
3. **Select project**: `kids-attention-app`
4. **Click "Authentication"** in left sidebar
5. **Click "Sign-in method"** tab (at top)
6. **Find "Google"** in the provider list
7. **Click on "Google"** (the row, opens a dialog)
8. **Toggle "Enable" to ON** (turns blue/green)
9. **Enter your email** as "Project support email"
10. **Click "Save"**

✅ **This is the critical step!** Without this, sign-in will always fail.

---

### Step 2: Add SHA-1 Fingerprint to Firebase

1. In Firebase Console, click **gear icon (⚙️)** → **Project settings**
2. Scroll to **"Your apps"** section
3. Find your **Android app** (package: `com.example.kids_tv`)
4. **Click on it** to expand
5. Scroll to **"SHA certificate fingerprints"**
6. **Click "Add fingerprint"**
7. **Paste this SHA-1:**
   ```
   E2:3C:36:C5:6B:5B:C4:22:9A:85:2B:94:23:B2:25:7B:D0:34:5F:9C
   ```
8. **Click "Save"**

---

### Step 3: Download Updated google-services.json

1. Still in Firebase Console → Project Settings → Your apps
2. Find your **Android app**
3. **Click "Download google-services.json"** button
4. **Save the file** to your computer

---

### Step 4: Replace google-services.json in Your Project

1. **Copy** the downloaded `google-services.json` file
2. **Navigate to**: `android/app/google-services.json` in your project
3. **Replace** the old file with the new one
4. **Verify** the new file has `oauth_client` entries (not empty `[]`)

**To verify:** Open the new file and check line 15. It should look like:
```json
"oauth_client": [
  {
    "client_id": "...",
    "client_type": 1,
    ...
  }
]
```

NOT:
```json
"oauth_client": []
```

---

### Step 5: Rebuild the App

Run these commands in your terminal:

```bash
flutter clean
flutter pub get
flutter run
```

---

## ✅ Verification Checklist

After completing all steps:

- [ ] Google Sign-In enabled in Firebase Console
- [ ] SHA-1 fingerprint added to Firebase
- [ ] New `google-services.json` downloaded
- [ ] New `google-services.json` replaced in project
- [ ] New file has `oauth_client` entries (not empty)
- [ ] App rebuilt with `flutter clean` and `flutter run`

---

## 🎯 Test Sign-In

1. **Hot restart** the app (not just hot reload)
2. **Click "Sign in with Google"**
3. **Select your Google account**
4. **Grant permissions** if prompted
5. **You should be signed in!** ✅

---

## 🆘 Still Not Working?

### Check the Error Message

The app now shows specific error messages. Common ones:

- **"Google Sign-In not enabled"** → Go back to Step 1
- **"Network error"** → Check internet connection
- **"Invalid API key"** → Re-download google-services.json (Step 3)

### Check Console Logs

Look for these in your debug console:
- `🔵 Starting Google Sign-In...` ✅ Good - process started
- `✅ Google account selected` ✅ Good - account picked
- `❌ Firebase Auth Error: [code]` ❌ Check the error code

---

## 📝 Quick Reference

**Your SHA-1:** `E2:3C:36:C5:6B:5B:C4:22:9A:85:2B:94:23:B2:25:7B:D0:34:5F:9C`

**Firebase Project:** `kids-attention-app`

**Package Name:** `com.example.kids_tv`

**File to Replace:** `android/app/google-services.json`

---

**The most important step is Step 1 - enabling Google Sign-In in Firebase Console!**

After you complete Step 1, the rest should be straightforward. Let me know if you need help with any specific step!

