
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/weather_service.dart';
import '../../widgets/weather_card.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? errorMessage;


// Add these state variables in your class
List<Map<String, dynamic>> userPlants = [];
bool isLoadingPlants = false;

// Add this method to fetch user plants
Future<void> _fetchUserPlants() async {
  setState(() {
    isLoadingPlants = true;
    
  });

  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/user/${user.id}/plants'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        userPlants = data.cast<Map<String, dynamic>>();
      });
    } else {
      print('Failed to load plants: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching plants: $e');
  } finally {
    setState(() {
      isLoadingPlants = false;
    });
  }
}

  @override
  void initState() {
    super.initState();
    fetchWeather();
    _fetchUserPlants();
  }

  Future<void> fetchWeather() async {
    try {
      LocationData locationData = await _getCurrentLocation();
      final data = await WeatherService.fetchWeatherFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      setState(() {
        weatherData = data;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<LocationData> _getCurrentLocation() async {
    Location location = Location();

    // Check if location service is enabled
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
    }

    // Check for permissions
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Location permissions are denied');
      }
    }

    // Get the current location
    return await location.getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
       titleSpacing: 0,
        title: RichText(
          text: const TextSpan(
            style:  TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500, // Medium-bold
            ),
            children: [
               TextSpan(
                text: 'Yaad ',
                style: TextStyle(color: Colors.black),
              ),
               TextSpan(
                text: 'Garden',
                style: TextStyle(color: Color(0xFF025A1E)),
              ),
            ],
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        
      ),
      body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : errorMessage != null
        ? _buildErrorWidget()
        : weatherData == null
            ? const Center(child: Text('No weather data available'))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWeatherContent(),
                    _buildMyPlantsSection(),
                  ],
                ),
    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to get weather data',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(errorMessage!),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                fetchWeather();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildWeatherContent() {
  final weatherCondition = weatherData!['weather'][0]['main'];
  final weatherIconPath = _getWeatherIconPath(weatherCondition);

  return Padding(
    padding: const EdgeInsets.all(16),
    child: SingleChildScrollView(
      child: Column(
        children: [
          // Weather card
          WeatherCard(
            date: DateFormat('EEEE, d MMM').format(DateTime.now()),
            location: weatherData!['name'] ?? 'Your Garden',
            weatherDescription: weatherData!['weather'][0]['description'],
            temperature: '${weatherData!['main']['temp'].round()}°C',
            humidity: '${weatherData!['main']['humidity']}%',
            windSpeed: '${weatherData!['wind']['speed']} m/s',
            weatherIcon: Image.asset(
              weatherIconPath,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}


  String _getErrorMessage(String error) {
    if (error.contains('Location services are disabled')) {
      return 'Please enable location services in your device settings.';
    } else if (error.contains('Location permissions are denied')) {
      return 'Please allow location access to get weather for your area.';
    } else if (error.contains('Failed to fetch weather')) {
      return 'Unable to connect to weather service. Check your internet connection.';
    } else {
      return 'Something went wrong. Please try again.';
    }
  }
  
  String _getWeatherIconPath(String condition) {
  switch (condition) {
    case 'Clear':
      return 'assets/images/clear.png';
    case 'Clouds':
      return 'assets/images/clouds.png';
    case 'Rain':
      return 'assets/images/rain.png';
    case 'Drizzle':
      return 'assets/images/rain.png';
    case 'Thunderstorm':
      return 'assets/images/thunderstorm.png';
    case 'Snow':
      return 'assets/images/snow.png';
    case 'Mist':
    case 'Fog':
    case 'Haze':
      return 'assets/images/fog.png';
    default:
      return 'assets/images/clouds.png';
  }
}


  
// Helper method to calculate plant age
String _calculatePlantAge(String plantDate) {
  final DateTime planted = DateTime.parse(plantDate);
  final DateTime now = DateTime.now();
  final int daysDiff = now.difference(planted).inDays;
  final int weeks = daysDiff ~/ 7;
  
  if (weeks == 0) {
    return '$daysDiff days old';
  } else if (weeks == 1) {
    return '1 week old';
  } else {
    return '$weeks weeks old';
  }
}

// Helper method to get watering info from plant data
String _getWateringInfo(Map<String, dynamic> plantData) {
  final watering = plantData['watering'];
  if (watering == null) return 'Unknown';
  return watering.toString();
}

// Helper method to get sunlight info from plant data
String _getSunlightInfo(Map<String, dynamic> plantData) {
  final sunlight = plantData['sunlight'];
  if (sunlight == null) return 'Unknown';
  return sunlight.toString();
}

// Updated My Plants Section
Widget _buildMyPlantsSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Plants',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/plants/find');
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF399942),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Loading state
        if (isLoadingPlants)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF399942),
            ),
          )
        
        // Plants grid
        else if (userPlants.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 2, // Controls height
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              
            ),
            itemCount: userPlants.length,
            itemBuilder: (context, index) {
              final userPlant = userPlants[index];
              final plant = userPlant['plant'];
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Plant Image
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD3D3D3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: plant['image_url'] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    plant['image_url'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.local_florist,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.local_florist,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 25),

                      // Plant Info
                      Expanded(
                        flex: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Plant name
                            Text(
                              plant['common_name'] ?? plant['scientific_name'] ?? 'Unknown Plant',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // Age info
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16, color: Colors.red),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _calculatePlantAge(userPlant['date']),
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Watering info
                            Row(
                              children: [
                                const Icon(Icons.water_drop, size: 16, color: Colors.blue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _getWateringInfo(plant),
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Sunlight info
                            Row(
                              children: [
                                const Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _getSunlightInfo(plant),
                                    style: const TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )

                ),
              );
            },
          )
        
        // Empty state
        else
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/potted-plants.png',
                  height: 220,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No plants yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap the + button to add your first plant!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 24),
      ],
    ),
  );
}
  
  // // My Plants Section
  // Widget _buildMyPlantsSection() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Text(
  //               'My Plants',
  //               style: TextStyle(
  //                 fontSize: 32,
  //                 fontWeight: FontWeight.w500,
  //               ),
  //             ),
  //             InkWell(
  //               onTap: () {
  //                  Navigator.pushNamed(context, '/plants/find');
  //               },
  //               child: Container(
  //                 padding: const EdgeInsets.all(6),
  //                 decoration: const BoxDecoration(
  //                   color: Color(0xFF399942),
  //                   shape: BoxShape.circle,
  //                 ),
  //                 child: const Icon(
  //                   Icons.add,
  //                   color: Colors.white,
  //                   size: 24,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 24),

  //         // Empty state placeholder for now
  //         Center(
  //           child: Column(
  //             children: [
  //               Image.asset(
  //                 'assets/images/potted-plants.png', 
  //                 height: 220,
  //               ),
  //               const SizedBox(height: 16),
  //               const Text(
  //                 'No plants yet',
  //                 style: TextStyle(
  //                   fontSize: 20,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               const Text(
  //                 'Tap the + button to add your first plant!',
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: Colors.grey,
  //                 ),
  //                 textAlign: TextAlign.center,
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 24),
  //       ],
  //     ),
  //   );
  // }
  
  
}