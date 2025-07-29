// import 'package:flutter/material.dart';
// import 'package:grow_a_ting/ui/user_plant/user_plant.dart';
// import 'package:http/http.dart' as http;
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:convert';
// import '../../model/user_plant.dart';
// import '../../model/plant_task.dart';

// // Enhanced task with plant data
// class TaskWithPlant {
//   final PlantTask task;
//   final UserPlant? userPlant;

//   TaskWithPlant({required this.task, this.userPlant});
// }

// enum TaskFilter { all, overdue }

// class RemindersPage extends StatefulWidget {
//   final int? userId;

//   const RemindersPage({super.key, this.userId});

//   @override
//   _RemindersPageState createState() => _RemindersPageState();
// }

// class _RemindersPageState extends State<RemindersPage> {
//   List<TaskWithPlant> allTasksWithPlants = [];
//   List<TaskWithPlant> filteredTasksWithPlants = [];
//   TaskFilter currentFilter = TaskFilter.all;
//   bool isLoading = true;
//   String? error;

//   @override
//   void initState() {
//     super.initState();
//     fetchTasksWithPlantData();
//   }

//   static const String baseUrl = 'http://10.0.2.2:3000';

//   Future<void> fetchTasksWithPlantData() async {
//     try {
//       setState(() {
//         isLoading = true;
//         error = null;
//       });
      
//       final supabase = Supabase.instance.client;
//       final user = supabase.auth.currentUser;
      
//       if (user == null) {
//         setState(() {
//           error = 'User not authenticated';
//           isLoading = false;
//         });
//         return;
//       }

//       // Fetch tasks
//       final tasksResponse = await http.get(
//         Uri.parse('$baseUrl/user/${user.id}/tasks'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       if (tasksResponse.statusCode != 200) {
//         setState(() {
//           error = 'Failed to load tasks: ${tasksResponse.statusCode}';
//           isLoading = false;
//         });
//         return;
//       }

//       final List<dynamic> tasksJsonData = json.decode(tasksResponse.body);
//       final List<PlantTask> allTasks = tasksJsonData
//           .map((taskJson) => PlantTask.fromJson(taskJson))
//           .toList();

//       // Filter for incomplete tasks only (show all incomplete tasks)
//       final List<PlantTask> incompleteTasks = allTasks
//           .where((task) => !task.isCompleted)
//           .toList();

//       // Fetch user plants
//       final plantsResponse = await http.get(
//         Uri.parse('$baseUrl/user/${user.id}/plants'),
//         headers: {'Content-Type': 'application/json'},
//       );

//       Map<int, UserPlant> plantsMap = {};
//       if (plantsResponse.statusCode == 200) {
//         final List<dynamic> plantsJsonData = json.decode(plantsResponse.body);
//         for (var plantJson in plantsJsonData) {
//           final userPlant = UserPlant.fromJson(plantJson);
//           plantsMap[userPlant.userPlantId] = userPlant;
//         }
//       }

//       // Combine tasks with plant data
//       final List<TaskWithPlant> tasksWithPlants = incompleteTasks.map((task) {
//         final userPlant = plantsMap[task.userPlantId];
//         return TaskWithPlant(task: task, userPlant: userPlant);
//       }).toList();

//       // Sort by due date (overdue first, then by earliest due date)
//       tasksWithPlants.sort((a, b) {
//         if (a.task.isOverdue && !b.task.isOverdue) return -1;
//         if (!a.task.isOverdue && b.task.isOverdue) return 1;
//         return a.task.dueDate.compareTo(b.task.dueDate);
//       });

//       setState(() {
//         allTasksWithPlants = tasksWithPlants;
//         _applyFilter();
//         isLoading = false;
//       });

//     } catch (e) {
//       setState(() {
//         error = 'Error fetching data: $e';
//         isLoading = false;
//       });
//     }
//   }

//   void _applyFilter() {
//     switch (currentFilter) {
//       case TaskFilter.all:
//         filteredTasksWithPlants = allTasksWithPlants;
//         break;
//       case TaskFilter.overdue:
//         filteredTasksWithPlants = allTasksWithPlants
//             .where((taskWithPlant) => taskWithPlant.task.isOverdue)
//             .toList();
//         break;
//     }
//   }

