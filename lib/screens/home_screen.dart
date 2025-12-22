import 'package:flutter/material.dart';
import '../services/parental_control_service.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkTimeLimit();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Widget _buildHeader() {
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
          const SizedBox(height: 8),
          const Text(
            'Fun & Educational Videos for Kids',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
                    // Time limit widget
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

                    // Popular Shows Section
                    _buildSection(
                      title: 'Popular Kids Shows',
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
                      child: SizedBox(
                        height: 140,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildCategoryCard(
                              title: 'Bob the Train',
                              icon: Icons.train_rounded,
                              color: Colors.red.shade400,
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
                            _buildCategoryCard(
                              title: 'Junior Squad',
                              icon: Icons.group_rounded,
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
                            _buildCategoryCard(
                              title: 'Little Eddie',
                              icon: Icons.child_care_rounded,
                              color: Colors.green.shade400,
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
                            _buildCategoryCard(
                              title: 'Baby Bao Panda',
                              icon: Icons.pets_rounded,
                              color: Colors.pink.shade400,
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Statistics Section
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.teal.shade300,
                            Colors.cyan.shade300,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UsageStatisticsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.bar_chart_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Usage Statistics',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'View your watching history',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
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
  }
}

