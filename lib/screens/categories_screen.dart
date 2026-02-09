import 'package:flutter/material.dart';
import '../services/youtube_service.dart';
import '../services/parental_control_service.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../widgets/video_card.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/empty_state.dart';
import '../widgets/animated_button.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final YouTubeService _youtubeService = YouTubeService(
    apiKey: Constants.youtubeApiKey,
  );
  final ParentalControlService _parentalService = ParentalControlService();
  
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedCategoryQuery;
  List<VideoModel> _categoryVideos = [];
  bool _isLoadingVideos = false;
  String? _errorMessage;

  // Icon mapping for categories
  IconData _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'music_note': return Icons.music_note;
      case 'tv': return Icons.tv;
      case 'abc': return Icons.abc;
      case 'pets': return Icons.pets;
      case 'auto_stories': return Icons.auto_stories;
      case 'science': return Icons.science;
      case 'palette': return Icons.palette;
      case 'directions_run': return Icons.directions_run;
      case 'park': return Icons.park;
      case 'restaurant': return Icons.restaurant;
      case 'flash_on': return Icons.flash_on;
      case 'egg': return Icons.egg;
      case 'rocket_launch': return Icons.rocket_launch;
      case 'directions_car': return Icons.directions_car;
      case 'auto_awesome': return Icons.auto_awesome;
      case 'sentiment_very_satisfied': return Icons.sentiment_very_satisfied;
      default: return Icons.category;
    }
  }

  // Color palette for kids
  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF4CAF50), // Green
      const Color(0xFFE91E63), // Pink
      const Color(0xFF2196F3), // Blue
      const Color(0xFFFF9800), // Orange
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFFFEB3B), // Yellow
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF03A9F4), // Light Blue
      const Color(0xFFF44336), // Red
      const Color(0xFF009688), // Teal
      const Color(0xFFCDDC39), // Lime
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFFFF4081), // Pink Accent
    ];
    return colors[index % colors.length];
  }

  Future<void> _loadCategoryVideos(String categoryId, String categoryName, String searchQuery) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
      _selectedCategoryQuery = searchQuery;
      _isLoadingVideos = true;
      _errorMessage = null;
    });

    if (!Constants.hasValidApiKey) {
      setState(() {
        _errorMessage = 'YouTube API key is not configured. Please add your API key to the .env file.';
        _isLoadingVideos = false;
      });
      return;
    }

    try {
      final videos = await _youtubeService.searchVideos(searchQuery, maxResults: 30);
      
      // Filter videos based on parental controls
      final filteredVideos = <VideoModel>[];
      for (final video in videos) {
        final isAllowed = await _parentalService.isVideoAllowed(video);
        if (isAllowed) {
          filteredVideos.add(video);
        }
      }

      setState(() {
        _categoryVideos = filteredVideos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load videos. Please try again.';
        _isLoadingVideos = false;
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
            playlist: _categoryVideos,
          ),
        ),
      );
    }
  }

  void _goBackToCategories() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedCategoryQuery = null;
      _categoryVideos = [];
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategoryName ?? 'Categories'),
        leading: _selectedCategoryId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToCategories,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _selectedCategoryId == null ? _buildCategoriesGrid() : _buildVideosView(),
    );
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: Constants.kidCategories.length,
      itemBuilder: (context, index) {
        final category = Constants.kidCategories[index];
        final color = _getColorForIndex(index);
        final icon = _getIconForCategory(category['icon'] ?? 'category');
        
        return _buildCategoryTile(
          title: category['title']!,
          icon: icon,
          color: color,
          onTap: () => _loadCategoryVideos(
            category['id']!,
            category['title']!,
            category['query']!,
          ),
        );
      },
    );
  }

  Widget _buildCategoryTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedButton(
      onTap: onTap,
      child: Material(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Fun shapes behind icon
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background shapes
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  // Icon
                  Icon(
                    icon,
                    size: 36,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
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

  Widget _buildVideosView() {
    if (_isLoadingVideos) {
      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const VideoCardSkeleton(),
      );
    }

    if (_errorMessage != null) {
      return EmptyStateError(
        message: _errorMessage!,
        onRetry: () => _loadCategoryVideos(
          _selectedCategoryId!,
          _selectedCategoryName!,
          _selectedCategoryQuery!,
        ),
      );
    }

    if (_categoryVideos.isEmpty) {
      return EmptyStateVideos(
        customMessage: 'No videos found in $_selectedCategoryName. Try another category!',
        onRetry: _goBackToCategories,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _categoryVideos.length,
      itemBuilder: (context, index) {
        final video = _categoryVideos[index];
        return VideoCard(
          video: video,
          onTap: () => _playVideo(video),
        );
      },
    );
  }
}
