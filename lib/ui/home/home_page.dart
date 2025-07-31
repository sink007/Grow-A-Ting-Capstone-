import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/weather_service.dart';
import '../../widgets/weather_card.dart';
import '../../widgets/weather_alert_card.dart';
import '../weather_alert/weather_alert_page.dart';
import '../../model/plant.dart';
import '../../model/user_plant.dart';
import '../../ui/user_plant/user_plant.dart';
import '../../widgets/sidemenu_widget.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver{
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = true;
  String? weatherErrorMessage;
  String? userEmail;
  List<UserPlant> userPlants = [];
  bool isLoadingPlants = false;

  @override
  void initState() {
    super.initState();
    print('🚀 HomePage initState called');
    final user = Supabase.instance.client.auth.currentUser;
    userEmail = user?.email;

    WidgetsBinding.instance.addObserver(this);

    fetchWeather();
    _fetchUserPlants();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchUserPlants();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _fetchUserPlants();
        }
      });
    }
  }


  Future<void> _fetchUserPlants() async {
  if (!mounted) {
    print('Widget not mounted, returning');
    return;
  }
  
  if (mounted) {
    setState(() {
      isLoadingPlants = true;
    });
  }

  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {

      throw Exception('User not authenticated');
    }

    final url = 'https://grow-a-ting-capstone.onrender.com/user/${user.id}/plants';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (mounted) {
        setState(() {
          userPlants = data.map((json) => UserPlant.fromJson(json)).toList();
          
          userPlants.sort((a, b) => b.date.compareTo(a.date));
          
        });
      }
    } else {
      print('Failed to load plants: ${response.statusCode}');
      print('Error body: ${response.body}');
    }
  } catch (e, stackTrace) {
    print('Error fetching plants: $e');
    print('Stack trace: $stackTrace');
  } finally {
    if (mounted) {
      setState(() {
        isLoadingPlants = false;
      });
    }
    print('_fetchUserPlants completed');
  }
}

  Future<void> fetchWeather() async {
    try {
      LocationData locationData = await _getCurrentLocation();
      
      final data = await WeatherService.fetchWeatherFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      //TESTING: Override temperature in weather data BEFORE setting state
      // data['main']['temp'] = 35.0;
      // print(' Temperature overridden to: ${data['main']['temp']}°C');


      if (mounted) {
        setState(() {
          weatherData = data;
          isLoadingWeather = false;
          weatherErrorMessage = null;
        });
      }
    } catch (e, stackTrace) {
      print('Error fetching weather: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          isLoadingWeather = false;
          weatherErrorMessage = e.toString();
        });
      }
    }
  }

  Future<LocationData> _getCurrentLocation() async {
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Location permissions are denied');
      }
    }

    return await location.getLocation();
  }

  // Temperature Alert Methods
  List<TemperatureAlert> _generateTemperatureAlerts(List<UserPlant> plants, double currentTemp) {
    List<TemperatureAlert> alerts = [];
    for (UserPlant userPlant in plants) {
      final plant = userPlant.plant;
      final idealTemp = plant.idealTemperature;
      // Skip plants without temperature data
      if (idealTemp == null) {
        continue;
      }
      
      if (currentTemp > idealTemp.max) {
        alerts.add(TemperatureAlert(
          plantName: plant.commonName,
          message: "Max temperature for ${plant.commonName} is ${idealTemp.max}°C. Relocate to a shaded area or use a breathable tarp to reduce heat stress.",
          type: AlertType.tooHot,
        ));
      } else if (currentTemp < idealTemp.min) {
        alerts.add(TemperatureAlert(
          plantName: plant.commonName,
          message: "Min temperature for ${plant.commonName} is ${idealTemp.min}°C. Protect plants by moving to a warmer location.",
          type: AlertType.tooCold,
        ));
      } else {
      }
    }
    
    return alerts;
  }

  double? _getCurrentTemperature() {
    if (weatherData == null) return null;
    return weatherData!['main']['temp']?.toDouble();
  }

  bool _hasTemperatureAlerts() {
    final currentTemp = _getCurrentTemperature();
    if (currentTemp == null) return false;
    
    final alerts = _generateTemperatureAlerts(userPlants, currentTemp);
    return alerts.isNotEmpty;
  }

  
Widget _buildTemperatureAlertSection() {
  
  if (isLoadingWeather || weatherData == null || userPlants.isEmpty) {
    return const SizedBox.shrink();
  }

  final currentTemp = _getCurrentTemperature();
  
  if (currentTemp == null) {
    return const SizedBox.shrink();
  }

  final alerts = _generateTemperatureAlerts(userPlants, currentTemp);
  
  return WeatherAlertCard(
    alerts: alerts,
    currentTemperature: currentTemp,
    onSeeAllPressed: alerts.length > 2 ? () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WeatherAlertPage(
            alerts: alerts,
            currentTemperature: currentTemp,
          ),
        ),
      );
    } : null,
  );
}


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
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
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: SideMenu(userEmail: userEmail),
      body: CustomScrollView(
        slivers: [
          // Weather section
          SliverToBoxAdapter(
            child: _buildWeatherSection(),
          ),
          
          // Temperature Alert section
          SliverToBoxAdapter(
            child: _buildTemperatureAlertSection(),
          ),
          
          // Sticky header for "My Plants" section
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            floating: false,
            snap: false,
            elevation: 0,
            backgroundColor: const Color(0xFFFAFAFA),
            toolbarHeight: 70,
            flexibleSpace: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'My Plants',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
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
              ),
            ),
          ),

          // Plants content
          SliverToBoxAdapter(
            child: _buildPlantsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection() {
    if (isLoadingWeather) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (weatherErrorMessage != null) {
      return _buildWeatherErrorWidget();
    }

    if (weatherData == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No weather data available'),
        ),
      );
    }

    return _buildWeatherContent();
  }

  Widget _buildWeatherErrorWidget() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 254, 243, 244),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/no-internet.png',
              width: 60,
              height: 60,
            ),
            const SizedBox(height: 12),
            const Text(
              'Lost in the weeds—no signal!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF399942),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(weatherErrorMessage!),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    isLoadingWeather = true;
                    weatherErrorMessage = null;
                  });
                }
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
      child: WeatherCard(
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
    );
  }

  Widget _buildPlantsContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          
          if (isLoadingPlants)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF399942),
              ),
            )
          else if (userPlants.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userPlants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final userPlant = userPlants[index];
                final plant = userPlant.plant;

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserPlantPage(
                          plant: plant,
                          userPlant: userPlant,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 160),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD3D3D3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: plant.imageUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          plant.imageUrl!,
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
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      plant.commonName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF399942),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _calculatePlantAge(userPlant.date),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.water_drop,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Every ${_getWateringInfo(plant)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.wb_sunny,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _getSunlightInfo(plant),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            )
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
                      color: Colors.black54,
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

  // Helper Methods
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

  String _calculatePlantAge(DateTime plantedDate) {
    final DateTime now = DateTime.now();
    final int daysDiff = now.difference(plantedDate).inDays;
    final int weeks = daysDiff ~/ 7;

    if (weeks == 0) {
      return '$daysDiff days old';
    } else if (weeks == 1) {
      return '1 week old';
    } else {
      return '$weeks weeks old';
    }
  }

  String _getWateringInfo(Plant plant) {
    return plant.water ?? 'Unknown';
  }

  String _getSunlightInfo(Plant plant) {
    return plant.sunlight ?? 'Unknown';
  }
}
