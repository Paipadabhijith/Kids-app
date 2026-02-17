import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;
  final String categoryId;
  final VoidCallback? onTap;
  final IconData? icon;

  const CategoryCard({
    super.key,
    required this.categoryName,
    required this.categoryId,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    final colorIndex = categoryId.hashCode % colors.length;
    final cardColor = colors[colorIndex.abs()];

    return Card(
      margin: const EdgeInsets.all(8),
      color: cardColor.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 48,
                  color: cardColor,
                ),
                const SizedBox(height: 12),
              ],
              Text(
                categoryName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

