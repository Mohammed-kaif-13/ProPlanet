import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/activity_model.dart';

class ActivityCard extends StatelessWidget {
  final UserActivity userActivity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.userActivity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activity = userActivity.activity;
    final isCompleted = userActivity.isCompleted;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Activity Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isCompleted 
                      ? Colors.green.withOpacity(0.1)
                      : _getCategoryColor(activity.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    activity.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Activity Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ' points',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.amber[700],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'min',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? 'Done' : 'Active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Color _getCategoryColor(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.transport:
        return Colors.blue;
      case ActivityCategory.energy:
        return Colors.yellow;
      case ActivityCategory.waste:
        return Colors.green;
      case ActivityCategory.water:
        return Colors.cyan;
      case ActivityCategory.food:
        return Colors.orange;
      case ActivityCategory.shopping:
        return Colors.purple;
      case ActivityCategory.nature:
        return Colors.teal;
    }
  }
}
