import 'package:flutter/material.dart';
import '../services/youtube_service.dart';
import '../services/parental_control_service.dart';
import '../utils/constants.dart';
import '../widgets/category_card.dart';
import '../widgets/video_card.dart';
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
  
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  List<VideoModel> _categoryVideos = [];
  bool _isLoadingCategories = true;
  bool _isLoadingVideos = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _errorMessage = null;
    });

    try {
      final categories = await _youtubeService.getCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories. Please check your API key.';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadCategoryVideos(String categoryId, String categoryName) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategoryName = categoryName;
      _isLoadingVideos = true;
      _errorMessage = null;
    });

    try {
      final videos = await _youtubeService.getVideosByCategory(categoryId);
      
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
        _errorMessage = 'Failed to load videos. Please check your API key.';
        _isLoadingVideos = false;
      });
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
          builder: (context) => VideoPlayerScreen(
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
      _categoryVideos = [];
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
            : null,
      ),
      body: _selectedCategoryId == null ? _buildCategoriesView() : _buildVideosView(),
    );
  }

  Widget _buildCategoriesView() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
                onPressed: _loadCategories,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text('No categories available'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return CategoryCard(
          categoryId: category['id']!,
          categoryName: category['title']!,
          icon: Icons.category,
          onTap: () => _loadCategoryVideos(
            category['id']!,
            category['title']!,
          ),
        );
      },
    );
  }

  Widget _buildVideosView() {
    if (_isLoadingVideos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
                onPressed: () => _loadCategoryVideos(
                  _selectedCategoryId!,
                  _selectedCategoryName!,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_categoryVideos.isEmpty) {
      return const Center(
        child: Text('No videos found in this category'),
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

