import 'package:flutter/material.dart';
import '../models/playlist_model.dart';

class PlaylistCard extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Playlist icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.playlist_play,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              // Playlist info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${playlist.videoIds.length} videos',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              if (onEdit != null || onDelete != null) ...[
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                    tooltip: 'Edit playlist',
                  ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                    tooltip: 'Delete playlist',
                    color: Colors.red,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

