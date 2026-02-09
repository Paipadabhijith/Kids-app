import 'package:flutter/material.dart';

/// Enhanced empty state widget with kid-friendly design
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customIllustration;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.actionLabel,
    this.onAction,
    this.customIllustration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultIconColor = iconColor ?? theme.primaryColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom illustration or default icon
            if (customIllustration != null)
              customIllustration!
            else
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: defaultIconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: defaultIconColor,
                ),
              ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            // Message
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            // Action button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specific empty states for common scenarios
class EmptyStateVideos extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const EmptyStateVideos({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Videos Found',
      message: customMessage ?? 'Try searching for something else or explore categories!',
      icon: Icons.video_library_outlined,
      iconColor: Colors.orange,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      customIllustration: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class EmptyStateSearch extends StatelessWidget {
  final VoidCallback? onExplore;

  const EmptyStateSearch({
    super.key,
    this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Start Searching!',
      message: 'Search for your favorite videos, songs, or shows!',
      icon: Icons.search,
      iconColor: Colors.blue,
      customIllustration: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.search,
            size: 64,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}

class EmptyStateCategories extends StatelessWidget {
  final VoidCallback? onRetry;

  const EmptyStateCategories({
    super.key,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'No Categories Available',
      message: 'Categories will appear here once they\'re loaded.',
      icon: Icons.category_outlined,
      iconColor: Colors.purple,
      actionLabel: onRetry != null ? 'Retry' : null,
      onAction: onRetry,
    );
  }
}

class EmptyStateError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const EmptyStateError({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      title: 'Oops! Something went wrong',
      message: message,
      icon: Icons.error_outline,
      iconColor: Colors.red,
      actionLabel: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
      customIllustration: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

