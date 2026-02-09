import 'dart:async' show Timer, unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import '../services/parental_control_service.dart';
import '../services/video_filter_service.dart';
import '../services/binaural_beats_service.dart';
import '../services/youtube_service.dart';

/// Fullscreen portrait Shorts player with swipe-up navigation.
/// Uses YoutubePlayer directly (not YoutubePlayerBuilder) to avoid
/// the internal 16:9 constraint and fill the entire screen.
class ShortsPlayerScreen extends StatefulWidget {
  final VideoModel initialVideo;
  final List<VideoModel>? relatedVideos;

  const ShortsPlayerScreen({
    super.key,
    required this.initialVideo,
    this.relatedVideos,
  });

  @override
  State<ShortsPlayerScreen> createState() => _ShortsPlayerScreenState();
}

class _ShortsPlayerScreenState extends State<ShortsPlayerScreen> {
  late PageController _pageController;
  final List<VideoModel> _videos = [];
  final Map<int, YoutubePlayerController> _controllers = {};
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _showSwipeHint = true;
  DateTime? _startTime;
  final StorageService _storageService = StorageService();
  final ParentalControlService _parentalService = ParentalControlService();
  final VideoFilterService _filterService = VideoFilterService();
  final BinauralBeatsService _beatsService = BinauralBeatsService();
  ColorFilter? _calmModeFilter;
  Timer? _breakCheckTimer;
  int _totalMinutesWatched = 0;
  bool _isOnBreak = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Build video list: initial video first, then any related
    _videos.add(widget.initialVideo);
    if (widget.relatedVideos != null) {
      for (final v in widget.relatedVideos!) {
        if (v.id != widget.initialVideo.id) {
          _videos.add(v);
        }
      }
    }

    // Create controller for the first video
    _getOrCreateController(0);

    // Lock to portrait for Shorts
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Hide status bar for true fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _startTime = DateTime.now();
    _startBreakCheckTimer();
    _loadCalmModeFilter();
    _startBinauralBeats();
    _loadRelatedShorts();

