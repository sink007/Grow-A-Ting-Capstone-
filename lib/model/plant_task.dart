class PlantTask {
  final int taskId;
  final int userPlantId;
  final int templateId;
  final String progress;
  final bool isCompleted;
  final DateTime dueDate;
  final String description;
  final bool isOverdue;
  final DateTime? dateCompleted;

  PlantTask({
    required this.taskId,
    required this.userPlantId,
    required this.templateId,
    required this.progress,
    required this.isCompleted,
    required this.dueDate,
    required this.description,
    required this.isOverdue,
    required this.dateCompleted,
  });

  factory PlantTask.fromJson(Map<String, dynamic> json) {
    final dueDate = DateTime.parse(json['due_date']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    return PlantTask(
      taskId: json['task_id'],
      userPlantId: json['user_plant_id'],
      templateId: json['template_id'],
      progress: json['progress'],
      isCompleted: json['is_completed'],
      dueDate: dueDate,
      description: json['description'],
      isOverdue: taskDate.isBefore(today) && !json['is_completed'],
      dateCompleted: json['date_completed'] != null
          ? DateTime.parse(json['date_completed'])
          : null,
    );
  }

  PlantTask copyWith({
    bool? isCompleted,
    String? progress,
    DateTime? dateCompleted,
  }) {
    return PlantTask(
      taskId: taskId,
      userPlantId: userPlantId,
      templateId: templateId,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate,
      description: description,
      isOverdue: isOverdue,
      dateCompleted: dateCompleted,
    );
  }
}
