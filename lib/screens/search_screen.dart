import 'package:flutter/material.dart';
import '../models/video_model.dart';
import '../services/youtube_service.dart';
import '../services/parental_control_service.dart';
import '../utils/constants.dart';
import '../widgets/video_card.dart';
import 'video_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _youtubeService = YouTubeService(
    apiKey: Constants.youtubeApiKey,
  );
  final ParentalControlService _parentalService = ParentalControlService();
  
  List<VideoModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasSearchText = false;

  Future<void> _searchVideos(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _youtubeService.searchVideos(query);
      
      if (results.isEmpty) {
        setState(() {
          _searchResults = [];
          _errorMessage = 'No videos found. Try a different search term.';
          _isLoading = false;
        });
        return;
      }
      
      // Filter videos based on parental controls
      final filteredResults = <VideoModel>[];
      for (final video in results) {
        final isAllowed = await _parentalService.isVideoAllowed(video);
        if (isAllowed) {
          filteredResults.add(video);
        }
      }

      setState(() {
        _searchResults = filteredResults;
        _errorMessage = filteredResults.isEmpty && results.isNotEmpty
            ? 'All results were filtered by parental controls.'
            : null;
        _isLoading = false;
      });
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = 'Failed to search videos: $errorMsg';
        _searchResults = [];
        _isLoading = false;
      });
      // Print error for debugging
      debugPrint('Search error: $e');
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
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(video: video),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _hasSearchText = _searchController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Videos'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for videos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _hasSearchText
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _searchVideos(_searchController.text),
                            tooltip: 'Search',
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _hasSearchText = false;
                                _errorMessage = null;
                              });
                            },
                            tooltip: 'Clear',
                          ),
                        ],
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onSubmitted: _searchVideos,
              textInputAction: TextInputAction.search,
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          // Search results
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final video = _searchResults[index];
                  return VideoCard(
                    video: video,
                    onTap: () => _playVideo(video),
                  );
                },
              ),
            )
          // Empty state
          else if (!_isLoading && _searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search for videos',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Center(
                child: Text(
                  'No results found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

