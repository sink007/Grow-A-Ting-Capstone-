import 'package:flutter/material.dart';
import '../model/user_plant.dart';

// Task models
class TaskTemplate {
  final int id;
  final String title;
  final String description;
  final int dayOffset;
  final List<String> steps;

  TaskTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.dayOffset,
    required this.steps,
  });
}

class PlantTask {
  final int id;
  final int userPlantId;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final List<TaskStep> steps;
  final bool isOverdue;

  PlantTask({
    required this.id,
    required this.userPlantId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
    required this.steps,
    required this.isOverdue,
  });
}

class TaskStep {
  final int id;
  final String title;
  final bool isCompleted;

  TaskStep({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
}

// Task service with dummy data - no database needed
class TaskService {
  // Dummy method - not used anymore
  static Future<void> createInitialTasks(UserPlant userPlant) async {
    // Skip - using dummy data instead
  }
}

class PlantTasksWidget extends StatefulWidget {
  final UserPlant userPlant;

  const PlantTasksWidget({super.key, required this.userPlant});

  @override
  State<PlantTasksWidget> createState() => _PlantTasksWidgetState();
}

class _PlantTasksWidgetState extends State<PlantTasksWidget> {
  List<PlantTask> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    // Just use dummy data for Seed Propagation task
    await Future.delayed(const Duration(milliseconds: 500));

    final seedPropagationTask = PlantTask(
      id: 1,
      userPlantId: widget.userPlant.plant.plantId,
      title: "Seed Propagation",
      description: "Initial steps to germinate your seeds",
      dueDate: DateTime.now(),
      isCompleted: false,
      steps: [
        TaskStep(id: 1, title: "Prepare seed starting mix", isCompleted: false),
        TaskStep(
            id: 2, title: "Plant seeds at proper depth", isCompleted: false),
        TaskStep(
            id: 3, title: "Water gently and consistently", isCompleted: false),
        TaskStep(
            id: 4, title: "Place in warm, bright location", isCompleted: false),
        TaskStep(
            id: 5,
            title: "Monitor for germination (7-14 days)",
            isCompleted: false),
      ],
      isOverdue: false,
    );

    setState(() {
      tasks = [seedPropagationTask];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/sad-plant.png', height: 160),
            const SizedBox(height: 16),
            const Text(
              'No upcoming tasks',
              style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll remind you when it's time to care for your plant.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...tasks
            .map((task) => TaskSection(
                  task: task,
                  onStepToggle: _toggleStep,
                ))
            ,
      ],
    );
  }

  void _toggleStep(PlantTask task, TaskStep step) {
    setState(() {
      final taskIndex = tasks.indexWhere((t) => t.id == task.id);
      if (taskIndex != -1) {
        final stepIndex =
            tasks[taskIndex].steps.indexWhere((s) => s.id == step.id);
        if (stepIndex != -1) {
          final updatedStep = TaskStep(
            id: step.id,
            title: step.title,
            isCompleted: !step.isCompleted,
          );

          final updatedSteps = List<TaskStep>.from(tasks[taskIndex].steps);
          updatedSteps[stepIndex] = updatedStep;

          final updatedTask = PlantTask(
            id: task.id,
            userPlantId: task.userPlantId,
            title: task.title,
            description: task.description,
            dueDate: task.dueDate,
            isCompleted: task.isCompleted,
            steps: updatedSteps,
            isOverdue: task.isOverdue,
          );

          tasks[taskIndex] = updatedTask;
        }
      }
    });
  }
}

class TaskSection extends StatefulWidget {
  final PlantTask task;
  final Function(PlantTask, TaskStep) onStepToggle;

  const TaskSection({
    super.key,
    required this.task,
    required this.onStepToggle,
  });

  @override
  State<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends State<TaskSection> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => isExpanded = !isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Today • ${_formatTodaysDate()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
          ),
          // Steps with checkboxes
          if (isExpanded) ...[
            const Divider(height: 1, color: Colors.green),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: widget.task.steps
                    .map((step) => StepItem(
                          step: step,
                          onToggle: () =>
                              widget.onStepToggle(widget.task, step),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTodaysDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[now.month - 1]} ${now.day}';
  }
}

class StepItem extends StatelessWidget {
  final TaskStep step;
  final VoidCallback onToggle;

  const StepItem({
    super.key,
    required this.step,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: step.isCompleted
                      ? Colors.green.shade500
                      : Colors.green.shade400,
                  width: 2,
                ),
                color: step.isCompleted
                    ? Colors.green.shade500
                    : Colors.transparent,
              ),
              child: step.isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: step.isCompleted ? Colors.grey.shade600 : Colors.black87,
                decoration:
                    step.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
