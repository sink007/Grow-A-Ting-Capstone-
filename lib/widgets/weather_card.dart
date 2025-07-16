import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final String date;
  final String location;
  final String weatherDescription;
  final String temperature;
  final String humidity;
  final String windSpeed;
  final Widget weatherIcon;

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

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//      decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [ Color(0xFFC0E0FF), Color(0xFFDAEEFF), Color(0xFFC0E0FF)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         ),
//       child: Row(
//         children: [
//           // Text Info
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(date, style: const TextStyle(fontSize: 12, color: Colors.black87)),
//                 const SizedBox(height: 4),
//                 Text(
//                   location,
//                   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text.rich(
//                   TextSpan(
//                     children: [
//                       TextSpan(
//                         text: temperature,
//                         style: const TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       TextSpan(
//                         text: ' • ${weatherDescription.split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     const Icon(Icons.water_drop, size: 16, color: Colors.blueAccent),
//                     const SizedBox(width: 4),
//                     Text(humidity),
//                     const SizedBox(width: 16),
//                     const Icon(Icons.air, size: 16, color: Colors.grey),
//                     const SizedBox(width: 4),
//                     Text(windSpeed),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Icon
//           SizedBox(
//             width: 100,
//             height: 100,
//             child: weatherIcon,
//           ),
//         ],
//       ),
//     );
//   }
// }



@override
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFC0E0FF), Color(0xFFDAEEFF), Color(0xFFC0E0FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        // Text Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(fontSize: 18,  color: Color(0xFF505A6B), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Big Temperature + Smaller Description
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: temperature,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF505A6B),
                      ),
                    ),
                    TextSpan(
                      text: '  ${weatherDescription.split(' ').map((e) => e[0].toUpperCase() + e.substring(1)).join(' ')}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.water_drop, size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(humidity),
                  const SizedBox(width: 16),
                  const Icon(Icons.air, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(windSpeed),
                ],
              ),
            ],
          ),
        ),

        // Icon
        SizedBox(
          width: 120,
          height: 120,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: weatherIcon,
          ),
        ),
      ],
    ),
  );
}
}
