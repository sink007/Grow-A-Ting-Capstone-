import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static final _apiKey = dotenv.env['WEATHER_API_KEY'];
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const int _timeoutSeconds = 15;
  static const int _maxRetries = 3;

  static Future<Map<String, dynamic>> fetchWeatherFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    // Validate API key
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Weather API key not configured');
    }

    // Validate coordinates
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw Exception('Invalid coordinates provided');
    }

    final url = '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        print('Weather API attempt $attempt/$_maxRetries: $url');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'YaadGarden-Mobile-App',
          },
        ).timeout(Duration(seconds: _timeoutSeconds));

        print('Weather API response: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('Weather data received successfully');
          return data;
        } else if (response.statusCode == 401) {
          throw Exception('Invalid API key');
        } else if (response.statusCode == 404) {
          throw Exception('Location not found');
        } else if (response.statusCode == 429) {
          // Rate limited - wait before retry
          if (attempt < _maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          throw Exception('API rate limit exceeded');
        } else {
          throw Exception('Weather service error: ${response.statusCode}');
        }
      } on SocketException {
        if (attempt == _maxRetries) {
          throw Exception('No internet connection');
        }
        await Future.delayed(Duration(seconds: attempt));
      } on HttpException {
        if (attempt == _maxRetries) {
          throw Exception('Network error occurred');
        }
        await Future.delayed(Duration(seconds: attempt));
      } on FormatException {
        throw Exception('Invalid response format');
      } catch (e) {
        if (attempt == _maxRetries) {
          if (e.toString().contains('TimeoutException')) {
            throw Exception('Request timed out');
          }
          throw Exception('Failed to fetch weather: $e');
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    
    throw Exception('Failed to fetch weather after $_maxRetries attempts');
  }

  // Improved city-based weather with similar error handling
  static Future<Map<String, dynamic>> fetchWeatherByCity(String cityName) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Weather API key not configured');
    }

    if (cityName.isEmpty) {
      throw Exception('City name cannot be empty');
    }

    final url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric';
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'YaadGarden-Mobile-App',
          },
        ).timeout(Duration(seconds: _timeoutSeconds));

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else if (response.statusCode == 404) {
          throw Exception('City not found: $cityName');
        } else if (response.statusCode == 401) {
          throw Exception('Invalid API key');
        } else {
          throw Exception('Weather service error: ${response.statusCode}');
        }
      } on SocketException {
        if (attempt == _maxRetries) {
          throw Exception('No internet connection');
        }
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        if (attempt == _maxRetries) {
          throw Exception('Failed to fetch weather for $cityName: $e');
        }
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    
    throw Exception('Failed to fetch weather after $_maxRetries attempts');
  }
}