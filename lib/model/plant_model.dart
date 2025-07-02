// Plant model to structure the data
class Plant {
  final int plantId;
  final String name;
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
    required this.name,
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
    return Plant(
      plantId: json['plant_id'],
      name: json['common_name'],
      scientificName: json['scientific_name'],
      imageUrl: json['image_url'],
      description: json['description'],
      water: json['water'],
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