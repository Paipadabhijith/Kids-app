# 🚀 Quick Fix: Enable Google Sign-In (5 Minutes)

## What You Need to Do

I cannot access Firebase Console for you (it requires your login), but here's exactly what to do:

## Step 1: Enable Google Sign-In in Firebase Console (2 minutes)

1. **Open your browser** and go to: https://console.firebase.google.com/
2. **Sign in** with your Google account
3. **Select project**: `kids-attention-app`
4. **Click "Authentication"** in the left menu
5. **Click "Sign-in method"** tab
6. **Find "Google"** in the list and click on it
7. **Toggle "Enable" to ON** (it will turn blue/green)
8. **Enter your email** as Project support email
9. **Click "Save"**

## Step 2: Get Your SHA-1 Fingerprint (1 minute)

Run this command in your terminal (from project root):
```bash
cd android
.\gradlew signingReport
```

Look for a line that says:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

Copy that entire SHA1 string.

## Step 3: Add SHA-1 to Firebase (1 minute)

1. In Firebase Console, click the **gear icon** (⚙️) → **Project settings**
2. Scroll to **"Your apps"** section
3. Click on your **Android app** (package: `com.example.kids_tv`)
4. Scroll to **"SHA certificate fingerprints"**
5. Click **"Add fingerprint"**
6. **Paste your SHA-1** from Step 2
7. Click **"Save"**

## Step 4: Download Updated google-services.json (1 minute)

1. Still in Firebase Console → Project Settings → Your apps
2. Find your Android app
3. Click **"Download google-services.json"**
4. **Save the file**

## Step 5: Replace the File

1. **Copy** the downloaded `google-services.json`
2. **Replace** `android/app/google-services.json` in your project
3. The new file should have `oauth_client` entries (not empty `[]`)

## Step 6: Rebuild App

```bash
flutter clean
flutter pub get
flutter run
```

## ✅ Done!

After these steps, sign-in should work. The key is **Step 1** - enabling Google Sign-In in Firebase Console.

---

## Need Help?

If you get stuck:
- Check `ENABLE_GOOGLE_SIGNIN_STEPS.md` for detailed instructions
- The error message in the app will tell you what's wrong
- Most common issue: Forgetting to enable Google Sign-In in Step 1

