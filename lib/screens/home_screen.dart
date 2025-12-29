import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/parental_control_service.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/youtube_service.dart';
import '../models/video_model.dart';
import '../utils/constants.dart';
import '../widgets/time_limit_widget.dart';
import '../widgets/video_card.dart';
import 'search_screen.dart';
import 'categories_screen.dart';
import 'playlists_screen.dart';
import 'parental_settings_screen.dart';
import 'curated_content_screen.dart';
import 'account_settings_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentalControlService _parentalService = ParentalControlService();
  final AuthService _authService = AuthService();
  final UserProfileService _profileService = UserProfileService();
  final YouTubeService _youtubeService = YouTubeService(
    apiKey: Constants.youtubeApiKey,
  );
  int _remainingMinutes = -1;
  bool _isLimitExceeded = false;
  final ScrollController _scrollController = ScrollController();
  bool _isSigningIn = false;
  List<VideoModel> _trendingShows = [];
  bool _isLoadingTrending = false;

  @override
  void initState() {
    super.initState();
    _checkTimeLimit();
    _loadTrendingShows();
  }

  Future<void> _loadTrendingShows() async {
    if (!Constants.hasValidApiKey) return;
    
    setState(() {
      _isLoadingTrending = true;
    });

    try {
      final shows = await _youtubeService.getTrendingKidsShows(maxResults: 10);
      
      // Filter based on parental controls
      final filteredShows = <VideoModel>[];
      for (final show in shows) {
        final isAllowed = await _parentalService.isVideoAllowed(show);
        if (isAllowed) {
          filteredShows.add(show);
        }
      }

      if (mounted) {
        setState(() {
          _trendingShows = filteredShows;
          _isLoadingTrending = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading trending shows: $e');
      if (mounted) {
        setState(() {
          _isLoadingTrending = false;
        });
      }
    }
  }

  @override
  void dispose() {
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
        final displayName = _authService.displayName;
        final email = _authService.email;
        final photoURL = _authService.photoURL;
        
        // Don't show "Signing in..." if user is actually signed in
        final showSigningIn = _isSigningIn && !isSignedIn;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kids TV',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    children: [
                      if (isSignedIn)
                        PopupMenuButton<String>(
                          icon: FutureBuilder<String?>(
                            future: _profileService.getProfilePhotoUrl(),
                            builder: (context, snapshot) {
                              final photoUrl = snapshot.data ?? photoURL;
                              return photoUrl != null
                                  ? CircleAvatar(
                                      radius: 18,
                                      backgroundImage: NetworkImage(photoUrl),
                                      onBackgroundImageError: (exception, stackTrace) {
                                        debugPrint('Error loading profile image: $exception');
                                      },
                                    )
                                  : const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.account_circle, color: Colors.purple, size: 20),
                                    );
                            },
                          ),
                          color: Colors.white,
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
                            // Menu was dismissed without selection - do nothing
                            debugPrint('Profile menu dismissed');
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'account',
                              child: Row(
                                children: [
                                  Icon(Icons.settings, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Account Settings'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'signout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Sign Out'),
                                ],
                              ),
                            ),
                          ],
                        )
                      else if (showSigningIn)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ParentalSettingsScreen(),
                              ),
                            );
                            if (result == true) {
                              _checkTimeLimit();
                            }
                          },
                          tooltip: 'Parental Settings',
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Fun & Educational Videos for Kids',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              // Google Sign-In Button (only show if not signed in and not currently signing in)
              if (!isSignedIn && !showSigningIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                    icon: _isSigningIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    label: Text(
                      showSigningIn ? 'Signing in...' : 'Sign in with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
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
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
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
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    VoidCallback? onSeeAll,
  }) {
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
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
                child: SingleChildScrollView(
                  controller: _scrollController,
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
                          borderRadius: BorderRadius.circular(16),
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

                    // Quick Access Section
                    _buildSection(
                      title: 'Quick Access',
                      child: SizedBox(
                        height: 180,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildQuickAccessCard(
                              title: 'Search',
                              subtitle: 'Find videos',
                              icon: Icons.search_rounded,
                              color: Colors.blue.shade400,
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
                            ),
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
                              title: 'Playlists',
                              subtitle: 'My favorites',
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
                            _buildQuickAccessCard(
                              title: 'Kid-Safe',
                              subtitle: 'Curated content',
                              icon: Icons.favorite_rounded,
                              color: Colors.orange.shade400,
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
                                          builder: (context) => const CategoriesScreen(),
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
                                          builder: (context) => const CategoriesScreen(),
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
                                          builder: (context) => const CategoriesScreen(),
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
                                          builder: (context) => const CategoriesScreen(),
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
                                          builder: (context) => const CategoriesScreen(),
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
                                          builder: (context) => const CategoriesScreen(),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

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
                          ? const SizedBox(
                              height: 200,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _trendingShows.isEmpty
                              ? SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.trending_up,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No trending shows available',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                                    MaterialPageRoute(
                                                      builder: (context) => VideoPlayerScreen(
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

