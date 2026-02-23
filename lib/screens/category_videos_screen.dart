import 'package:flutter/material.dart';
import '../services/youtube_service.dart';
import '../services/parental_control_service.dart';
import '../utils/constants.dart';
import '../models/video_model.dart';
import '../utils/page_transitions.dart';
import '../widgets/video_card.dart';
import 'video_player_screen.dart';

class CategoryVideosScreen extends StatefulWidget {
  final String categoryName;
  final String searchQuery;

  const CategoryVideosScreen({
    super.key,
    required this.categoryName,
    required this.searchQuery,
  });

  @override
  State<CategoryVideosScreen> createState() => _CategoryVideosScreenState();
}

class _CategoryVideosScreenState extends State<CategoryVideosScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  final ParentalControlService _parentalService = ParentalControlService();
  
  List<VideoModel> _videos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!Constants.hasValidApiKey) {
      setState(() {
        _errorMessage = 'YouTube API key is not configured. Please add your API key to the .env file.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Search for videos using the category-specific query
      final videos = await _youtubeService.searchVideos(
        widget.searchQuery,
        maxResults: 50,
      );
      
      // Filter videos based on parental controls
      final filteredVideos = <VideoModel>[];
      for (final video in videos) {
        final isAllowed = await _parentalService.isVideoAllowed(video);
        if (isAllowed) {
          filteredVideos.add(video);
        }
      }

      setState(() {
        _videos = filteredVideos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load videos. Please check your API key and internet connection.';
        _isLoading = false;
      });
      debugPrint('Error loading category videos: $e');
    }
  }

  Future<void> _playVideo(VideoModel video) async {
    // Check time limit
    final isLimitExceeded = await _parentalService.isTimeLimitExceeded();
    if (isLimitExceeded) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Daily time limit reached. Please ask a parent to adjust settings.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        SmoothPageRoute(
          page: VideoPlayerScreen(
            video: video,
            playlist: _videos,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadVideos,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _videos.isEmpty
                  ? const Center(
                      child: Text('No videos found for this category'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _videos.length,
                      itemBuilder: (context, index) {
                        final video = _videos[index];
                        return VideoCard(
                          video: video,
                          onTap: () => _playVideo(video),
                        );
                      },
                    ),
    );
  }
}

