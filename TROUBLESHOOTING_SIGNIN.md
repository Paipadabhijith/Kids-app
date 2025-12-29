# Troubleshooting Sign-In Failures

## Quick Diagnostic Steps

### 1. Check Console Logs
When sign-in fails, check the debug console for these error messages:
- `🔵 Starting Google Sign-In...` - Sign-in process started
- `✅ Google account selected` - User selected account
- `✅ Authentication tokens obtained` - Google tokens received
- `🔵 Signing in to Firebase...` - Attempting Firebase sign-in
- `✅ Firebase Authentication SUCCESS` - Sign-in successful

If you see errors before any of these steps, that's where the issue is.

### 2. Common Error Codes and Solutions

#### Error: "operation-not-allowed"
**Cause:** Google Sign-In not enabled in Firebase Console
**Solution:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Sign-in method**
4. Click on **Google**
5. Toggle **Enable** to ON
6. Enter a **Project support email**
7. Click **Save**
8. Rebuild the app

#### Error: "network-request-failed"
**Cause:** Network connectivity issues
**Solution:**
- Check internet connection
- Try on different network
- Check if Firebase services are accessible

#### Error: "invalid-credential"
**Cause:** Authentication tokens are invalid or expired
**Solution:**
- Try signing in again
- Clear app data and retry
- Check if Google account is valid

#### Error: "invalid-api-key"
**Cause:** Firebase configuration issue
**Solution:**
1. Download fresh `google-services.json` from Firebase Console
2. Replace `android/app/google-services.json`
3. Rebuild the app

### 3. Verify Firebase Configuration

#### Check SHA-1 Fingerprint
1. Get your SHA-1 fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Or for Windows:
   ```bash
   cd android
   gradlew.bat signingReport
   ```

2. Add SHA-1 to Firebase:
   - Firebase Console → Project Settings → Your apps
   - Click on your Android app
   - Add SHA-1 fingerprint under "SHA certificate fingerprints"

3. Download updated `google-services.json` and rebuild

### 4. Test Steps

1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Check Firebase initialization:**
   - Look for "Firebase initialized successfully" in console
   - If missing, check `google-services.json` is in correct location

3. **Verify Google Sign-In is enabled:**
   - Firebase Console → Authentication → Sign-in method
   - Google should show as "Enabled"

### 5. Platform-Specific Issues

#### Android
- Ensure `google-services.json` is in `android/app/` directory
- Check `build.gradle.kts` includes `com.google.gms.google-services` plugin
- Verify SHA-1 fingerprint is added to Firebase

#### iOS
- Ensure `GoogleService-Info.plist` is in `ios/Runner/` directory
- Check `Info.plist` has correct bundle identifier
- Verify URL schemes are configured

### 6. Debug Mode

Enable verbose logging by checking console output. The app prints detailed debug messages:
- `🔵` = Process step
- `✅` = Success
- `❌` = Error
- `⚠️` = Warning

### 7. Still Not Working?

If sign-in still fails after checking all above:
1. Check Firebase project is active and billing is enabled (if required)
2. Verify Google Cloud APIs are enabled for your project
3. Check if there are any Firebase quota limits reached
4. Try creating a new Firebase project and testing with that

## Need More Help?

Check the error message in the app's snackbar - it should provide specific guidance based on the error type.

