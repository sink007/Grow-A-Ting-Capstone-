
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import '../../services/weather_service.dart';
import '../../widgets/weather_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchWeather();
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        
      ),
      // backgroundColor: Colors.white,
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
              weatherIcon: _getWeatherIcon(weatherData!['weather'][0]['main']),
            ),
            const SizedBox(height: 16),
            // You can add more widgets here later
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

  IconData _getWeatherIcon(String condition) {
    switch (condition) {
      case 'Clouds':
        return Icons.cloud;
      case 'Rain':
        return Icons.umbrella;
      case 'Clear':
        return Icons.wb_sunny;
      case 'Thunderstorm':
        return Icons.flash_on;
      case 'Snow':
        return Icons.ac_unit;
      case 'Mist':
      case 'Fog':
        return Icons.foggy;
      default:
        return Icons.cloud_queue;
    }
  }


  
  // My Plants Section
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

          // Empty state placeholder for now
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
  
  
}