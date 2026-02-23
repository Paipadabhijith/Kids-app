# Step-by-Step: Enable Google Sign-In in Firebase Console

## ⚠️ IMPORTANT: You need to do this in Firebase Console (web browser)

I cannot access your Firebase Console, but I'll guide you through each step.

## Step 1: Open Firebase Console

1. Open your web browser
2. Go to: **https://console.firebase.google.com/**
3. Sign in with your Google account (the one that has access to the project)
4. Select your project: **kids-attention-app**

## Step 2: Enable Google Sign-In

1. In the left sidebar, click **Authentication**
2. Click the **Sign-in method** tab (at the top)
3. You'll see a list of sign-in providers
4. Find **Google** in the list
5. Click on **Google** (the row, not just the toggle)
6. A dialog will open:
   - Toggle **Enable** to **ON** (it should turn green/blue)
   - Enter a **Project support email** (your email address)
   - Click **Save**

## Step 3: Verify SHA-1 Fingerprint (Important for Android)

1. Get your SHA-1 fingerprint:
   - Open terminal/command prompt in your project
   - Run: `cd android && gradlew.bat signingReport`
   - Look for "SHA1:" in the output (it will be a long string like: `E2:3C:36:C5:6B:5B:...`)

2. Add SHA-1 to Firebase:
   - In Firebase Console, click the **gear icon** (⚙️) next to "Project Overview"
   - Click **Project settings**
   - Scroll down to **Your apps** section
   - Find your Android app (package: `com.example.kids_tv`)
   - Click on it
   - Scroll to **SHA certificate fingerprints**
   - Click **Add fingerprint**
   - Paste your SHA-1 fingerprint
   - Click **Save**

## Step 4: Download Updated google-services.json

1. Still in Firebase Console → Project Settings
2. In **Your apps** section, find your Android app
3. Click **Download google-services.json** button
4. Save the file

## Step 5: Replace the File in Your Project

1. Copy the downloaded `google-services.json` file
2. Replace the file at: `android/app/google-services.json`
3. Make sure the new file has `oauth_client` entries (not empty array)

## Step 6: Rebuild the App

Run these commands:
```bash
flutter clean
flutter pub get
flutter run
```

## Verification

After rebuilding, the new `google-services.json` should have:
- `"oauth_client": [...]` with entries (not empty `[]`)
- OAuth client IDs for Android

## Need Help?

If you get stuck at any step, let me know which step and I'll provide more detailed instructions!







