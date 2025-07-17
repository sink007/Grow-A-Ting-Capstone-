import 'plant.dart';

class UserPlant {
  final DateTime date;
  final Plant plant;
  
  UserPlant({
    required this.date,
    required this.plant,
  });
  
  factory UserPlant.fromJson(Map<String, dynamic> json) {
    // print('=== UserPlant.fromJson Debug ===');
    // print('Full json: $json');
    // print('json type: ${json.runtimeType}');
    // print('date exists: ${json.containsKey('date')}');
    // print('plant_id exists: ${json.containsKey('plant_id')}');
    // print('plant_id type: ${json['plant_id']?.runtimeType}');
    // print('plant_id is null: ${json['plant_id'] == null}');
    
    if (json['plant_id'] != null) {
      print('plant_id content: ${json['plant_id']}');
    }

    return UserPlant(
      date: DateTime.parse(json['date']),
      plant: Plant.fromJson(json['plant_id']), // FIXED: use 'plant_id' instead of 'plant'
    );
  }
}