    // Hide swipe hint after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showSwipeHint = false);
    });
  }

  YoutubePlayerController _getOrCreateController(int index) {
    if (_controllers.containsKey(index)) return _controllers[index]!;

    final controller = YoutubePlayerController(
      initialVideoId: _videos[index].id,
      flags: YoutubePlayerFlags(
        autoPlay: index == _currentPage,
        mute: false,
        enableCaption: true,
        hideControls: false,
        controlsVisibleAtStart: true,
      ),
    );
    _controllers[index] = controller;
    return controller;
  }

  void _onPageChanged(int page) {
    // Pause the old video
    _controllers[_currentPage]?.pause();

    setState(() => _currentPage = page);

    // Play the new video
    final controller = _getOrCreateController(page);
    controller.play();

    // Preload adjacent pages
    if (page + 1 < _videos.length) _getOrCreateController(page + 1);

    // Load more when near end
    if (page >= _videos.length - 3 && !_isLoadingMore) {
      _loadRelatedShorts();
    }

    // Record history for previous video
    unawaited(
      _storageService.addToWatchHistory(_videos[_currentPage]).catchError((e) {
        debugPrint('Error adding to watch history: $e');
      }),
    );

    // Dispose controllers that are far from current page (memory management)
    _cleanupDistantControllers(page);
  }

  void _cleanupDistantControllers(int currentPage) {
    final keysToRemove = <int>[];
    for (final key in _controllers.keys) {
      if ((key - currentPage).abs() > 2) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }
  }

  Future<void> _loadRelatedShorts() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    try {
      final apiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
      if (apiKey.isEmpty) return;

      final youtubeService = YouTubeService(apiKey: apiKey);
      // Search for related kid-friendly Shorts
      final queries = [
        '${widget.initialVideo.channelTitle} shorts for kids',
        'kids shorts videos fun',
        'nursery rhymes shorts',
      ];
      final query = queries[_videos.length % queries.length];

      final videos = await youtubeService.searchVideos(
        query,
        maxResults: 10,
      );

      // Filter out duplicates
      final newVideos = videos
          .where((v) => !_videos.any((existing) => existing.id == v.id))
          .toList();

      if (mounted && newVideos.isNotEmpty) {
        setState(() => _videos.addAll(newVideos));
      }
    } catch (e) {
      debugPrint('Error loading related shorts: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _loadCalmModeFilter() async {
    final filter = await _filterService.getCalmModeFilter();
    if (mounted) setState(() => _calmModeFilter = filter);
  }

  Future<void> _startBinauralBeats() async {
    try {
      final settings = await _parentalService.getSettings();
      if (!settings.binauralBeatsEnabled) return;
      await _beatsService.setVolume(settings.binauralBeatsVolume);
      if (settings.windDownModeEnabled) {
        await _beatsService.startBeats(BeatFrequency.theta);
      } else if (settings.calmFocusModeEnabled) {
        await _beatsService.startBeats(BeatFrequency.alpha);
      }
    } catch (e) {
      debugPrint('Error starting binaural beats: $e');
    }
  }

  void _startBreakCheckTimer() {
    _breakCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_startTime != null && !_isOnBreak) {
        final watchDuration = DateTime.now().difference(_startTime!);
        final minutesWatched = watchDuration.inMinutes;
        if (minutesWatched > _totalMinutesWatched) {
          _totalMinutesWatched = minutesWatched;
          final shouldBreak = await _parentalService.shouldShowBreakReminder(
            _totalMinutesWatched,
          );
          if (shouldBreak && mounted) {
            _isOnBreak = true;
            _controllers[_currentPage]?.pause();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _breakCheckTimer?.cancel();
    _beatsService.dispose();

    // Record watch time
    if (_startTime != null && !_isOnBreak) {
      final watchDuration = DateTime.now().difference(_startTime!);
      final minutesWatched = watchDuration.inMinutes;
      if (minutesWatched > 0) {
        unawaited(
          _parentalService.recordVideoWatch(minutesWatched).catchError((e) {
            debugPrint('Error recording watch time: $e');
          }),
        );
      }
    }

    // Add current video to watch history
    unawaited(
      _storageService.addToWatchHistory(_videos[_currentPage]).catchError((e) {
        debugPrint('Error adding to watch history: $e');
      }),
    );

    unawaited(_beatsService.stopBeats());

    // Dispose all controllers
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();

    // Restore orientation and system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Vertical swipeable page view
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _videos.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildVideoPage(index);
            },
          ),

          // Overlay: Back button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Swipe up hint (auto-hides)
          if (_showSwipeHint && _videos.length > 1)
            Positioned(
              bottom: 140,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showSwipeHint ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white.withOpacity(0.7),
                        size: 36,
                      ),
                      Text(
                        'Swipe up for more',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Page indicator dots (right side, like TikTok/Shorts)
          if (_videos.length > 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _videos.length.clamp(0, 5),
                    (i) {
                      // Show dots around current page
                      final startIndex = (_currentPage - 2).clamp(0, (_videos.length - 5).clamp(0, _videos.length));
                      final dotIndex = startIndex + i;
                      if (dotIndex >= _videos.length) return const SizedBox.shrink();
                      return Container(
                        width: 6,
                        height: dotIndex == _currentPage ? 18 : 6,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: dotIndex == _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPage(int index) {
    final video = _videos[index];
    final controller = _getOrCreateController(index);

    Widget playerWidget = YoutubePlayer(
      controller: controller,
      showVideoProgressIndicator: true,
      aspectRatio: 16 / 9,
      width: MediaQuery.of(context).size.width,
      progressColors: const ProgressBarColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
        bufferedColor: Colors.white24,
        backgroundColor: Colors.white12,
      ),
    );

    // Apply calm mode filter if active
    if (_calmModeFilter != null) {
      playerWidget = ColorFiltered(
        colorFilter: _calmModeFilter!,
        child: playerWidget,
      );
    }

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player - centered vertically, fills width
          Center(child: playerWidget),

          // Bottom info overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 60, // Leave space for page indicator dots
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Channel name with Short badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow, color: Colors.white, size: 14),
                            SizedBox(width: 2),
                            Text(
                              'Short',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          video.channelTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Video title
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

