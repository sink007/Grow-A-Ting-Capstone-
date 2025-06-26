import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final String date;
  final String location;
  final String weatherDescription;
  final String temperature;
  final String humidity;
  final String windSpeed;
  final IconData weatherIcon;

  const WeatherCard({
    super.key,
    required this.date,
    required this.location,
    required this.weatherDescription,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
         color: Color(0xFFDAEEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: temperature,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' • ${weatherDescription.split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),    

                const SizedBox(height: 4),
                Text('Humidity: $humidity • Wind: $windSpeed'),
              ],
            ),
          ),

          // Icon
          Icon(
            weatherIcon,
            size: 48,
            color: Colors.orangeAccent,
          ),
        ],
      ),
    );
  }
}
