const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// YouTube API key from Firebase config
const YOUTUBE_API_KEY = functions.config().youtube?.key || process.env.YOUTUBE_API_KEY;
const YOUTUBE_BASE_URL = 'https://www.googleapis.com/youtube/v3';

// Cache duration: 1 hour (3600 seconds)
const CACHE_DURATION = 3600;

/**
 * Search YouTube videos with caching
 * GET /youtube/search?q=query&maxResults=25
 */
exports.youtubeSearch = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const query = req.query.q;
    const maxResults = parseInt(req.query.maxResults) || 25;

    // Validate input
    if (!query || query.trim().length < 2) {
      return res.status(400).json({ 
        error: 'Invalid query. Query must be at least 2 characters.' 
      });
    }

    if (!YOUTUBE_API_KEY) {
      return res.status(500).json({ 
        error: 'YouTube API key not configured' 
      });
    }

    // Check cache first
    const cacheKey = `youtube_search_${query}_${maxResults}`;
    const cacheRef = admin.firestore().collection('cache').doc(cacheKey);
    const cachedDoc = await cacheRef.get();

    if (cachedDoc.exists) {
      const cachedData = cachedDoc.data();
      const cacheAge = Date.now() - cachedData.timestamp;

      // Return cached result if still valid
      if (cacheAge < CACHE_DURATION * 1000) {
        console.log(`Cache hit for query: ${query}`);
        return res.json({
          ...cachedData.data,
          cached: true,
          cacheAge: Math.floor(cacheAge / 1000)
        });
      }
    }

    // Make YouTube API request
    console.log(`Making YouTube API request for query: ${query}`);
    const response = await axios.get(`${YOUTUBE_BASE_URL}/search`, {
      params: {
        part: 'snippet',
        q: query.trim(),
        type: 'video',
        videoEmbeddable: true,
        safeSearch: 'strict',
        maxResults: Math.min(maxResults, 50), // Cap at 50
        key: YOUTUBE_API_KEY
      },
      timeout: 10000 // 10 second timeout
    });

    // Check for API errors
    if (response.data.error) {
      console.error('YouTube API Error:', response.data.error);
      return res.status(400).json({ 
        error: response.data.error.message || 'YouTube API error' 
      });
    }

    const result = {
      items: response.data.items || [],
      pageInfo: response.data.pageInfo || {}
    };

    // Cache the result
    await cacheRef.set({
      data: result,
      timestamp: Date.now(),
      query: query.trim(),
      maxResults: maxResults
    });

    // Return result
    res.json({
      ...result,
      cached: false
    });

  } catch (error) {
    console.error('Error in youtubeSearch:', error);
    
    if (error.response) {
      // YouTube API error
      const status = error.response.status;
      const message = error.response.data?.error?.message || 'YouTube API error';
      
      if (status === 403) {
        return res.status(403).json({ 
          error: 'Quota exceeded or API key invalid' 
        });
      }
      
      return res.status(status).json({ error: message });
    }
    
    res.status(500).json({ 
      error: 'Internal server error',
      message: error.message 
    });
  }
});

/**
 * Get video details
 * GET /youtube/video?id=videoId
 */
exports.youtubeVideo = functions.https.onRequest(async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const videoId = req.query.id;

    if (!videoId) {
      return res.status(400).json({ error: 'Video ID required' });
    }

    if (!YOUTUBE_API_KEY) {
      return res.status(500).json({ error: 'YouTube API key not configured' });
    }

    // Check cache
    const cacheKey = `youtube_video_${videoId}`;
    const cacheRef = admin.firestore().collection('cache').doc(cacheKey);
    const cachedDoc = await cacheRef.get();

    if (cachedDoc.exists) {
      const cachedData = cachedDoc.data();
      const cacheAge = Date.now() - cachedData.timestamp;

      if (cacheAge < CACHE_DURATION * 1000) {
        return res.json({
          ...cachedData.data,
          cached: true
        });
      }
    }

    // Make API request
    const response = await axios.get(`${YOUTUBE_BASE_URL}/videos`, {
      params: {
        part: 'snippet,contentDetails,statistics',
        id: videoId,
        key: YOUTUBE_API_KEY
      },
      timeout: 10000
    });

    if (response.data.error) {
      return res.status(400).json({ error: response.data.error.message });
    }

    const result = {
      items: response.data.items || []
    };

    // Cache result
    await cacheRef.set({
      data: result,
      timestamp: Date.now(),
      videoId: videoId
    });

    res.json({
      ...result,
      cached: false
    });

  } catch (error) {
    console.error('Error in youtubeVideo:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * Clean up old cache entries (runs daily)
 */
exports.cleanupCache = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const cacheRef = admin.firestore().collection('cache');
    const cutoffTime = Date.now() - (CACHE_DURATION * 2 * 1000); // 2x cache duration
    
    const snapshot = await cacheRef
      .where('timestamp', '<', cutoffTime)
      .limit(500)
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${snapshot.size} cache entries`);
    return null;
  });

