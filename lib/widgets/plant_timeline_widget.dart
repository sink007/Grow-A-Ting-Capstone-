import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../model/user_plant.dart';
import '../model/plant_task.dart';

class PlantTimelineWidget extends StatefulWidget {
  final UserPlant userPlant;

  const PlantTimelineWidget({super.key, required this.userPlant});

  @override
  State<PlantTimelineWidget> createState() => _PlantTimelineWidgetState();
}

class _PlantTimelineWidgetState extends State<PlantTimelineWidget> {
  static const String baseUrl = 'https://grow-a-ting-capstone.onrender.com';
  List<PlantTask> completedTasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedTasks();
  }

  double _calculateLineHeight(int numTasks) {
    // Estimate line height based on number of task rows (each ~32–40 pixels tall with padding)
    return 32.0 * numTasks;
  }

  Future<void> _loadCompletedTasks() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ User not authenticated');
        throw Exception('User not authenticated');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/${user.id}/all-tasks'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> allTasks = json.decode(response.body);
        
        // Filter for completed tasks for this specific plant
        final completedTasksForPlant = allTasks
            .where((taskJson) => 
                taskJson['user_plant_id'] == widget.userPlant.userPlantId &&
                (taskJson['is_completed'] == true || taskJson['is_completed'] == 1) &&
                taskJson['date_completed'] != null)
            .map((taskJson) => PlantTask.fromJson(taskJson))
            .toList();

        // Sort by date_completed descending (most recent first)
        completedTasksForPlant.sort((a, b) => 
            (b.dateCompleted ?? DateTime.now()).compareTo(a.dateCompleted ?? DateTime.now()));

        setState(() {
          completedTasks = completedTasksForPlant;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading completed tasks: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Map<String, List<PlantTask>> _groupTasksByDate() {
    Map<String, List<PlantTask>> groupedTasks = {};
    
    for (var task in completedTasks) {
      if (task.dateCompleted != null) {
        String dateKey = _formatDate(task.dateCompleted!);
        if (groupedTasks.containsKey(dateKey)) {
          groupedTasks[dateKey]!.add(task);
        } else {
          groupedTasks[dateKey] = [task];
        }
      }
    }
    
    return groupedTasks;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);
    
    if (taskDate == today) {
      return 'Today';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _formatYear(DateTime date) {
    return date.year.toString();
  }

  IconData _getTaskIcon(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('water')) {
      return Icons.water_drop;
    } else if (desc.contains('inspect') || desc.contains('pest')) {
      return Icons.bug_report;
    } else if (desc.contains('prune') || desc.contains('trim')) {
      return Icons.content_cut;
    } else if (desc.contains('repot')) {
      return Icons.grass;
    } else {
      return Icons.eco;
    }
  }

  DateTime _parseDateForSorting(String dateKey) {
    if (dateKey == 'Today') {
      return DateTime.now();
    }
    
    try {
      final parts = dateKey.split(' ');
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final month = months.indexOf(parts[0]) + 1;
      final day = int.parse(parts[1]);
      return DateTime(DateTime.now().year, month, day);
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        ),
      );
    }

    if (completedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/sad-plant.png', height: 160),
            const SizedBox(height: 16),
            const Text(
              'No timeline events yet',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your plant\'s journey will show up here.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final groupedTasks = _groupTasksByDate();
    final sortedDates = groupedTasks.keys.toList()
      ..sort((a, b) {
        // Sort with "Today" first, then by date descending
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        
        final dateA = _parseDateForSorting(a);
        final dateB = _parseDateForSorting(b);
        
        return dateB.compareTo(dateA);
      });

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final dateKey = sortedDates[index];
          final tasksForDate = groupedTasks[dateKey]!;
          final firstTask = tasksForDate.first;
          final taskDate = firstTask.dateCompleted!;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and Timeline
                SizedBox(
                  width: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateKey,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatYear(taskDate),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: Column(
                          children: [
                            // Dot with stroke
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF82BE44), // Stroke
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            // Line (variable height)
                            if (index < sortedDates.length - 1)
                              Container(
                                width: 2,
                                height: _calculateLineHeight(tasksForDate.length),
                                color: Colors.grey.shade300,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tasks for this date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: tasksForDate.map((task) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    _getTaskIcon(task.description),
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task.description,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}