# Kids TV — Native iOS App

This folder contains a **native Swift/SwiftUI** iOS version of the Kids TV app, with full feature parity to the Flutter app: home feed, categories, search, video playback, playlists, favorites, parental controls, and optional Firebase Auth + Google Sign-In.

## Requirements

- **Xcode 15+** and **macOS** (the project must be opened and built on a Mac)
- **iOS 15.0+** deployment target
- **Apple Developer account** (for running on device and App Store; you said you’ll create this later)

## Opening the project

1. On a Mac, open **Xcode**.
2. **File → Open** and select the `iOS_Kids TV` folder (or open `KidsTV.xcodeproj` inside it).
3. Select the **Kids TV** scheme and a simulator or device.

The app will build and run **without** Firebase or a YouTube API key; trending/recommendations will show “no API key” or empty until you add configuration below.

## Configuration

### 1. YouTube API key (required for video content)

- Get an API key from [Google Cloud Console](https://console.cloud.google.com/) (YouTube Data API v3).
- In Xcode:
  - Either add to **Info.plist**: replace the `YOUTUBE_API_KEYS` array with your key(s),  
  - Or add a **User-Defined Build Setting**: `YOUTUBE_API_KEY` = `your_key`, and reference it in Info.plist as `$(YOUTUBE_API_KEY)`.

### 2. Firebase (optional — for Auth and Analytics)

- In [Firebase Console](https://console.firebase.google.com/), create or use the same project as your Flutter app.
- Add an **iOS app** with bundle ID `com.kidstv.app` (or the one you set in the target).
- Download **GoogleService-Info.plist** and add it to the **KidsTV** target (drag into the project, check “Copy items” and the Kids TV target).
- In Xcode: **File → Add Package Dependencies** and add:
  - `https://github.com/firebase/firebase-ios-sdk`
  - Add **FirebaseCore** and **FirebaseAuth** (and **FirebaseAnalytics** if you want).
- Rebuild. Sign-in will work after you add Google Sign-In (next step).

### 3. Google Sign-In (optional)

- In Firebase Console → Authentication → Sign-in method, enable **Google**.
- Add the **GoogleSignIn** package (e.g. from Apple’s or Google’s SPM repo) and link the **GoogleSignIn** library to the Kids TV target.
- Ensure the iOS client ID from Firebase is used where `AuthService` expects it (e.g. in `GoogleService-Info.plist` or your config). The app uses the same client ID as Firebase for `GIDConfiguration`.

### 4. Bundle ID and signing

- In Xcode, select the **Kids TV** target → **Signing & Capabilities**.
- Set **Team** to your Apple Developer team.
- Set **Bundle Identifier** (e.g. `com.yourcompany.kidstv`) to match Firebase and your App Store app.

## Project structure

```
iOS_Kids TV/
├── KidsTV.xcodeproj/
├── README.md
└── KidsTV/
    ├── App/
    │   ├── KidsTVApp.swift      # App entry, theme, Firebase init
    │   └── ContentView.swift
    ├── Models/
    │   ├── VideoModel.swift
    │   ├── PlaylistModel.swift
    │   ├── SettingsModel.swift
    │   ├── ChildProfileModel.swift
    │   └── SubscriptionModel.swift
    ├── Services/
    │   ├── StorageService.swift
    │   ├── AppThemeService.swift
    │   ├── ApiKeyService.swift
    │   ├── ParentalControlService.swift
    │   ├── YouTubeService.swift
    │   ├── YouTubeBackendService.swift
    │   ├── AuthService.swift
    │   └── SubscriptionService.swift
    ├── Theme/
    │   └── AppTheme.swift
    ├── Utils/
    │   └── Constants.swift
    ├── Views/
    │   ├── HomeView.swift
    │   ├── CategoriesView.swift
    │   ├── SearchView.swift
    │   ├── PlaylistsView.swift
    │   ├── CuratedContentView.swift
    │   ├── VideoPlayerView.swift
    │   ├── ParentalSettingsView.swift
    │   └── Components/
    │       ├── VideoCardView.swift
    │       └── TimeLimitWidget.swift
    ├── Assets.xcassets/
    └── Info.plist
```

## Features (aligned with Flutter app)

- **Home**: Trending kids shows, recommended for you, quick access (Categories, Favorites, Playlists), Learn & Play chips.
- **Categories**: Grid of kid-safe categories; each opens a category video list.
- **Search**: YouTube search (sanitized, kid-safe) with parental filtering.
- **Video player**: WebView-based YouTube embed; watch history and daily usage recorded for parental limits.
- **Playlists / Favorites**: Local playlists and curated (favorites) list.
- **Parental settings**: Enable/disable controls, daily time limit, parent password, break reminders.
- **Auth**: Optional Firebase Auth + Google Sign-In (when Firebase and GoogleSignIn are added).
- **Subscription**: In-memory/local tier (Bright Kids / Zen Kids); can be wired to your backend later.

## Backend (Firebase Functions)

The app can use the same Firebase Functions as the Flutter app for YouTube (e.g. `youtubeSearch`, `youtubeVideo`). The base URL is set in `YouTubeBackendService.swift` (`kids-attention-app`). Change it if your project name differs.

## Notes

- **Portrait only** by default (matches Flutter).
- **Firebase is optional**: the app compiles and runs without Firebase; auth and analytics only activate after you add the SDK and `GoogleService-Info.plist`.
- When you create your **Apple Developer account**, set the bundle ID and team in Signing & Capabilities and add the app in App Store Connect for TestFlight/App Store when ready.
