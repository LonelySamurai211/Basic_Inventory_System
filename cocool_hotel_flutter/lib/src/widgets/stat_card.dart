import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.trendLabel,
    this.trendPositive = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? caption;
  final String? trendLabel;
  final bool trendPositive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.forest, size: 28),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(
                caption!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (trendLabel != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (trendPositive ? AppColors.mint : AppColors.warning)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendPositive
                          ? Icons.arrow_outward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: trendPositive ? AppColors.forest : AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        trendLabel!,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: trendPositive
                              ? AppColors.forest
                              : AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
