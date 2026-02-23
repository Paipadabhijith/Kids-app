# ⚡ Quick Start: Auto-Scaling Backend (5 Minutes)

## 🎯 Goal
Set up a backend that starts FREE and auto-scales to handle millions of users.

---

## Step 1: Install Firebase CLI (2 minutes)

```bash
npm install -g firebase-tools
firebase login
```

---

## Step 2: Initialize Functions (1 minute)

```bash
cd c:\Kids\kids-tv
firebase init functions
```

**Select:**
- ✅ Use existing project: `kids-attention-app`
- ✅ JavaScript
- ✅ Yes to ESLint
- ✅ Yes to install dependencies

---

## Step 3: Set API Key (30 seconds)

```bash
firebase functions:config:set youtube.key="YOUR_YOUTUBE_API_KEY_HERE"
```

**Get your API key from:** [Google Cloud Console](https://console.cloud.google.com/)

---

## Step 4: Deploy (1 minute)

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

**Copy the URL** from output (e.g., `https://us-central1-kids-attention-app.cloudfunctions.net/youtubeSearch`)

---

## Step 5: Update Flutter App (30 seconds)

1. **Open:** `lib/services/youtube_backend_service.dart`
2. **Update URL:**
   ```dart
   static const String backendBaseUrl = 'https://us-central1-kids-attention-app.cloudfunctions.net';
   ```
   (Use the URL from Step 4)

3. **In your screens** (home_screen.dart, search_screen.dart, etc.):
   ```dart
   // Change from:
   final youtubeService = YouTubeService(apiKey: Constants.youtubeApiKey);
   
   // To:
   final youtubeService = YouTubeBackendService();
   ```

---

## ✅ Done!

Your backend is now:
- ✅ **Deployed** and ready
- ✅ **Auto-scaling** (handles any number of users)
- ✅ **Caching** results (reduces API calls)
- ✅ **FREE** to start (or ~$0-5/month)

---

## 🧪 Test It

1. Run your Flutter app
2. Search for videos
3. Check Firebase Console → Functions → Logs
4. See cached results on second search (faster!)

---

## 💰 Cost

- **0-2M requests/month:** FREE
- **2M+ requests/month:** $0.40 per million
- **For 10,000 users:** ~$0-2/month

---

## 📚 Full Guide

See `AUTO_SCALE_SETUP_GUIDE.md` for detailed documentation.





