import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:skadoosh_app/models/habit.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class HabitDetailDialog extends StatelessWidget {
  final Habit habit;

  const HabitDetailDialog({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: DesignTokens.pageMargin,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Category icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: habit.category.color.withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    habit.category.icon,
                    color: habit.category.color,
                    size: 20,
                  ),
                ),
                SizedBox(width: DesignTokens.spaceM.left),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${habit.category.displayName} • ${habit.statusDescription}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close),
                ),
              ],
            ),

            SizedBox(height: DesignTokens.spaceL.top),

            // Current Cycle Stats
            _buildCurrentCycleCard(theme, colorScheme),

            SizedBox(height: DesignTokens.spaceL.top),

            // Cycle History
            if (habit.cycleHistory.isNotEmpty) ...[
              Text(
                'Cycle History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: DesignTokens.spaceM.top),
              Expanded(
                child: ListView.builder(
                  itemCount: habit.cycleHistory.length,
                  itemBuilder: (context, index) {
                    final cycle = habit.cycleHistory[index];
                    return _buildCycleHistoryCard(cycle, theme, colorScheme);
                  },
                ),
              ),
            ] else ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        FluentIcons.history_24_regular,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: DesignTokens.spaceM.top),
                      Text(
                        'No History Yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: DesignTokens.spaceS.top),
                      Text(
                        'Complete your first cycle to see progress history here.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCycleCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: DesignTokens.cardPadding,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusM),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.target_24_regular,
                color: colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: DesignTokens.spaceS.left),
              Text(
                'Current Cycle ${habit.currentCycle}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceM.top),

          // Progress bar
          LinearProgressIndicator(
            value: habit.cycleProgress,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          SizedBox(height: DesignTokens.spaceS.top),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${habit.currentCycleCompletions.length} of ${habit.currentDuration.days} days',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${(habit.cycleProgress * 100).round()}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.spaceS.top),

          // Additional stats
          Row(
            children: [
              _buildStatChip(
                'Current streak: ${habit.currentCycleStreak}',
                FluentIcons.fire_24_regular,
                theme,
                colorScheme,
              ),
              SizedBox(width: DesignTokens.spaceS.left),
              _buildStatChip(
                'Total: ${habit.totalStreak}',
                FluentIcons.trophy_24_regular,
                theme,
                colorScheme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String text,
    IconData icon,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleHistoryCard(
    CycleHistory cycle,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final completionPercentage = (cycle.completionRate * 100).round();
    final isCompleted = cycle.isCompleted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Row(
          children: [
            // Cycle indicator
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        FluentIcons.checkmark_24_filled,
                        color: colorScheme.onPrimary,
                        size: 20,
                      )
                    : Text(
                        '${cycle.cycleNumber}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ),

            SizedBox(width: DesignTokens.spaceM.left),

            // Cycle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Cycle ${cycle.cycleNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: DesignTokens.spaceS.left),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusS,
                          ),
                        ),
                        child: Text(
                          cycle.duration.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    cycle.dateRangeString,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Completion stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$completionPercentage%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${cycle.completions}/${cycle.targetDays}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
