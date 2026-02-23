import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/parental_control_service.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/youtube_service.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../models/video_model.dart';
import '../models/subscription_model.dart';
import '../models/child_profile_model.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../widgets/time_limit_widget.dart';
import '../widgets/video_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/animated_button.dart';
import '../widgets/tier_badge.dart';
import 'search_screen.dart';
import 'categories_screen.dart';
import 'playlists_screen.dart';
import 'parental_settings_screen.dart';
import 'curated_content_screen.dart';
import 'account_settings_screen.dart';
import 'video_player_screen.dart';
import 'category_videos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentalControlService _parentalService = ParentalControlService();
  final AuthService _authService = AuthService();
  final UserProfileService _profileService = UserProfileService();
  final StorageService _storageService = StorageService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final YouTubeService _youtubeService = YouTubeService();
  int _remainingMinutes = -1;
  bool _isLimitExceeded = false;
  final ScrollController _scrollController = ScrollController();
  bool _isSigningIn = false;
  List<VideoModel> _trendingShows = [];
  bool _isLoadingTrending = false;
  List<VideoModel> _recommendedVideos = [];
  bool _isLoadingRecommendations = false;
  SubscriptionModel _subscription = SubscriptionModel();
  StreamSubscription<ChildProfileModel?>? _activeProfileSubscription;
  String? _activeProfileId;
  String? _recommendationEmptyReason;
  String? _trendingEmptyReason;
  int? _recommendationsFetchedCount;
  int? _recommendationsAllowedCount;
  int? _trendingFetchedCount;
  int? _trendingAllowedCount;

  @override
  void initState() {
    super.initState();
    _checkTimeLimit();
    _loadSubscription();
    _setupActiveProfileListener();
    // Load cached content first, then refresh in background
    Future.microtask(() async {
      await _loadCachedContent();
      // Then refresh from API
      _loadTrendingShows();
      _loadRecommendations();
    });
  }

  Future<void> _loadCachedContent() async {
    try {
      // Load cached trending (12h cache)
      final cachedTrending = await _storageService.getCachedApiData(
        'trending_kids_shows',
        maxAge: const Duration(hours: 12),
      );
      if (cachedTrending != null) {
        final rawVideos = cachedTrending['videos'] as List?;
        if (rawVideos != null && mounted) {
          final videos = rawVideos
              .whereType<Map>()
              .map((item) => VideoModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          if (videos.isNotEmpty) {
            setState(() {
              _trendingShows = videos.take(5).toList();
            });
          }
        }
      }

      // Load cached recommendations (12h cache)
      final cachedRecommendations = await _storageService.getCachedApiData(
        'recommendations',
        maxAge: const Duration(hours: 12),
      );
      if (cachedRecommendations != null) {
        final rawVideos = cachedRecommendations['videos'] as List?;
        if (rawVideos != null && mounted) {
          final videos = rawVideos
              .whereType<Map>()
              .map((item) => VideoModel.fromJson(Map<String, dynamic>.from(item)))
              .toList();
          if (videos.isNotEmpty) {
            setState(() {
              _recommendedVideos = videos.take(5).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached content: $e');
      // Continue anyway - will load from API
    }
  }

  Future<void> _refreshContent() async {
    await Future.wait([
      _loadTrendingShows(),
      _loadRecommendations(),
    ]);
  }

  Future<void> _setupActiveProfileListener() async {
    final active = await _storageService.getActiveProfile();
    _activeProfileId = active?.id;
    _activeProfileSubscription = StorageService.activeProfileChanges.listen((profile) {
      final newId = profile?.id;
      if (!mounted || newId == _activeProfileId) return;
      _activeProfileId = newId;
      _loadRecommendations();
      _loadTrendingShows();
    });
  }

  Future<void> _loadSubscription() async {
    final subscription = await _subscriptionService.getSubscription();
    if (mounted) {
      setState(() {
        _subscription = subscription;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    if (!Constants.hasValidApiKey) {
      if (mounted) {
        setState(() {
          _recommendedVideos = [];
          _isLoadingRecommendations = false;
          _recommendationEmptyReason = 'YouTube API key is missing or invalid.';
          _recommendationsFetchedCount = 0;
          _recommendationsAllowedCount = 0;
        });
      }
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationEmptyReason = null;
      _recommendationsFetchedCount = null;
      _recommendationsAllowedCount = null;
    });

    try {
      // Add timeout to prevent hanging
      await Future.any([
        _loadRecommendationsInternal(),
        Future.delayed(const Duration(seconds: 10)),
      ]);
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
          _recommendationEmptyReason = 'Could not load recommendations right now.';
          _recommendationsFetchedCount = null;
          _recommendationsAllowedCount = null;
        });
      }
    }
  }

  Future<void> _loadRecommendationsInternal() async {
    try {
      // First try to get recommendations based on watch history
      final activeProfile = await _storageService.getActiveProfile();
      _activeProfileId = activeProfile?.id;
      final watchHistory = await _storageService.getWatchHistory(
        profileId: activeProfile?.id,
      );
      List<VideoModel> recommendations = [];
      final profileTopics = activeProfile?.preferredTopics ?? const <String>[];
      final ageTopic = _getAgeRecommendationTopic(activeProfile?.age);

      if (watchHistory.isNotEmpty) {
        // Extract keywords from watch history titles for personalized recommendations
        final historyKeywords = <String>{};
        for (final video in watchHistory.take(5)) {
          // Extract meaningful words from titles
          final words = video.title.toLowerCase().split(RegExp(r'[\s\-\|]+'));
          for (final word in words) {
            if (word.length > 3 && !_commonWords.contains(word)) {
              historyKeywords.add(word);
            }
          }
        }

        // Search for videos based on extracted keywords
        if (historyKeywords.isNotEmpty) {
          final profileTerms = <String>{
            ...profileTopics.take(2),
            if (ageTopic.isNotEmpty) ageTopic,
          };
          final searchQuery =
              '${historyKeywords.take(3).join(' ')} ${profileTerms.join(' ')} kids'
                  .trim();
          try {
            recommendations = await _youtubeService.searchVideos(
              searchQuery,
              maxResults: 5,
            );
          } catch (e) {
            debugPrint('Error searching recommendations: $e');
          }
        }
      }

      // If personalized history-based search failed, use profile preferences.
      if (recommendations.isEmpty) {
        final profileQueryTerms = <String>{
          ...profileTopics.take(3),
          if (ageTopic.isNotEmpty) ageTopic,
        };
        if (profileQueryTerms.isNotEmpty) {
          try {
            recommendations = await _youtubeService.searchVideos(
              '${profileQueryTerms.join(' ')} kids videos',
              maxResults: 5,
            );
          } catch (e) {
            debugPrint('Error loading profile-based recommendations: $e');
          }
        }
      }

      // Final fallback: use general kids recommendations
      if (recommendations.isEmpty) {
        try {
          // Single query for faster loading
          recommendations = await _youtubeService.searchVideos(
            'popular educational kids videos',
            maxResults: 5,
          );
        } catch (e) {
          debugPrint('Error loading general recommendations: $e');
        }
      }

      // Filter based on parental controls and remove duplicates
      final uniqueIds = <String>{};
      final filteredRecommendations = <VideoModel>[];
      
      final allowChecks = await Future.wait(
        recommendations.map((video) => _parentalService.isVideoAllowed(video)),
      );
      for (int i = 0; i < recommendations.length; i++) {
        final video = recommendations[i];
        if (!uniqueIds.contains(video.id) && allowChecks[i]) {
          uniqueIds.add(video.id);
          filteredRecommendations.add(video);
        }
      }

      // Remove videos that are already in trending
      final trendingIds = _trendingShows.map((v) => v.id).toSet();
      filteredRecommendations.removeWhere((v) => trendingIds.contains(v.id));

      if (mounted) {
        final reason = await _resolveEmptyReason(
          fetchedCount: recommendations.length,
          filteredCount: filteredRecommendations.length,
        );
        // Cache the results
        try {
          await _storageService.setCachedApiData('recommendations', {
            'videos': filteredRecommendations.take(5).map((v) => v.toJson()).toList(),
          });
        } catch (e) {
          debugPrint('Error caching recommendations: $e');
        }

        setState(() {
          _recommendedVideos = filteredRecommendations.take(5).toList();
          _isLoadingRecommendations = false;
          _recommendationEmptyReason = _recommendedVideos.isEmpty
              ? reason ?? 'No recommendations available right now.'
              : null;
          _recommendationsFetchedCount = recommendations.length;
          _recommendationsAllowedCount = filteredRecommendations.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecommendations = false;
          _recommendationEmptyReason = _friendlyErrorReason(e);
          _recommendationsFetchedCount = null;
          _recommendationsAllowedCount = null;
        });
      }
    }
  }

  // Common words to exclude from keyword extraction
  static const _commonWords = {
    'the', 'and', 'for', 'with', 'this', 'that', 'from', 'have', 'will',
    'video', 'videos', 'kids', 'children', 'episode', 'full', 'official',
  };

  String _getAgeRecommendationTopic(int? age) {
    if (age == null) return '';
    if (age <= 4) return 'toddler learning';
    if (age <= 7) return 'early learning';
    if (age <= 12) return 'kids educational';
    return 'teen learning';
  }

  Future<void> _loadTrendingShows() async {
    if (!Constants.hasValidApiKey) {
      if (mounted) {
        setState(() {
          _trendingShows = [];
          _isLoadingTrending = false;
          _trendingEmptyReason = 'YouTube API key is missing or invalid.';
          _trendingFetchedCount = 0;
          _trendingAllowedCount = 0;
        });
      }
      return;
    }
    
    setState(() {
      _isLoadingTrending = true;
      _trendingEmptyReason = null;
      _trendingFetchedCount = null;
      _trendingAllowedCount = null;
    });

    try {
      // Add timeout to prevent hanging
      final shows = await _youtubeService.getTrendingKidsShows(maxResults: 5)
          .timeout(const Duration(seconds: 10));
      
      // Filter based on parental controls
      final filteredShows = <VideoModel>[];
      final allowChecks = await Future.wait(
        shows.map((show) => _parentalService.isVideoAllowed(show)),
      );
      for (int i = 0; i < shows.length; i++) {
        if (allowChecks[i]) {
          filteredShows.add(shows[i]);
        }
      }

      if (mounted) {
        final reason = await _resolveEmptyReason(
          fetchedCount: shows.length,
          filteredCount: filteredShows.length,
        );
        // Cache the results
        try {
          await _storageService.setCachedApiData('trending_kids_shows', {
            'videos': filteredShows.take(5).map((v) => v.toJson()).toList(),
          });
        } catch (e) {
          debugPrint('Error caching trending: $e');
        }

        setState(() {
          _trendingShows = filteredShows.take(5).toList();
          _isLoadingTrending = false;
          _trendingEmptyReason = _trendingShows.isEmpty
              ? reason ?? 'No trending videos available right now.'
              : null;
          _trendingFetchedCount = shows.length;
          _trendingAllowedCount = filteredShows.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading trending shows: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
          _trendingEmptyReason = _friendlyErrorReason(e);
          _trendingFetchedCount = null;
          _trendingAllowedCount = null;
        });
      }
    }
  }

  Future<String?> _resolveEmptyReason({
    required int fetchedCount,
    required int filteredCount,
  }) async {
    if (fetchedCount > 0 && filteredCount == 0) {
      final settings = await _parentalService.getSettings();
      if (settings.whitelistedChannels.isNotEmpty) {
        return 'No videos match your allowed channels list.';
      }
      if (settings.blockedKeywords.isNotEmpty || settings.blacklistedChannels.isNotEmpty) {
        return 'Parental filters are blocking available videos.';
      }
      return 'Available videos were filtered for safety.';
    }
    if (fetchedCount == 0) {
      return 'No videos returned right now. Check API quota or try again later.';
    }
    return null;
  }

  String _friendlyErrorReason(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('quota') || message.contains('403')) {
      return 'YouTube API quota exceeded. Please try later.';
    }
    if (message.contains('api key') || message.contains('key')) {
      return 'YouTube API key is invalid or restricted.';
    }
    if (message.contains('timeout')) {
      return 'Request timed out. Check internet and retry.';
    }
    return 'Could not load videos right now.';
  }

  Widget _buildCompactFeedEmptyState({
    required String title,
    required String reason,
    required IconData icon,
    required Color iconColor,
    int? fetchedCount,
    int? allowedCount,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final debugLine = (fetchedCount != null && allowedCount != null)
        ? 'Debug: fetched $fetchedCount, allowed $allowedCount'
        : null;
    return SizedBox(
      height: 180,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 34),
              const SizedBox(height: 10),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                reason,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (debugLine != null) ...[
                const SizedBox(height: 6),
                Text(
                  debugLine,
                  style: textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activeProfileSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkTimeLimit() async {
    try {
      // Add timeout to prevent hanging
      final remaining = await _parentalService.getRemainingTimeMinutes()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Timeout getting remaining time');
        return -1; // No limit if timeout
      });
      
      final exceeded = await _parentalService.isTimeLimitExceeded()
          .timeout(const Duration(seconds: 5), onTimeout: () {
        debugPrint('Timeout checking time limit');
        return false; // Not exceeded if timeout
      });
      
      if (mounted) {
        setState(() {
          _remainingMinutes = remaining;
          _isLimitExceeded = exceeded;
        });
      }
    } catch (e) {
      // If there's an error, default to no limit so app can still function
      debugPrint('Error checking time limit: $e');
      if (mounted) {
        setState(() {
          _remainingMinutes = -1; // -1 means no limit (don't show widget)
          _isLimitExceeded = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // Prevent multiple simultaneous sign-in attempts
    if (_isSigningIn) {
      debugPrint('⚠️ Sign-in already in progress, ignoring duplicate request');
      return;
    }
    
    // Don't sign in if already signed in
    if (_authService.isSignedIn) {
      debugPrint('⚠️ User already signed in, ignoring sign-in request');
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      debugPrint('🔵 Starting Google Sign-In from UI...');
      
      final userCredential = await _authService.signInWithGoogle()
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () {
              throw TimeoutException('Sign-in process took too long. Please try again.');
            },
          );

      if (userCredential != null && mounted) {
        // Wait a moment for Firebase to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force state update to clear signing in status
        if (mounted) {
          setState(() {
            _isSigningIn = false;
          });
        }
        
        // Verify Firebase authentication state
        final isAuthenticated = _authService.isSignedIn;
        final currentUser = _authService.currentUser;
        
        debugPrint('Post-sign-in verification:');
        debugPrint('   isSignedIn: $isAuthenticated');
        debugPrint('   currentUser: ${currentUser?.uid ?? "null"}');
        
        if (isAuthenticated && currentUser != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome, ${_authService.displayName ?? _authService.email ?? "User"}!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          debugPrint('⚠️ WARNING: Sign-in completed but user not authenticated in Firebase!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign in completed but authentication verification failed. Please try again.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      } else if (mounted) {
        debugPrint('ℹ️ Sign-in was canceled or returned null');
        // Make sure to clear signing in state even if canceled
        setState(() {
          _isSigningIn = false;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Sign-in timeout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign-in took too long. Please check your internet connection and try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _handleGoogleSignIn();
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Sign-in error: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');
      debugPrint('❌ Stack trace: $stackTrace');
      if (mounted) {
        String errorMessage = 'Sign in failed';
        
        // Get error string and clean it up
        String errorString = e.toString();
        
        // Log the raw error for debugging
        debugPrint('❌ Raw error string: $errorString');
        
        // First, try to extract the actual error message from Exception
        if (e is Exception) {
          final exceptionMessage = e.toString();
          // Remove "Exception: " prefix if present
          if (exceptionMessage.startsWith('Exception: ')) {
            errorMessage = exceptionMessage.substring(11);
          } else if (exceptionMessage.contains(':')) {
            final parts = exceptionMessage.split(':');
            if (parts.length > 1) {
              errorMessage = parts.skip(1).join(':').trim();
            }
          } else {
            errorMessage = exceptionMessage;
          }
        }
        
        // If we still have a generic message, try to parse it
        if (errorMessage == 'Sign in failed' || errorMessage.isEmpty) {
          if (errorString.contains('network') || errorString.contains('Network')) {
            errorMessage = 'Network error. Please check your internet connection.';
          } else if (errorString.contains('timeout') || errorString.contains('Timeout')) {
            errorMessage = 'Request timed out. Please try again.';
          } else if (errorString.contains('cancelled') || errorString.contains('canceled')) {
            errorMessage = 'Sign in was cancelled.';
            // Don't show error for cancellation, just return
            return;
          } else if (errorString.contains('platform_exception') || errorString.contains('PlatformException')) {
            // Extract meaningful message from platform exception
            final parts = errorString.split(',');
            if (parts.length > 1) {
              final message = parts.first.replaceAll('PlatformException(', '').trim();
              errorMessage = 'Sign in failed: $message';
            } else {
              errorMessage = 'Sign in failed. Check Firebase Console → Authentication → Sign-in method.';
            }
          } else if (errorString.contains('operation-not-allowed') || errorString.contains('Google Sign-In is not enabled')) {
            errorMessage = 'Google Sign-In not enabled. Enable it in Firebase Console → Authentication → Sign-in method.';
          } else {
            // Try to extract meaningful error message
            String cleanedError = errorString
                .replaceAll(RegExp(r',\s*null\s*,?'), '')
                .replaceAll(RegExp(r'\(null\)'), '')
                .replaceAll(RegExp(r'\s*null\s*'), '')
                .trim();
            
            cleanedError = cleanedError.replaceAll(RegExp(r'[,)]+$'), '').trim();
            
            final parts = cleanedError.split(':');
            if (parts.length > 1) {
              final lastPart = parts.last.trim();
              if (lastPart.isNotEmpty && 
                  !lastPart.contains('null') && 
                  lastPart.length > 2) {
                errorMessage = lastPart;
              } else {
                errorMessage = 'Sign in failed. Enable Google Sign-In in Firebase Console.';
              }
            } else if (cleanedError.isNotEmpty && !cleanedError.contains('null')) {
              errorMessage = cleanedError;
            } else {
              errorMessage = 'Sign in failed. Enable Google Sign-In in Firebase Console → Authentication → Sign-in method.';
            }
          }
        }
        
        // Ensure error message is not empty
        if (errorMessage.isEmpty) {
          errorMessage = 'Sign in failed. Enable Google Sign-In in Firebase Console → Authentication → Sign-in method.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _handleGoogleSignIn();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    try {
      debugPrint('🔵 Starting sign out...');
      await _authService.signOut()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ Sign out timeout');
              throw TimeoutException('Sign out timed out');
            },
          );
      
      debugPrint('✅ Sign out successful');
      
      if (mounted) {
        // Force state update
        setState(() {
          _isSigningIn = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('❌ Sign out timeout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign out timed out. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString().split(':').last.trim()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildHeader() {
    return StreamBuilder(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Use snapshot data if available, otherwise fall back to current state
        final isSignedIn = snapshot.hasData && snapshot.data != null 
            ? true 
            : _authService.isSignedIn;
        final photoURL = _authService.photoURL;
        
        // Don't show "Signing in..." if user is actually signed in
        final showSigningIn = _isSigningIn && !isSignedIn;

        final textTheme = Theme.of(context).textTheme;
        final colorScheme = Theme.of(context).colorScheme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade400,
                Colors.blue.shade400,
                Colors.pink.shade300,
              ],
            ),
          ),
          child: Row(
            children: [
              // Kids TV title
              Text(
                'Kids TV',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              // Tier badge
              TierBadge(
                subscription: _subscription,
                size: 16,
              ),
              const SizedBox(width: 12),
              // Search button - moved to header
              GestureDetector(
                onTap: _isLimitExceeded
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search,
                        color: _isLimitExceeded ? Colors.white54 : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Search',
                        style: textTheme.bodyMedium?.copyWith(
                          color: _isLimitExceeded ? Colors.white54 : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Right side icons
              if (isSignedIn)
                PopupMenuButton<String>(
                  icon: FutureBuilder<String?>(
                    future: _profileService.getProfilePhotoUrl(),
                    builder: (context, snapshot) {
                      final photoUrl = snapshot.data ?? photoURL;
                      return photoUrl != null
                          ? CircleAvatar(
                              radius: 16,
                              backgroundImage: NetworkImage(photoUrl),
                              onBackgroundImageError: (exception, stackTrace) {
                                debugPrint('Error loading profile image: $exception');
                              },
                            )
                          : const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.account_circle, color: Colors.purple, size: 18),
                            );
                    },
                  ),
                  color: colorScheme.surface,
                  onSelected: (value) {
                    if (value == 'account') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountSettingsScreen(),
                        ),
                      );
                    } else if (value == 'signout') {
                      _handleSignOut();
                    }
                  },
                  onCanceled: () {
                    debugPrint('Profile menu dismissed');
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'account',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Account Settings',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            'Sign Out',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else if (showSigningIn)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else ...[
                // Sign in button (compact)
                Material(
                  color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: _isSigningIn ? null : _handleGoogleSignIn,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sign in',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAccessCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required String subtitle,
  }) {
    final card = Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    if (onTap != null) {
      return AnimatedButton(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: textTheme.headlineMedium,
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See All',
                    style: textTheme.labelLarge,
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final card = SizedBox(
      width: 140,
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    if (onTap != null) {
      return AnimatedButton(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshContent,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh even when content fits
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Time limit widget - only show if we have a valid limit (>= 0)
                      // -1 means no limit or still loading, so don't show anything
                      if (_remainingMinutes >= 0)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: TimeLimitWidget(
                          remainingMinutes: _remainingMinutes,
                          isLimitExceeded: _isLimitExceeded,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParentalSettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // Warning if time limit exceeded
                    if (_isLimitExceeded)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.red.shade300, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Daily time limit reached. Please ask a parent to adjust settings.',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Quick Access Section - Categories and Favorites
                    _buildSection(
                      title: 'Quick Access',
                      child: SizedBox(
                        height: 160,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildQuickAccessCard(
                              title: 'Categories',
                              subtitle: 'Browse by type',
                              icon: Icons.category_rounded,
                              color: Colors.purple.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CategoriesScreen(),
                                        ),
                                      );
                                    },
                            ),
                            _buildQuickAccessCard(
                              title: 'Favorites',
                              subtitle: 'Saved content',
                              icon: Icons.favorite_rounded,
                              color: Colors.red.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CuratedContentScreen(),
                                        ),
                                      );
                                    },
                            ),
                            _buildQuickAccessCard(
                              title: 'Playlists',
                              subtitle: 'My collections',
                              icon: Icons.playlist_play_rounded,
                              color: Colors.pink.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const PlaylistsScreen(),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Learning Categories Section
                    _buildSection(
                      title: 'Learn & Play',
                      child: SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildCategoryCard(
                              title: 'Alphabets',
                              icon: Icons.abc_rounded,
                              color: Colors.blue.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryVideosScreen(
                                            categoryName: 'Alphabets',
                                            searchQuery: 'alphabet learning for kids ABC',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            _buildCategoryCard(
                              title: 'Numbers',
                              icon: Icons.numbers_rounded,
                              color: Colors.green.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryVideosScreen(
                                            categoryName: 'Numbers',
                                            searchQuery: 'numbers counting for kids 123',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            _buildCategoryCard(
                              title: 'Colors',
                              icon: Icons.palette_rounded,
                              color: Colors.pink.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryVideosScreen(
                                            categoryName: 'Colors',
                                            searchQuery: 'colors learning for kids rainbow',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            _buildCategoryCard(
                              title: 'Shapes',
                              icon: Icons.shape_line_rounded,
                              color: Colors.orange.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryVideosScreen(
                                            categoryName: 'Shapes',
                                            searchQuery: 'shapes learning for kids circle square triangle',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            _buildCategoryCard(
                              title: 'Animals',
                              icon: Icons.pets_rounded,
                              color: Colors.teal.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryVideosScreen(
                                            categoryName: 'Animals',
                                            searchQuery: 'animals for kids learning zoo',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                            _buildCategoryCard(
                              title: 'Nursery Rhymes',
                              icon: Icons.music_note_rounded,
                              color: Colors.purple.shade400,
                              onTap: _isLimitExceeded
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CategoryVideosScreen(
                                            categoryName: 'Nursery Rhymes',
                                            searchQuery: 'nursery rhymes for kids songs',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Recommended For You Section
                    _buildSection(
                      title: 'Recommended For You',
                      onSeeAll: _isLimitExceeded || _recommendedVideos.isEmpty
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SearchScreen(),
                                ),
                              );
                            },
                      child: _isLoadingRecommendations
                          ? SizedBox(
                              height: 180,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    width: 150,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: const VideoCardSkeleton(),
                                  ),
                                ),
                              ),
                            )
                          : _recommendedVideos.isEmpty
                              ? _buildCompactFeedEmptyState(
                                  title: 'No Recommendations Yet',
                                  reason: _recommendationEmptyReason ??
                                      'Watch some videos to get personalized recommendations.',
                                  icon: Icons.recommend,
                                  iconColor: Colors.blue,
                                  fetchedCount: _recommendationsFetchedCount,
                                  allowedCount: _recommendationsAllowedCount,
                                )
                              : SizedBox(
                                  height: 180,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    children: _recommendedVideos.map((video) {
                                      return Container(
                                        width: 150,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: VideoCard(
                                          video: video,
                                          onTap: _isLimitExceeded
                                              ? null
                                              : () {
                                                  Navigator.push(
                                                    context,
                                                    SmoothPageRoute(
                                                      page: VideoPlayerScreen(
                                                        video: video,
                                                      ),
                                                    ),
                                                  );
                                                },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                    ),

                    const SizedBox(height: 16),

                    // Trending Kids Shows Section
                    _buildSection(
                      title: 'Trending Kids Shows',
                      onSeeAll: _isLimitExceeded
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CategoriesScreen(),
                                ),
                              );
                            },
                      child: _isLoadingTrending
                          ? SizedBox(
                              height: 200,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                children: List.generate(
                                  3,
                                  (index) => Container(
                                    width: 160,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: const VideoCardSkeleton(),
                                  ),
                                ),
                              ),
                            )
                          : _trendingShows.isEmpty
                              ? _buildCompactFeedEmptyState(
                                  title: 'No Trending Shows',
                                  reason: _trendingEmptyReason ??
                                      'Check back later for trending kids content.',
                                  icon: Icons.trending_up,
                                  iconColor: Colors.orange,
                                  fetchedCount: _trendingFetchedCount,
                                  allowedCount: _trendingAllowedCount,
                                )
                              : SizedBox(
                                  height: 200,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    children: _trendingShows.map((video) {
                                      return Container(
                                        width: 160,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: VideoCard(
                                          video: video,
                                          onTap: _isLimitExceeded
                                              ? null
                                              : () {
                                                  Navigator.push(
                                                    context,
                                                    SmoothPageRoute(
                                                      page: VideoPlayerScreen(
                                                        video: video,
                                                      ),
                                                    ),
                                                  );
                                                },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                    ),

                    const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      // If there's an error building the home screen, show error UI
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error loading home screen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _remainingMinutes = -1;
                      _isLimitExceeded = false;
                    });
                    _checkTimeLimit();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

