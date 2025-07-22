import 'package:flutter/material.dart';
import '../model/user_plant.dart';

class PlantTimelineWidget extends StatelessWidget {
  final UserPlant userPlant;

  const PlantTimelineWidget({super.key, required this.userPlant});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/sad-plant.png', height: 160),
          const SizedBox(height: 16),
          const Text(
            'No timeline events yet',
            style: TextStyle(color: Colors.black54 , fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your plant\'s journey will show up here.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
