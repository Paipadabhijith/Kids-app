import 'package:flutter/material.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const VideoCard({
    super.key,
    required this.video,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumbnail with Hero animation
            // Always use 16:9 for card thumbnails (consistent grid layout)
            Hero(
              tag: 'video-${video.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        video.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: theme.colorScheme.primary.withOpacity(0.08),
                            child: const Icon(
                              Icons.video_library,
                              size: 48,
                              color: Color(0xFF8A90AB),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: theme.colorScheme.secondary.withOpacity(0.08),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                    // Show "Short" badge for YouTube Shorts
                    if (video.isShort)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D6D).withOpacity(0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Short',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.35),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Video info - flexible to prevent overflow
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      video.channelTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        color: const Color(0xFF6C7394),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

