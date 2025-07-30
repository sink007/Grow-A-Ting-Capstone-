import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../model/user_plant.dart';
import '../model/plant_task.dart';

class TaskTemplate {
  final int templateId;
  final String title;
  final String description;
  final int stepCount;
  final List<String> steps;
  final String imageUrl;
  final String category;

  TaskTemplate({
    required this.templateId,
    required this.title,
    required this.description,
    required this.stepCount,
    required this.steps,
    required this.imageUrl,
    required this.category,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      templateId: json['template_id'],
      title: json['title'],
      description: json['description'],
      stepCount: json['step_count'],
      steps: List<String>.from(json['steps']),
      imageUrl: json['image_url'],
      category: json['category'],
    );
  }
}


// Updated Task service with 2-week filtering and recurring task management
class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000';
  static final _supabase = Supabase.instance.client;

  // Updated method to fetch tasks for next 2 weeks only
  static Future<List<PlantTask>> fetchUserTasks(UserPlant userPlant) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        throw Exception('User not authenticated');
      }

      print('🔍 Fetching tasks for user: ${user.id}');
      
      // Calculate date range (today + 2 weeks)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final twoWeeksFromNow = today.add(const Duration(days: 14));
      
      // Fetch tasks from Supabase directly with date filtering
      final response = await _supabase
          .from('task')
          .select('''
            task_id,
            user_plant_id,
            template_id,
            progress,
            is_completed,
            due_date,
            description,
            date_completed
          ''')
          .eq('user_plant_id', userPlant.userPlantId)
          .gte('due_date', today.toIso8601String().split('T')[0])
          .lte('due_date', twoWeeksFromNow.toIso8601String().split('T')[0])
          .order('due_date', ascending: true);

      print('📋 Received ${response.length} tasks for next 2 weeks');

      final tasks = response
          .map((taskJson) => PlantTask.fromJson(taskJson))
          .toList();

      // Sort tasks: overdue first, then by due date
      tasks.sort((a, b) {
        if (a.isOverdue && !b.isOverdue) return -1;
        if (!a.isOverdue && b.isOverdue) return 1;
        return a.dueDate.compareTo(b.dueDate);
      });

      // Check if we need to extend recurring tasks (do this in background)
      _checkAndExtendRecurringTasks(userPlant.userPlantId);

      return tasks;
    } catch (e) {
      print('❌ Error fetching tasks: $e');
      throw Exception('Error fetching tasks: $e');
    }
  }

  // Background method to check and extend recurring tasks
  static Future<void> _checkAndExtendRecurringTasks(int userPlantId) async {
    try {
      final url = '$baseUrl/api/extend-recurring-tasks';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_plant_id': userPlantId}),
      );
      
      if (response.statusCode == 200) {
        print('✅ Recurring tasks check completed');
      }
    } catch (e) {
      print('⚠️ Error checking recurring tasks: $e');
    }
  }

  // Fetch task template details
  static Future<TaskTemplate> fetchTaskTemplate(int templateId) async {
    try {
      final response = await _supabase
          .from('task_template')
          .select()
          .eq('template_id', templateId)
          .single();

      return TaskTemplate.fromJson(response);
    } catch (e) {
      print('❌ Error fetching task template: $e');
      throw Exception('Error fetching task template: $e');
    }
  }

  static Future<void> updateTaskCompletion(int taskId, bool isCompleted) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Updating task $taskId with completion: $isCompleted');

      final taskResponse = await _supabase
          .from('task')
          .select('''
            due_date, 
            is_completed, 
            user_plant_id,
            task_template!inner(category)
          ''')
          .eq('task_id', taskId)
          .single();

      final dueDate = DateTime.parse(taskResponse['due_date']);
      final userPlantId = taskResponse['user_plant_id'];
      final category = taskResponse['task_template']['category'];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

      String progress;
      bool finalIsCompleted;

      if (isCompleted) {
        progress = 'completed';
        finalIsCompleted = true;
      } else {
        if (taskDate.isBefore(today)) {
          progress = 'overdue';
          finalIsCompleted = false;
        } else {
          progress = 'started';
          finalIsCompleted = false;
        }
      }

      // Update the task in Supabase
      await _supabase.from('task').update({
        'progress': progress,
        'is_completed': finalIsCompleted,
        'date_completed': isCompleted ? 
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).toIso8601String() : null,
      }).eq('task_id', taskId);

      print('✅ Task $taskId updated successfully');

      // If this was a propagation task being completed, check if all propagation is done
      if (isCompleted && category == 'Propagation') {
        print('🌱 Propagation task completed, checking if recurring tasks should start...');
        await _triggerRecurringTaskCheck(userPlantId);
      }
    } catch (e) {
      print('❌ Error updating task: $e');
      throw Exception('Error updating task: $e');
    }
  }

  static Future<void> _triggerRecurringTaskCheck(int userPlantId) async {
    try {
      final url = '$baseUrl/api/check-and-schedule-tasks';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_plant_id': userPlantId}),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Recurring task check result: ${result['message']}');
      } else {
        print('⚠️ Failed to trigger recurring task check: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error triggering recurring task check: $e');
    }
  }

  static Future<void> refreshAndExtendTasks(int userPlantId) async {
    try {
      final url = '$baseUrl/api/extend-recurring-tasks';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'user_plant_id': userPlantId}),
      );
      
      if (response.statusCode == 200) {
        print('✅ Tasks refreshed and extended');
      } else {
        throw Exception('Failed to refresh tasks: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error refreshing tasks: $e');
      throw Exception('Error refreshing tasks: $e');
    }
  }
}

