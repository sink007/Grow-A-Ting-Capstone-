import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static final _apiKey = dotenv.env['WEATHER_API_KEY'];
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  static Future<Map<String, dynamic>> fetchWeatherFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    final url = '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather: $e');
    }
  }

  // Optional: Method to fetch weather by city name as fallback
  static Future<Map<String, dynamic>> fetchWeatherByCity(String cityName) async {
    final url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch weather for $cityName: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch weather for $cityName: $e');
    }
  }
}