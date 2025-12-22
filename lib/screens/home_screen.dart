import 'package:flutter/material.dart';
import '../services/parental_control_service.dart';
import '../widgets/kid_friendly_button.dart';
import '../widgets/time_limit_widget.dart';
import 'search_screen.dart';
import 'categories_screen.dart';
import 'playlists_screen.dart';
import 'parental_settings_screen.dart';
import 'curated_content_screen.dart';
import 'usage_statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ParentalControlService _parentalService = ParentalControlService();
  int _remainingMinutes = -1;
  bool _isLimitExceeded = false;

  @override
  void initState() {
    super.initState();
    _checkTimeLimit();
  }

  Future<void> _checkTimeLimit() async {
    final remaining = await _parentalService.getRemainingTimeMinutes();
    final exceeded = await _parentalService.isTimeLimitExceeded();
    
    if (mounted) {
      setState(() {
        _remainingMinutes = remaining;
        _isLimitExceeded = exceeded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kids TV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Time limit widget
              if (_remainingMinutes >= 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
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
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Daily time limit reached. Please ask a parent to adjust settings.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Main menu buttons
              KidFriendlyButton(
                text: 'Search Videos',
                icon: Icons.search,
                onPressed: _isLimitExceeded
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

              const SizedBox(height: 16),

              KidFriendlyButton(
                text: 'Categories',
                icon: Icons.category,
                backgroundColor: Colors.blue,
                onPressed: _isLimitExceeded
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

              const SizedBox(height: 16),

              KidFriendlyButton(
                text: 'My Playlists',
                icon: Icons.playlist_play,
                backgroundColor: Colors.purple,
                onPressed: _isLimitExceeded
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

              const SizedBox(height: 16),

              KidFriendlyButton(
                text: 'Kid-Safe Content',
                icon: Icons.favorite,
                backgroundColor: Colors.pink,
                onPressed: _isLimitExceeded
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

              const SizedBox(height: 16),

              KidFriendlyButton(
                text: 'Usage Statistics',
                icon: Icons.bar_chart,
                backgroundColor: Colors.teal,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsageStatisticsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // App info
              Text(
                'Choose an option above to start watching videos!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

