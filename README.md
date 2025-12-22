# Kids TV Mobile App

A Flutter mobile app that allows kids to watch YouTube videos with a kid-friendly interface, including search, categories, playlists, and comprehensive parental controls.

## Features

- 🎥 **YouTube Video Playback** - Watch videos with a kid-friendly player
- 🔍 **Video Search** - Search for videos with safe search enabled
- 📂 **Categories** - Browse videos by YouTube categories
- 📋 **Custom Playlists** - Create and manage your own playlists
- 🛡️ **Parental Controls**:
  - Daily time limits
  - Content filtering with keyword blocking
  - Password protection for settings
  - Break reminders with interactive games
- 📊 **Usage Statistics** - Track daily and weekly viewing time
- 📚 **Curated Content** - Pre-approved kid-safe videos
- 📱 **Watch History** - Keep track of recently watched videos

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.0.0 or higher)
  - Check installation: `flutter --version`
  - Install from: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Android SDK** (for Android development)
  - Android Studio includes the SDK
- **Xcode** (for iOS development, macOS only)
  - Install from Mac App Store
- **YouTube Data API v3 Key** (see setup instructions below)
- **Git** (for version control)

## Local Development Setup

### Step 1: Clone the Repository

```bash
git clone <your-repository-url>
cd kids-tv
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

This will install all the required packages listed in `pubspec.yaml`:
- `youtube_player_flutter` - For video playback
- `http` - For API calls
- `shared_preferences` - For local storage
- `sqflite` - For database operations
- `crypto` - For password hashing
- `flutter_dotenv` - For environment variables
- And other dependencies

### Step 3: Set Up YouTube API Key

1. **Get a YouTube Data API v3 Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select an existing one
   - Enable the **YouTube Data API v3**
   - Go to "Credentials" → "Create Credentials" → "API Key"
   - Copy your API key

2. **Create the `.env` file:**
   - Copy the example file:
     ```bash
     cp .env.example .env
     ```
   - Open `.env` and replace `your_youtube_api_key_here` with your actual API key:
     ```
     YOUTUBE_API_KEY=your_actual_api_key_here
     ```
   
   **Note:** The `.env` file is already in `.gitignore` and will not be committed to version control.

3. **Optional: Restrict API Key (Recommended for Production)**
   - In Google Cloud Console, edit your API key
   - Under "API restrictions", select "Restrict key"
   - Choose "YouTube Data API v3"
   - Under "Application restrictions", you can restrict by IP or Android/iOS app

### Step 4: Verify Flutter Setup

```bash
flutter doctor
```

This will check your Flutter installation and show any missing dependencies. Fix any issues before proceeding.

### Step 5: Run the App

#### For Android:

```bash
# List available devices
flutter devices

# Run on a connected device or emulator
flutter run

# Or specify a device
flutter run -d <device-id>
```

#### For iOS (macOS only):

```bash
# Install CocoaPods dependencies (first time only)
cd ios
pod install
cd ..

# Run on a connected device or simulator
flutter run

# Or open in Xcode
open ios/Runner.xcworkspace
```

#### For Web (experimental):

```bash
flutter run -d chrome
```

### Step 6: Build the App

#### Android APK:

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App bundle for Play Store
flutter build appbundle --release
```

#### iOS (macOS only):

```bash
# Build for iOS
flutter build ios --release

# Or use Xcode
open ios/Runner.xcworkspace
```

## Development Workflow

### Running in Debug Mode

```bash
flutter run
```

- Hot reload: Press `r` in the terminal
- Hot restart: Press `R` in the terminal
- Quit: Press `q` in the terminal

### Running Tests

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart
```

### Code Analysis

```bash
# Analyze code for issues
flutter analyze

# Format code
flutter format lib/
```

### Cleaning Build Files

```bash
# Clean build artifacts
flutter clean

# Then reinstall dependencies
flutter pub get
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                  # Data models
│   ├── playlist_model.dart
│   ├── settings_model.dart
│   └── video_model.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── search_screen.dart
│   ├── categories_screen.dart
│   ├── playlists_screen.dart
│   ├── video_player_screen.dart
│   ├── parental_settings_screen.dart
│   ├── curated_content_screen.dart
│   ├── usage_statistics_screen.dart
│   └── break_reminder_screen.dart
├── services/                 # Business logic
│   ├── youtube_service.dart
│   ├── parental_control_service.dart
│   └── storage_service.dart
├── widgets/                  # Reusable widgets
│   ├── video_card.dart
│   ├── playlist_card.dart
│   ├── category_card.dart
│   ├── time_limit_widget.dart
│   └── kid_friendly_button.dart
└── utils/                    # Utilities
    ├── constants.dart       # App constants and API key
    └── theme.dart           # App theme
```

## Troubleshooting

### Common Issues

#### 1. **YouTube API Errors**

**Error:** "Failed to search videos" or "API key not valid"

**Solutions:**
- Verify your API key is correct in `lib/utils/constants.dart`
- Check that YouTube Data API v3 is enabled in Google Cloud Console
- Ensure your API key has proper quotas/limits
- Check if API key restrictions are blocking your requests

#### 2. **Build Errors**

**Error:** Gradle build failed (Android)

**Solutions:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

#### 3. **iOS Pod Issues**

**Error:** CocoaPods errors

**Solutions:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### 4. **No Devices Found**

**Solutions:**
- For Android: Enable USB debugging and connect device, or start an emulator
- For iOS: Open Simulator from Xcode or connect a physical device
- Check with: `flutter devices`

#### 5. **Dependencies Issues**

**Error:** Package not found or version conflicts

**Solutions:**
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

### Debugging Tips

1. **Check Logs:**
   ```bash
   flutter run --verbose
   ```

2. **Inspect Network Requests:**
   - Check the error messages in the app UI
   - Use browser DevTools for web version
   - Check Android Logcat: `adb logcat | grep flutter`

3. **Test API Key:**
   - You can test your API key directly:
   ```bash
   curl "https://www.googleapis.com/youtube/v3/search?part=snippet&q=test&key=YOUR_API_KEY"
   ```

## Environment Variables

The app uses environment variables for secure API key management. The YouTube API key is stored in a `.env` file (which is already in `.gitignore`).

### Setting Up Environment Variables

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` and add your API key:**
   ```
   YOUTUBE_API_KEY=your_actual_api_key_here
   ```

3. **The `.env` file is automatically loaded** when the app starts (see `main.dart`)

**Note:** Never commit the `.env` file to version control. The `.env.example` file serves as a template for other developers.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `flutter test`
4. Run analysis: `flutter analyze`
5. Format code: `flutter format lib/`
6. Submit a pull request

## Requirements

- Flutter SDK: `>=3.0.0 <4.0.0`
- Dart SDK: `>=3.0.0 <4.0.0`
- Android: Minimum SDK 21 (Android 5.0)
- iOS: Minimum iOS 12.0

## License

[Add your license here]

## Support

For issues and questions:
- Check the troubleshooting section above
- Review Flutter documentation: [https://flutter.dev/docs](https://flutter.dev/docs)
- YouTube Data API docs: [https://developers.google.com/youtube/v3](https://developers.google.com/youtube/v3)
