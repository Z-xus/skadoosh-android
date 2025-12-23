import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:skadoosh_app/models/habit.dart';

class MinimalHabitTile extends StatelessWidget {
  final Habit habit;
  final Function(bool?)? onChanged;
  final Function(BuildContext)? onEdit;
  final Function(BuildContext)? onDelete;

  const MinimalHabitTile({
    super.key,
    required this.habit,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: onEdit,
              backgroundColor: Colors.grey.shade800,
              icon: Icons.settings,
              borderRadius: BorderRadius.circular(12),
            ),
            SlidableAction(
              onPressed: onDelete,
              backgroundColor: Colors.red.shade400,
              icon: Icons.delete,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            if (onChanged != null) {
              onChanged!(!isCompleted);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.shade100 // Minimal pastel green when done
                  : theme.colorScheme.surfaceContainer, // Grey/Surface when not
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Custom Checkbox
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted ? Colors.green : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                
                const SizedBox(width: 20),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCompleted 
                              ? Colors.grey.shade800 
                              : theme.colorScheme.onSurface,
                          decoration: isCompleted 
                              ? TextDecoration.lineThrough 
                              : TextDecoration.none,
                        ),
                      ),
                      Text(
                        "${habit.category.displayName} • Streak: ${habit.currentCycleStreak}",
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompleted 
                              ? Colors.grey.shade600 
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow or Icon
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: Colors.grey.shade400,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
