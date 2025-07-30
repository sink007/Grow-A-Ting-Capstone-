import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PlantIdApi {
  static final String apiKey = dotenv.env['PLANT_ID_API_KEY'] ?? '';
  static const String endpoint = 'https://api.plant.id/v3/identification';

  static Future<bool> isLeaf(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = {
        "images": [base64Image]
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': apiKey,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final result = json['result'];
        final isPlant = result?['is_plant']?['binary'] ?? false;
        return isPlant == true;
      } else {
        throw Exception('Plant.id API failed: ${response.statusCode}');
      }
    } catch (e) {
      print("❌ Error in isLeaf: $e");
      return false;
    }
  }
}
