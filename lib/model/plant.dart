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
  final Map<String, String>? wateringCondition;
  final Pruning? pruning;
  final IdealTemperature? idealTemperature;

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
    this.wateringCondition,
    this.pruning,
    this.idealTemperature,
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
      wateringCondition: json['watering_condition'] != null
          ? Map<String, String>.from(json['watering_condition'])
          : null,
      pruning: json['pruning'] != null
          ? Pruning.fromJson(json['pruning'])
          : null,
      idealTemperature: json['ideal_temperature'] != null
    ? IdealTemperature.fromJson(json['ideal_temperature'])
    : null,

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

class Pruning {
  final String condition;
  final String frequency;

  Pruning({
    required this.condition,
    required this.frequency,
  });

  factory Pruning.fromJson(Map<String, dynamic> json) {
    return Pruning(
      condition: json['Condition'],
      frequency: json['Frequency'],
    );
  }
}


class IdealTemperature {
  final int min;
  final int max;

  IdealTemperature({
    required this.min,
    required this.max,
  });

  factory IdealTemperature.fromJson(Map<String, dynamic> json) {
    return IdealTemperature(
      min: json['min'],
      max: json['max'],
    );
  }
}
