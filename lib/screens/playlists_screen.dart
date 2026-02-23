import 'package:flutter/material.dart';
import '../models/playlist_model.dart';
import '../models/video_model.dart';
import '../services/storage_service.dart';
import '../services/youtube_service.dart';
import '../services/parental_control_service.dart';
import '../utils/constants.dart';
import '../widgets/playlist_card.dart';
import '../widgets/video_card.dart';
import 'video_player_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final StorageService _storageService = StorageService();
  final YouTubeService _youtubeService = YouTubeService();
  final ParentalControlService _parentalService = ParentalControlService();
  
  List<PlaylistModel> _playlists = [];
  PlaylistModel? _selectedPlaylist;
  List<VideoModel> _playlistVideos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    final playlists = await _storageService.getPlaylists();
    setState(() {
      _playlists = playlists;
      _isLoading = false;
    });
  }

  Future<void> _loadPlaylistVideos(PlaylistModel playlist) async {
    setState(() {
      _selectedPlaylist = playlist;
      _isLoading = true;
    });

    final videos = <VideoModel>[];
    for (final videoId in playlist.videoIds) {
      try {
        final video = await _youtubeService.getVideoDetails(videoId);
        if (video != null) {
          videos.add(video);
        }
      } catch (e) {
        // Skip videos that can't be loaded
      }
    }

    setState(() {
      _playlistVideos = videos;
      _isLoading = false;
    });
  }

  Future<void> _createPlaylist() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'Enter playlist name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter description',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final newPlaylist = PlaylistModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        videoIds: [],
        createdAt: DateTime.now(),
      );

      await _storageService.addPlaylist(newPlaylist);
      await _loadPlaylists();
    }
  }

  Future<void> _editPlaylist(PlaylistModel playlist) async {
    final nameController = TextEditingController(text: playlist.name);
    final descriptionController = TextEditingController(
      text: playlist.description ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Playlist Name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final updatedPlaylist = playlist.copyWith(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _storageService.updatePlaylist(updatedPlaylist);
      await _loadPlaylists();
      
      if (_selectedPlaylist?.id == playlist.id) {
        _loadPlaylistVideos(updatedPlaylist);
      }
    }
  }

  Future<void> _deletePlaylist(PlaylistModel playlist) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _storageService.deletePlaylist(playlist.id);
      await _loadPlaylists();
      
      if (_selectedPlaylist?.id == playlist.id) {
        setState(() {
          _selectedPlaylist = null;
          _playlistVideos = [];
        });
      }
    }
  }

  Future<void> _removeVideoFromPlaylist(VideoModel video) async {
    if (_selectedPlaylist == null) return;

    final updatedVideoIds = List<String>.from(_selectedPlaylist!.videoIds)
      ..remove(video.id);

    final updatedPlaylist = _selectedPlaylist!.copyWith(
      videoIds: updatedVideoIds,
      updatedAt: DateTime.now(),
    );

    await _storageService.updatePlaylist(updatedPlaylist);
    await _loadPlaylistVideos(updatedPlaylist);
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
            playlist: _playlistVideos,
          ),
        ),
      );
    }
  }

  void _goBackToPlaylists() {
    setState(() {
      _selectedPlaylist = null;
      _playlistVideos = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedPlaylist?.name ?? 'My Playlists'),
        leading: _selectedPlaylist != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToPlaylists,
              )
            : null,
        actions: _selectedPlaylist == null
            ? [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _createPlaylist,
                  tooltip: 'Create Playlist',
                ),
              ]
            : null,
      ),
      body: _selectedPlaylist == null ? _buildPlaylistsView() : _buildVideosView(),
    );
  }

  Widget _buildPlaylistsView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_play,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No playlists yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create one',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return PlaylistCard(
          playlist: playlist,
          onTap: () => _loadPlaylistVideos(playlist),
          onEdit: () => _editPlaylist(playlist),
          onDelete: () => _deletePlaylist(playlist),
        );
      },
    );
  }

  Widget _buildVideosView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_playlistVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No videos in this playlist',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
      itemCount: _playlistVideos.length,
      itemBuilder: (context, index) {
        final video = _playlistVideos[index];
        return VideoCard(
          video: video,
          onTap: () => _playVideo(video),
          onLongPress: () => _removeVideoFromPlaylist(video),
        );
      },
    );
  }
}

