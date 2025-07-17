// Plant model to structure the data
class Plant {
  final int plantId;
  final String commonName;
  final String? scientificName;
  final String? imageUrl;
  final String? description;
  final String? water;
  final String? sunlight;
  
  // New fields for plant details
  final String? type;
  final List<GrowthStage> growthStages;
  final List<Tool> toolsNeeded;
 

  Plant({
    required this.plantId,
    required this.commonName,
    this.scientificName,
    this.imageUrl,
    this.description,
    this.water,
    this.sunlight,
    this.type,
    this.growthStages = const [],
    this.toolsNeeded = const [],
  });

factory Plant.fromJson(Map<String, dynamic> json) {
  // print('=== Plant.fromJson Debug ===');
  // print('Received json:  ${json['plant_id']}');
  // print('json type: ${json.runtimeType}');
  
  // // ignore: unnecessary_null_comparison
  // if (json == null) {
  //   print('ERROR: json is null!');
  //   throw Exception('Plant JSON is null');
  // }
    return Plant(
      plantId: json['plant_id'],
      commonName: json['common_name'],
      scientificName: json['scientific_name'] != null
         ? json['scientific_name'].toString().split("'")[0].trim()
         : null,      
      imageUrl: json['image_url'],
      description: json['description'],
      water: json['watering'],
      sunlight: json['sunlight'],
      type: json['type'],
      growthStages: json['growth_stages'] != null
          ? (json['growth_stages'] as List)
              .map((stage) => GrowthStage.fromJson(stage))
              .toList()
          : [],
      toolsNeeded: json['tools_needed'] != null
          ? (json['tools_needed'] as List)
              .map((tool) => Tool.fromJson(tool))
              .toList()
          : [],
    );
  }
}


class GrowthStage {
  final String week;
  final String description;

  GrowthStage({
    required this.week,
    required this.description,
  });

  factory GrowthStage.fromJson(Map<String, dynamic> json) {
    return GrowthStage(
      week: json['week'],
      description: json['description'],
    );
  }
}

class Tool {
  final String name;
  final String? description;
  final String? icon;

  Tool({
    required this.name,
    this.description,
    this.icon,
  });

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}