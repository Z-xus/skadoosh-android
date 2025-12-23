import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:skadoosh_app/components/habit_heatmap.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/models/habit.dart';
import 'package:skadoosh_app/theme/theme_provider.dart';
import 'package:skadoosh_app/theme/design_tokens.dart';

class RitualsPage extends StatefulWidget {
  const RitualsPage({super.key});

  @override
  State<RitualsPage> createState() => _RitualsPageState();
}

class _RitualsPageState extends State<RitualsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Listen to tab changes to update FAB icon/action if needed
    _tabController.addListener(() {
      setState(() {});
    });

    // Fetch everything on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NoteDatabase>(context, listen: false).fetchHabits();
      Provider.of<NoteDatabase>(context, listen: false).fetchTodos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // === DIALOGS ===

  void _showAddDialog() {
    final themeProvider = context.read<ThemeProvider>();
    final tokens = themeProvider.currentTokens;

    bool isRitualTab = _tabController.index == 0;
    String hint = isRitualTab
        ? "New Ritual (e.g. Read 10 pages)"
        : "New Task (e.g. Buy Milk)";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        content: TextField(
          controller: _textController,
          style: TextStyle(color: tokens.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: tokens.textTertiary),
            filled: true,
            fillColor: tokens.surfaceInput,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: tokens.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              borderSide: BorderSide(color: tokens.accentPrimary, width: 2),
            ),
          ),
          autofocus: true,
          onSubmitted: (_) => _submitAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _textController.clear();
            },
            style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: _submitAdd,
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accentPrimary,
              foregroundColor: tokens.textInverse,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
            ),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _submitAdd() {
    if (_textController.text.isNotEmpty) {
      final db = context.read<NoteDatabase>();
      if (_tabController.index == 0) {
        db.addHabit(_textController.text, initialGoal: 7);
      } else {
        db.addTodo(_textController.text);
      }

      // Haptic feedback for successful creation
      HapticFeedback.mediumImpact();
    }
    Navigator.pop(context);
    _textController.clear();
  }

  // === LEVEL UP LOGIC ===
  void _showLevelUpDialog(Habit habit) {
    final themeProvider = context.read<ThemeProvider>();
    final tokens = themeProvider.currentTokens;

    _confettiController.play();
    int nextGoal = (habit.goalDays < 21)
        ? habit.goalDays + 7
        : habit.goalDays + 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: tokens.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Text(
          "Cycle Complete!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: tokens.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: tokens.stateSuccess, size: 60),
            const SizedBox(height: DesignTokens.radiusM),
            Text(
              "You crushed the ${habit.goalDays}-day cycle.",
              style: TextStyle(color: tokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.radiusM),
            Text(
              "Commit to $nextGoal days next?",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
            child: const Text("Not yet"),
          ),
          FilledButton(
            onPressed: () {
              context.read<NoteDatabase>().evolveHabit(habit.id);
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accentPrimary,
              foregroundColor: tokens.textInverse,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusM),
              ),
            ),
            child: const Text("Let's do it"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final tokens = themeProvider.currentTokens;

    return Scaffold(
      backgroundColor: tokens.bgBase,

      // APP BAR WITH TABS
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.center_focus_strong_rounded,
              size: 28,
              color: tokens.accentPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              "Focus",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: tokens.bgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: tokens.accentPrimary,
          unselectedLabelColor: tokens.textSecondary,
          indicatorColor: tokens.accentPrimary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: "Rituals"),
            Tab(text: "Tasks"),
          ],
        ),
      ),

      // DYNAMIC FAB
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: tokens.accentPrimary,
        foregroundColor: tokens.textInverse,
        elevation: DesignTokens.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        child: AnimatedSwitcher(
          duration: DesignTokens.animationFast,
          child: Icon(
            _tabController.index == 0 ? Icons.loop : Icons.add_task,
            key: ValueKey(_tabController.index),
          ),
        ),
      ),

      // BODY
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [_buildRitualsTab(), _buildTodosTab()],
          ),

          // Confetti matches Stack alignment
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 30,
              colors: [
                tokens.accentPrimary,
                tokens.accentSecondary,
                tokens.stateSuccess,
                tokens.stateWarning,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: RITUALS (Cyclic Habits)
  // ===========================================================================
  Widget _buildRitualsTab() {
    final tokens = context.read<ThemeProvider>().currentTokens;

    return Consumer<NoteDatabase>(
      builder: (context, db, child) {
        if (db.currentHabits.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.self_improvement,
                  size: 64,
                  color: tokens.textTertiary,
                ),
                const SizedBox(height: DesignTokens.radiusM),
                Text(
                  "No rituals yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start small, build momentum",
                  style: TextStyle(fontSize: 14, color: tokens.textTertiary),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: DesignTokens.pageMargin,
          children: [
            // Heatmap with modern styling
            Container(
              padding: DesignTokens.cardPadding,
              decoration: BoxDecoration(
                color: tokens.bgSecondary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: tokens.textPrimary.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: MinimalHeatMap(
                habits: db.currentHabits,
                startDate: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  1,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Habits list with enhanced styling
            ...db.currentHabits.map(
              (habit) => _buildModernHabitTile(habit, context),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildModernHabitTile(Habit habit, BuildContext context) {
    final tokens = context.read<ThemeProvider>().currentTokens;
    final isCompleted = habit.isCompletedToday;
    final safeProgress = habit.currentProgress < 0 ? 0 : habit.currentProgress;
    final safeGoal = habit.goalDays < 1 ? 7 : habit.goalDays;

    return TweenAnimationBuilder<double>(
      duration: DesignTokens.animationMedium,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * animation),
          child: AnimatedContainer(
            duration: DesignTokens.animationMedium,
            curve: DesignTokens.animationCurveStandard,
            margin: const EdgeInsets.only(bottom: DesignTokens.radiusM),
            decoration: BoxDecoration(
              color: tokens.bgSecondary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusL),
              border: Border.all(
                color: isCompleted
                    ? tokens.stateSuccess.withValues(alpha: 0.3)
                    : tokens.borderSecondary,
                width: isCompleted ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCompleted
                      ? tokens.stateSuccess.withValues(alpha: 0.1)
                      : tokens.textPrimary.withValues(alpha: 0.05),
                  blurRadius: isCompleted ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                onLongPress: () => _showDeleteDialog(habit),
                child: Padding(
                  padding: DesignTokens.cardPadding,
                  child: Row(
                    children: [
                      // Animated completion button
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final db = context.read<NoteDatabase>();
                          await db.checkHabitCompletion(habit.id, !isCompleted);
                          if (mounted) {
                            final h = await db.getHabitById(habit.id);
                            if (h != null && h.isCycleFinished) {
                              _showLevelUpDialog(h);
                            }
                          }
                        },
                        child: AnimatedContainer(
                          duration: DesignTokens.animationMedium,
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? tokens.stateSuccess
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusS,
                            ),
                            border: Border.all(
                              color: isCompleted
                                  ? tokens.stateSuccess
                                  : tokens.borderPrimary,
                              width: 2,
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: DesignTokens.animationFast,
                            child: isCompleted
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: tokens.textInverse,
                                    key: const ValueKey('check'),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.radiusM),

                      // Content section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: DesignTokens.animationMedium,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? tokens.textSecondary
                                    : tokens.textPrimary,
                              ),
                              child: Text(
                                habit.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Progress section with enhanced styling
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: habit.isCycleFinished
                                        ? tokens.stateSuccess.withValues(
                                            alpha: 0.1,
                                          )
                                        : tokens.surfaceSelected,
                                    borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusXS,
                                    ),
                                  ),
                                  child: Text(
                                    habit.isCycleFinished
                                        ? "Cycle Complete!"
                                        : "$safeProgress/$safeGoal days",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: habit.isCycleFinished
                                          ? tokens.stateSuccess
                                          : tokens.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Enhanced progress bar
                                Expanded(
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: tokens.surfaceSelected,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: TweenAnimationBuilder<double>(
                                        duration: DesignTokens.animationMedium,
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: habit.progressPercentage,
                                        ),
                                        builder: (context, progress, child) {
                                          return LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: Colors.transparent,
                                            valueColor: AlwaysStoppedAnimation(
                                              habit.isCycleFinished
                                                  ? tokens.stateSuccess
                                                  : tokens.accentPrimary,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(Habit habit) {
    final tokens = context.read<ThemeProvider>().currentTokens;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: tokens.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusL),
        ),
        title: Text(
          "Delete Ritual?",
          style: TextStyle(color: tokens.textPrimary),
        ),
        content: Text(
          "This action cannot be undone.",
          style: TextStyle(color: tokens.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: tokens.textSecondary),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              context.read<NoteDatabase>().deleteHabit(habit.id);
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            style: TextButton.styleFrom(foregroundColor: tokens.stateError),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: TODOS (Tasks)
  // ===========================================================================
  Widget _buildTodosTab() {
    final tokens = context.read<ThemeProvider>().currentTokens;

    return Consumer<NoteDatabase>(
      builder: (context, db, child) {
        if (db.currentTodos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 64, color: tokens.textTertiary),
                const SizedBox(height: DesignTokens.radiusM),
                Text(
                  "All caught up!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You're on top of things",
                  style: TextStyle(fontSize: 14, color: tokens.textTertiary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: DesignTokens.pageMargin,
          itemCount: db.currentTodos.length + 1, // +1 for spacing
          itemBuilder: (context, index) {
            if (index == db.currentTodos.length) {
              return const SizedBox(height: 80);
            }
            final todo = db.currentTodos[index];
            return _buildModernTodoTile(todo, context, index);
          },
        );
      },
    );
  }

  Widget _buildModernTodoTile(Todo todo, BuildContext context, int index) {
    final tokens = context.read<ThemeProvider>().currentTokens;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 150 + (index * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation)),
          child: Opacity(
            opacity: animation,
            child: Dismissible(
              key: Key(todo.id.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: tokens.stateError,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: tokens.textInverse,
                  size: 24,
                ),
              ),
              onDismissed: (direction) {
                context.read<NoteDatabase>().deleteTodo(todo.id);
                HapticFeedback.mediumImpact();
              },
              child: AnimatedContainer(
                duration: DesignTokens.animationMedium,
                margin: const EdgeInsets.only(bottom: DesignTokens.radiusM),
                decoration: BoxDecoration(
                  color: tokens.bgSecondary,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                  border: Border.all(
                    color: todo.isCompleted
                        ? tokens.stateSuccess.withValues(alpha: 0.3)
                        : tokens.borderSecondary,
                    width: todo.isCompleted ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: todo.isCompleted
                          ? tokens.stateSuccess.withValues(alpha: 0.1)
                          : tokens.textPrimary.withValues(alpha: 0.05),
                      blurRadius: todo.isCompleted ? 12 : 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    onTap: () {
                      context.read<NoteDatabase>().toggleTodo(todo.id);
                      HapticFeedback.lightImpact();
                    },
                    contentPadding: DesignTokens.cardPadding,
                    leading: AnimatedContainer(
                      duration: DesignTokens.animationMedium,
                      child: Icon(
                        todo.isCompleted
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: todo.isCompleted
                            ? tokens.stateSuccess
                            : tokens.textSecondary,
                        size: 28,
                      ),
                    ),
                    title: AnimatedDefaultTextStyle(
                      duration: DesignTokens.animationMedium,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted
                            ? tokens.textSecondary
                            : tokens.textPrimary,
                      ),
                      child: Text(todo.title),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusL),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
