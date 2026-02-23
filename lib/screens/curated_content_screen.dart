import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../services/youtube_service.dart';
import '../services/parental_control_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/video_card.dart';
import 'video_player_screen.dart';

class CuratedContentScreen extends StatefulWidget {
  const CuratedContentScreen({super.key});

  @override
  State<CuratedContentScreen> createState() => _CuratedContentScreenState();
}

class _CuratedContentScreenState extends State<CuratedContentScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  final ParentalControlService _parentalService = ParentalControlService();
  final StorageService _storageService = StorageService();
  
  List<VideoModel> _curatedVideos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCuratedVideos();
  }

  Future<void> _loadCuratedVideos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load saved curated videos
      final saved = await _storageService.getCuratedVideos();
      
      // If no curated videos, load educational content
      if (saved.isEmpty) {
        if (!Constants.hasValidApiKey) {
          setState(() {
            _errorMessage = 'YouTube API key is not configured. Please add your API key to the .env file to load curated content.';
            _curatedVideos = [];
            _isLoading = false;
          });
          return;
        }
        
        final educationalVideos = await _youtubeService.searchVideos(
          'educational kids content',
          maxResults: 20,
        );
        
        // Filter and save
        final filtered = <VideoModel>[];
        for (final video in educationalVideos) {
          final isAllowed = await _parentalService.isVideoAllowed(video);
          if (isAllowed) {
            filtered.add(video);
            await _storageService.addCuratedVideo(video);
          }
        }
        
        setState(() {
          _curatedVideos = filtered;
          _isLoading = false;
        });
      } else {
        // Filter saved videos
        final filtered = <VideoModel>[];
        for (final video in saved) {
          final isAllowed = await _parentalService.isVideoAllowed(video);
          if (isAllowed) {
            filtered.add(video);
          }
        }
        
        setState(() {
          _curatedVideos = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load curated content. Please check your API key.';
        _isLoading = false;
      });
    }
  }

  Future<void> _playVideo(VideoModel video) async {
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
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            video: video,
            playlist: _curatedVideos,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kid-Safe Content'),
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
                          onPressed: _loadCuratedVideos,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _curatedVideos.isEmpty
                  ? const Center(
                      child: Text('No curated content available'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _curatedVideos.length,
                      itemBuilder: (context, index) {
                        final video = _curatedVideos[index];
                        return VideoCard(
                          video: video,
                          onTap: () => _playVideo(video),
                        );
                      },
                    ),
    );
  }
}

