import 'dart:async';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import '../services/parental_control_service.dart';
import 'break_reminder_screen.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  final List<VideoModel>? playlist;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    this.playlist,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  final StorageService _storageService = StorageService();
  final ParentalControlService _parentalService = ParentalControlService();
  DateTime? _startTime;
  bool _isInitialized = false;
  Timer? _breakCheckTimer;
  int _totalMinutesWatched = 0;
  bool _isOnBreak = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _startTime = DateTime.now();
    _startBreakCheckTimer();
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
            _controller.pause();
            
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BreakReminderScreen(
                  onBreakComplete: () {
                    _isOnBreak = false;
                    _controller.play();
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          }
        }
      }
    });
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(() {
      if (_controller.value.isReady && !_isInitialized) {
        _isInitialized = true;
      }
    });
  }


  @override
  void dispose() async {
    _breakCheckTimer?.cancel();
    
    // Record watch time before disposing
    if (_startTime != null && !_isOnBreak) {
      final watchDuration = DateTime.now().difference(_startTime!);
      final minutesWatched = watchDuration.inMinutes;
      if (minutesWatched > 0) {
        await _parentalService.recordVideoWatch(minutesWatched);
      }
    }

    // Add to watch history
    await _storageService.addToWatchHistory(widget.video);

    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App bar with video info
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primary,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          widget.video.channelTitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Video player
            Expanded(
              child: Center(
                child: YoutubePlayerBuilder(
                  onExitFullScreen: () {
                    // Handle exit fullscreen
                  },
                  player: YoutubePlayer(
                    controller: _controller,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Theme.of(context).colorScheme.primary,
                    progressColors: ProgressBarColors(
                      playedColor: Theme.of(context).colorScheme.primary,
                      handleColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  builder: (context, player) {
                    return player;
                  },
                ),
              ),
            ),

            // Video description
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description.isNotEmpty
                        ? widget.video.description
                        : 'No description available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

