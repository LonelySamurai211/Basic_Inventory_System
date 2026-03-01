import 'package:flutter/material.dart';

class NotificationPopup extends StatefulWidget {
  const NotificationPopup({
    super.key,
    required this.notification,
    required this.onDismiss,
    required this.onTap,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  State<NotificationPopup> createState() => _NotificationPopupState();
}

class _NotificationPopupState extends State<NotificationPopup>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title = _buildTitle(widget.notification);
    final message = (widget.notification['message'] ??
            widget.notification['description'] ??
            '')
        .toString();
    final category = widget.notification['category'];

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _iconForCategory(category),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _fadeController.reverse().then((_) {
                            widget.onDismiss();
                          });
                        },
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  if (category != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.secondaryContainer.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        category.toString().replaceAll('_', ' ').toUpperCase(),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _fadeController.reverse().then((_) {
                          widget.onTap();
                        });
                      },
                      child: const Text('View'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildTitle(Map<String, dynamic> data) {
    final rawTitle = data['title']?.toString().trim();
    if (rawTitle != null && rawTitle.isNotEmpty) return rawTitle;

    final category = data['category']?.toString();
    switch (category) {
      case 'new_item':
        return 'New item added';
      case 'stock_in':
        return 'Stock In complete';
      case 'stock_out':
        return 'Stock Out complete';
      case 'low_stock':
        return 'Low stock alert';
      case 'no_stock':
        return 'Out of stock';
      case 'supplier_added':
        return 'Supplier added';
      case 'supplier_removed':
        return 'Supplier removed';
      default:
        return 'Notification';
    }
  }

  IconData _iconForCategory(dynamic category) {
    final cat = category?.toString().toLowerCase();
    switch (cat) {
      case 'new_item':
        return Icons.fiber_new;
      case 'stock_in':
        return Icons.arrow_downward;
      case 'stock_out':
        return Icons.arrow_upward;
      case 'low_stock':
        return Icons.warning_amber_outlined;
      case 'no_stock':
        return Icons.error_outline;
      case 'supplier_added':
      case 'supplier_removed':
        return Icons.store_outlined;
      default:
        return Icons.notifications_active;
    }
  }
}