class PlantTasksWidget extends StatefulWidget {
  final UserPlant userPlant;

  const PlantTasksWidget({
    super.key,
    required this.userPlant,
  });

  @override
  State<PlantTasksWidget> createState() => _PlantTasksWidgetState();
}

class _PlantTasksWidgetState extends State<PlantTasksWidget> {
  List<PlantTask> tasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedTasks = await TaskService.fetchUserTasks(widget.userPlant);

      setState(() {
        tasks = fetchedTasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }
  Future<void> _refreshTasks() async {
    try {
      // First extend any recurring tasks if needed
      await TaskService.refreshAndExtendTasks(widget.userPlant.userPlantId);
      // Then reload the task list
      await loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tasks refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh tasks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleTaskCompletion(PlantTask task) async {
    try {
      final newIsCompleted = !task.isCompleted;
      String newProgress;

      if (newIsCompleted) {
        newProgress = 'completed';
      } else {
        // Check if task is overdue when unmarking completion
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final taskDate =
            DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);

        if (taskDate.isBefore(today)) {
          newProgress = 'overdue';
        } else {
          newProgress = 'started';
        }
      }

      setState(() {
        final taskIndex = tasks.indexWhere((t) => t.taskId == task.taskId);
        if (taskIndex != -1) {
          tasks[taskIndex] = task.copyWith(
            isCompleted: newIsCompleted,
            progress: newProgress,
            dateCompleted: newIsCompleted ? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) : null,
          );
        }
      });

      // Update in Supabase
      await TaskService.updateTaskCompletion(task.taskId, newIsCompleted);

      print('✅ Task ${task.taskId} toggled successfully');
    } catch (e) {
      // Revert UI changes on error
      setState(() {
        final taskIndex = tasks.indexWhere((t) => t.taskId == task.taskId);
        if (taskIndex != -1) {
          tasks[taskIndex] = task;
        }
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTaskInfo(PlantTask task) async {
    try {
      // Show loading dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final taskTemplate = await TaskService.fetchTaskTemplate(task.templateId);
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show task info dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => TaskInfoDialog(taskTemplate: taskTemplate),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load task info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              'Error loading tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: loadTasks,
                  child: const Text('Retry'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _refreshTasks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Refresh Tasks'),
                ),
              ],
            ),
          ],
        ),
      );
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
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll remind you when it's time to care for your plant.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshTasks,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check for New Tasks'),
            ),
          ],
        ),
      );
    }

    // Group tasks by date
    final Map<String, List<PlantTask>> tasksByDate = {};
    for (final task in tasks) {
      final dateKey = _formatDate(task.dueDate);
      if (!tasksByDate.containsKey(dateKey)) {
        tasksByDate[dateKey] = [];
      }
      tasksByDate[dateKey]!.add(task);
    }

    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...tasksByDate.entries.map((entry) => TaskSection(
                dateLabel: entry.key,
                tasks: entry.value,
                onTaskToggle: _toggleTaskCompletion,
                onTaskInfo: _showTaskInfo,
              )),
          // Add spacing at bottom
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (taskDate.isBefore(today)) {
      return 'Overdue';
    } else {
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
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

class TaskSection extends StatefulWidget {
  final String dateLabel;
  final List<PlantTask> tasks;
  final Function(PlantTask) onTaskToggle;
  final Function(PlantTask) onTaskInfo;

  const TaskSection({
    super.key,
    required this.dateLabel,
    required this.tasks,
    required this.onTaskToggle,
    required this.onTaskInfo,
  });

  @override
  State<TaskSection> createState() => _TaskSectionState();
}

class _TaskSectionState extends State<TaskSection> {
  bool isExpanded = true;

  List<Widget> _buildTaskItems() {
    final List<Widget> items = [];
    final Set<int> seenTemplateIds = {};

    for (final task in widget.tasks) {
      final showInfoIcon = !seenTemplateIds.contains(task.templateId);
      if (showInfoIcon) {
        seenTemplateIds.add(task.templateId);
      }

      items.add(TaskItem(
        task: task,
        onToggle: () => widget.onTaskToggle(task),
        onInfo: showInfoIcon ? () => widget.onTaskInfo(task) : null,
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.dateLabel == 'Overdue';
    final cardColor = isOverdue ? Colors.red.shade50 : Colors.green.shade50;
    final borderColor = isOverdue ? Colors.red.shade200 : Colors.green.shade200;
    final textColor = isOverdue ? Colors.red.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
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
                      widget.dateLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (widget.tasks.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.tasks.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _buildTaskItems(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final PlantTask task;
  final VoidCallback onToggle;
  final VoidCallback? onInfo;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    this.onInfo,
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
                  color: task.isCompleted
                      ? Colors.green.shade500
                      : (task.isOverdue
                          ? Colors.red.shade400
                          : Colors.green.shade400),
                  width: 2,
                ),
                color: task.isCompleted
                    ? Colors.green.shade500
                    : Colors.transparent,
              ),
              child: task.isCompleted
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
              task.description,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: task.isCompleted ? Colors.grey.shade600 : Colors.black87,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (onInfo != null)
            GestureDetector(
              onTap: onInfo,
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
}

class TaskInfoDialog extends StatelessWidget {
  final TaskTemplate taskTemplate;

  const TaskInfoDialog({
    super.key,
    required this.taskTemplate,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with image and close button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    taskTemplate.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      taskTemplate.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF399942),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Flexible(
                      child: SingleChildScrollView(
                        child: Text(
                          taskTemplate.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Steps count and category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF399942).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${taskTemplate.stepCount} steps',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF399942),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            taskTemplate.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}