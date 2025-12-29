# Google Sign-In Setup Guide

## Why Sign-In is Failing

The most common reasons for Google Sign-In failure:

1. **Google Sign-In not enabled in Firebase Console**
2. **Missing OAuth client configuration**
3. **SHA-1 fingerprint not added to Firebase**
4. **Network/permission issues**

## Step-by-Step Fix

### 1. Enable Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **kids-attention-app**
3. Go to **Authentication** → **Sign-in method**
4. Click on **Google**
5. Toggle **Enable** to ON
6. Enter a **Project support email** (your email)
7. Click **Save**

### 2. Verify SHA-1 Fingerprint is Added

Your SHA-1 fingerprint should already be added:
- **SHA-1:** `E2:3C:36:C5:6B:5B:C4:22:9A:85:2B:94:23:B2:25:7B:D0:34:5F:9C`

To verify:
1. Firebase Console → Project Settings → Your apps
2. Click on your Android app
3. Check if SHA-1 is listed under "SHA certificate fingerprints"

### 3. Download Updated google-services.json

After enabling Google Sign-In:
1. Firebase Console → Project Settings
2. Scroll to "Your apps"
3. Click on your Android app
4. Download the **google-services.json** file
5. Replace `android/app/google-services.json` with the new file

### 4. Rebuild the App

```bash
flutter clean
flutter pub get
flutter run
```

## Troubleshooting

### Error: "PlatformException"
- Make sure Google Sign-In is enabled in Firebase Console
- Verify SHA-1 fingerprint is correct
- Check internet connection

### Error: "Sign in failed"
- Check Firebase Console → Authentication → Sign-in method
- Ensure Google is enabled
- Verify google-services.json is up to date

### Error: "Network error"
- Check internet connection
- Verify Firebase project is active
- Check if API is enabled in Google Cloud Console

## Test Sign-In

After completing the setup:
1. Hot restart the app (not just hot reload)
2. Click "Sign in with Google"
3. Select your Google account
4. Grant permissions if prompted
5. You should be signed in successfully

