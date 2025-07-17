import 'package:flutter/material.dart';
import '../model/user_plant.dart';

class PlantTimelineWidget extends StatelessWidget {
  final UserPlant userPlant;

  const PlantTimelineWidget({Key? key, required this.userPlant})
      : super(key: key);

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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
