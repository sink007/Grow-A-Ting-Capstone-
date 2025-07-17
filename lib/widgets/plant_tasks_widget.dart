import 'package:flutter/material.dart';
import '../model/user_plant.dart';

class PlantTasksWidget extends StatelessWidget {
  final UserPlant userPlant;

  const PlantTasksWidget({Key? key, required this.userPlant})
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
            'No upcoming tasks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll remind you when it’s time to care for your plant.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
