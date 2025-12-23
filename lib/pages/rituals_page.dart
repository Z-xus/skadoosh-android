import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:skadoosh_app/components/habit_heatmap.dart';
import 'package:skadoosh_app/models/note_database.dart';
import 'package:skadoosh_app/models/habit.dart';

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

  // --- DIALOGS ---

  void _showAddDialog() {
    bool isRitualTab = _tabController.index == 0;
    String hint = isRitualTab
        ? "New Ritual (e.g. Read 10 pages)"
        : "New Task (e.g. Buy Milk)";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: TextField(
          controller: _textController,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
          onSubmitted: (_) => _submitAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _textController.clear();
            },
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: _submitAdd,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
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
    }
    Navigator.pop(context);
    _textController.clear();
  }

  // --- LEVEL UP LOGIC ---
  void _showLevelUpDialog(Habit habit) {
    _confettiController.play();
    int nextGoal = (habit.goalDays < 21)
        ? habit.goalDays + 7
        : habit.goalDays + 10;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Cycle Complete!", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 60),
            const SizedBox(height: 16),
            Text("You crushed the ${habit.goalDays}-day cycle."),
            const SizedBox(height: 16),
            Text(
              "Commit to $nextGoal days next?",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Not yet"),
          ),
          FilledButton(
            onPressed: () {
              context.read<NoteDatabase>().evolveHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text("Let's do it"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      // APP BAR WITH TABS
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.center_focus_strong_rounded, size: 28),
            SizedBox(width: 8),
            Text("Focus", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: "Rituals"),
            Tab(text: "Tasks"),
          ],
        ),
      ),

      // DYNAMIC FAB
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.black,
        child: Icon(
          _tabController.index == 0 ? Icons.loop : Icons.check,
          color: Colors.white,
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
    return Consumer<NoteDatabase>(
      builder: (context, db, child) {
        if (db.currentHabits.isEmpty) {
          return const Center(child: Text("No rituals yet. Start small."));
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            MinimalHeatMap(
              habits: db.currentHabits,
              startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
            ),
            const SizedBox(height: 30),
            ...db.currentHabits.map(
              (habit) => _buildCyclicTile(habit, context),
            ),
            const SizedBox(height: 80),
          ],
        );
      },
    );
  }

  Widget _buildCyclicTile(Habit habit, BuildContext context) {
    final isCompleted = habit.isCompletedToday;
    final safeProgress = habit.currentProgress < 0 ? 0 : habit.currentProgress;
    final safeGoal = habit.goalDays < 1 ? 7 : habit.goalDays;

    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Delete Ritual?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  context.read<NoteDatabase>().deleteHabit(habit.id);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                await context.read<NoteDatabase>().checkHabitCompletion(
                  habit.id,
                  !isCompleted,
                );
                if (mounted) {
                  final h = await context.read<NoteDatabase>().getHabitById(
                    habit.id,
                  );
                  if (h != null && h.isCycleFinished) _showLevelUpDialog(h);
                }
              },
              child: Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: isCompleted
                          ? Colors.grey
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        habit.isCycleFinished
                            ? "Done!"
                            : "$safeProgress/$safeGoal",
                        style: TextStyle(
                          fontSize: 12,
                          color: habit.isCycleFinished
                              ? Colors.green
                              : Colors.grey[600],
                          fontWeight: habit.isCycleFinished
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: habit.progressPercentage,
                            minHeight: 4,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation(
                              isCompleted ? Colors.green : Colors.grey[500],
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
    );
  }

  // ===========================================================================
  // TAB 2: TODOS (Tasks)
  // ===========================================================================
  Widget _buildTodosTab() {
    return Consumer<NoteDatabase>(
      builder: (context, db, child) {
        if (db.currentTodos.isEmpty) {
          return const Center(
            child: Text("All caught up!", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: db.currentTodos.length + 1, // +1 for spacing
          itemBuilder: (context, index) {
            if (index == db.currentTodos.length)
              return const SizedBox(height: 80);
            final todo = db.currentTodos[index];
            return _buildTodoTile(todo, context);
          },
        );
      },
    );
  }

  Widget _buildTodoTile(Todo todo, BuildContext context) {
    return Dismissible(
      key: Key(todo.id.toString()),
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        context.read<NoteDatabase>().deleteTodo(todo.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          onTap: () => context.read<NoteDatabase>().toggleTodo(todo.id),
          leading: Icon(
            todo.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: todo.isCompleted ? Colors.grey : Colors.black,
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              fontSize: 16,
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted
                  ? Colors.grey
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