//   void _setFilter(TaskFilter filter) {
//     setState(() {
//       currentFilter = filter;
//       _applyFilter();
//     });
//   }

//   String formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   String _getEmptyStateMessage() {
//     switch (currentFilter) {
//       case TaskFilter.all:
//         return 'No tasks yet!';
//       case TaskFilter.overdue:
//         return 'No overdue tasks!';
//     }
//   }

//   String _getEmptyStateSubMessage() {
//     switch (currentFilter) {
//       case TaskFilter.all:
//         return 'Your plant care tasks will appear here.';
//       case TaskFilter.overdue:
//         return 'You\'re all caught up with your plant care.';
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Reminders',
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: Colors.black
//           ),
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // Filter buttons
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   spreadRadius: 1,
//                   blurRadius: 3,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 // All Tasks filter
//                 GestureDetector(
//                   onTap: () => _setFilter(TaskFilter.all),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: currentFilter == TaskFilter.all 
//                           ? Color(0XFFDEF3E0) 
//                           : Colors.grey[100],
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: currentFilter == TaskFilter.all 
//                             ? Color(0XFF399942)! 
//                             : Colors.grey[300]!,
//                         width: 1,
//                       ),
//                     ),
//                     child: Text(
//                       'ALL TASKS',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: currentFilter == TaskFilter.all 
//                             ? Color(0XFF399942) 
//                             : Colors.grey[600],
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 // Overdue filter
//                 GestureDetector(
//                   onTap: () => _setFilter(TaskFilter.overdue),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: currentFilter == TaskFilter.overdue 
//                           ? Colors.red[50] 
//                           : Colors.grey[100],
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: currentFilter == TaskFilter.overdue 
//                             ? Colors.red[200]! 
//                             : Colors.grey[300]!,
//                         width: 1,
//                       ),
//                     ),
//                     child: Text(
//                       'OVERDUE',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: currentFilter == TaskFilter.overdue 
//                             ? Colors.red[700] 
//                             : Colors.grey[600],
//                         letterSpacing: 0.5,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Main content
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : error != null
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.error_outline,
//                               size: 64,
//                               color: Colors.red[400],
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               error!,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.red[600],
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                             const SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: fetchTasksWithPlantData,
//                               child: const Text('Retry'),
//                             ),
//                           ],
//                         ),
//                       )
//                     : filteredTasksWithPlants.isEmpty
//                         ? Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(
//                                   currentFilter == TaskFilter.overdue 
//                                       ? Icons.check_circle_outline
//                                       : Icons.task_alt,
//                                   size: 64,
//                                   color: currentFilter == TaskFilter.overdue 
//                                       ? Colors.green[400]
//                                       : Colors.blue[400],
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Text(
//                                   _getEmptyStateMessage(),
//                                   style: TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.w500,
//                                     color: currentFilter == TaskFilter.overdue 
//                                         ? Colors.green[600]
//                                         : Colors.blue[600],
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   _getEmptyStateSubMessage(),
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : RefreshIndicator(
//                             onRefresh: fetchTasksWithPlantData,
//                             child: ListView.separated(
//                               padding: const EdgeInsets.all(16.0),
//                               itemCount: filteredTasksWithPlants.length,
//                               separatorBuilder: (context, index) => const Divider(
//                                 color: Colors.grey,
//                                 thickness: 1,
//                                 height: 32,
//                               ),
//                               itemBuilder: (context, index) {
//                                 final taskWithPlant = filteredTasksWithPlants[index];
//                                 return TaskItem(
//                                   task: taskWithPlant.task,
//                                   userPlant: taskWithPlant.userPlant,
//                                 );
//                               },
//                             ),
//                           ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TaskItem extends StatelessWidget {
//   final PlantTask task;
//   final UserPlant? userPlant;

//   const TaskItem({
//     Key? key, 
//     required this.task, 
//     this.userPlant,
//   }) : super(key: key);

//   String formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: userPlant != null
//           ? () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => UserPlantPage(userPlant: userPlant!, plant: userPlant!.plant)),
//               );
//             }
//           : null,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Plant image or icon
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(8),
//                 color: Colors.green[100],
//               ),
//               child: userPlant?.plant.imageUrl != null
//                   ? ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: Image.network(
//                         userPlant!.plant.imageUrl!,
//                         fit: BoxFit.cover,
//                         errorBuilder: (context, error, stackTrace) {
//                           return Icon(
//                             Icons.local_florist,
//                             color: Colors.green[600],
//                             size: 24,
//                           );
//                         },
//                       ),
//                     )
//                   : Icon(
//                       Icons.local_florist,
//                       color: Colors.green[600],
//                       size: 24,
//                     ),
//             ),
//             const SizedBox(width: 12),
//             // Task details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Plant name
//                   Text(
//                     userPlant?.plant.commonName ?? 'Unknown Plant',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   // Task name
//                   Text(
//                     task.description,
//                     style: const TextStyle(
//                       fontSize: 16,
//                       color: Colors.black54,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   // Due date with status indicator
//                   Row(
//                     children: [
//                       Text(
//                         formatDate(task.dueDate),
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       // Status tag
//                       if (task.isOverdue)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.red[50],
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: Colors.red[200]!,
//                               width: 1,
//                             ),
//                           ),
//                           child: Text(
//                             'OVERDUE',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.red[700],
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                         ),
//                       if (!task.isOverdue)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 12,
//                             vertical: 4,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green[50],
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: Colors.green[200]!,
//                               width: 1,
//                             ),
//                           ),
//                           child: Text(
//                             'UPCOMING',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green[700],
//                               letterSpacing: 0.5,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:grow_a_ting/ui/user_plant/user_plant.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../model/user_plant.dart';
import '../../model/plant_task.dart';

// Enhanced task with plant data
class TaskWithPlant {
  final PlantTask task;
  final UserPlant? userPlant;

  TaskWithPlant({required this.task, this.userPlant});
}

enum TaskFilter { upcoming, overdue }

class RemindersPage extends StatefulWidget {
  final int? userId;

  const RemindersPage({super.key, this.userId});

  @override
  _RemindersPageState createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<TaskWithPlant> allTasksWithPlants = [];
  List<TaskWithPlant> filteredTasksWithPlants = [];
  TaskFilter currentFilter = TaskFilter.upcoming;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchTasksWithPlantData();
  }

  static const String baseUrl = 'http://10.0.2.2:3000';

  Future<void> fetchTasksWithPlantData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null) {
        setState(() {
          error = 'User not authenticated';
          isLoading = false;
        });
        return;
      }

      // Fetch tasks
      final tasksResponse = await http.get(
        Uri.parse('$baseUrl/user/${user.id}/tasks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (tasksResponse.statusCode != 200) {
        setState(() {
          error = 'Failed to load tasks: ${tasksResponse.statusCode}';
          isLoading = false;
        });
        return;
      }

      final List<dynamic> tasksJsonData = json.decode(tasksResponse.body);
      final List<PlantTask> allTasks = tasksJsonData
          .map((taskJson) => PlantTask.fromJson(taskJson))
          .toList();

      // Filter for incomplete tasks only (show all incomplete tasks)
      final List<PlantTask> incompleteTasks = allTasks
          .where((task) => !task.isCompleted)
          .toList();

      // Fetch user plants
      final plantsResponse = await http.get(
        Uri.parse('$baseUrl/user/${user.id}/plants'),
        headers: {'Content-Type': 'application/json'},
      );

      Map<int, UserPlant> plantsMap = {};
      if (plantsResponse.statusCode == 200) {
        final List<dynamic> plantsJsonData = json.decode(plantsResponse.body);
        for (var plantJson in plantsJsonData) {
          final userPlant = UserPlant.fromJson(plantJson);
          plantsMap[userPlant.userPlantId] = userPlant;
        }
      }

      // Combine tasks with plant data
      final List<TaskWithPlant> tasksWithPlants = incompleteTasks.map((task) {
        final userPlant = plantsMap[task.userPlantId];
        return TaskWithPlant(task: task, userPlant: userPlant);
      }).toList();

      // Sort by chronological order (earliest to latest)
      // This creates a natural timeline regardless of overdue status
      tasksWithPlants.sort((a, b) {
        return a.task.dueDate.compareTo(b.task.dueDate);
      });

      setState(() {
        allTasksWithPlants = tasksWithPlants;
        _applyFilter();
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        error = 'Error fetching data: $e';
        isLoading = false;
      });
    }
  }

  void _applyFilter() {
    switch (currentFilter) {
      case TaskFilter.upcoming:
        // Show only upcoming/current tasks (not overdue) in chronological order
        filteredTasksWithPlants = allTasksWithPlants
            .where((taskWithPlant) => !taskWithPlant.task.isOverdue)
            .toList();
        break;
      case TaskFilter.overdue:
        // Show only overdue tasks, sorted chronologically (most recent overdue first)
        filteredTasksWithPlants = allTasksWithPlants
            .where((taskWithPlant) => taskWithPlant.task.isOverdue)
            .toList();
        break;
    }
  }

  void _setFilter(TaskFilter filter) {
    setState(() {
      currentFilter = filter;
      _applyFilter();
    });
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getEmptyStateMessage() {
    switch (currentFilter) {
      case TaskFilter.upcoming:
        return 'No upcoming tasks!';
      case TaskFilter.overdue:
        return 'No overdue tasks!';
    }
  }

  String _getEmptyStateSubMessage() {
    switch (currentFilter) {
      case TaskFilter.upcoming:
        return 'Your upcoming plant care tasks will appear here.';
      case TaskFilter.overdue:
        return 'You\'re all caught up with your plant care.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Upcoming Tasks filter
                GestureDetector(
                  onTap: () => _setFilter(TaskFilter.upcoming),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentFilter == TaskFilter.upcoming 
                          ? Color(0XFFDEF3E0) 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: currentFilter == TaskFilter.upcoming 
                            ? Color(0XFF399942)! 
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'UPCOMING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: currentFilter == TaskFilter.upcoming 
                            ? Color(0XFF399942) 
                            : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Overdue filter
                GestureDetector(
                  onTap: () => _setFilter(TaskFilter.overdue),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: currentFilter == TaskFilter.overdue 
                          ? Colors.red[50] 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: currentFilter == TaskFilter.overdue 
                            ? Colors.red[200]! 
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'OVERDUE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: currentFilter == TaskFilter.overdue 
                            ? Colors.red[700] 
                            : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              error!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.red[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: fetchTasksWithPlantData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredTasksWithPlants.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  currentFilter == TaskFilter.overdue 
                                      ? Icons.check_circle_outline
                                      : Icons.schedule,
                                  size: 64,
                                  color: currentFilter == TaskFilter.overdue 
                                      ? Colors.green[400]
                                      : Colors.blue[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _getEmptyStateMessage(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: currentFilter == TaskFilter.overdue 
                                        ? Colors.green[600]
                                        : Colors.blue[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getEmptyStateSubMessage(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchTasksWithPlantData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: filteredTasksWithPlants.length,
                              separatorBuilder: (context, index) => const Divider(
                                color: Colors.grey,
                                thickness: 1,
                                height: 32,
                              ),
                              itemBuilder: (context, index) {
                                final taskWithPlant = filteredTasksWithPlants[index];
                                return TaskItem(
                                  task: taskWithPlant.task,
                                  userPlant: taskWithPlant.userPlant,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final PlantTask task;
  final UserPlant? userPlant;

  const TaskItem({
    Key? key, 
    required this.task, 
    this.userPlant,
  }) : super(key: key);

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: userPlant != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserPlantPage(userPlant: userPlant!, plant: userPlant!.plant)),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant image or icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.green[100],
              ),
              child: userPlant?.plant.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        userPlant!.plant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.local_florist,
                            color: Colors.green[600],
                            size: 24,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.local_florist,
                      color: Colors.green[600],
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant name
                  Text(
                    userPlant?.plant.commonName ?? 'Unknown Plant',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Task name
                  Text(
                    task.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Due date with status indicator
                  Row(
                    children: [
                      Text(
                        formatDate(task.dueDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status tag
                      if (task.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red[200]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      if (!task.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green[200]!,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'UPCOMING',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              letterSpacing: 0.5,
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
}

