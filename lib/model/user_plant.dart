import 'plant.dart';

class UserPlant {
  final int userPlantId; 
  final DateTime date;
  final Plant plant;
  
  UserPlant({
    required this.userPlantId,
    required this.date,
    required this.plant,
  });
  
  factory UserPlant.fromJson(Map<String, dynamic> json) {
    return UserPlant(
      userPlantId: json['user_plant_id'], 
      date: DateTime.parse(json['date']),
      plant: Plant.fromJson(json['plant_id']),
    );
  }
}