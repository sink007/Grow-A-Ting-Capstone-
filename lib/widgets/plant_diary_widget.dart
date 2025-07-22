import 'package:flutter/material.dart';
import '../model/user_plant.dart';

class PlantDiaryWidget extends StatelessWidget {
  final UserPlant userPlant;

  const PlantDiaryWidget({super.key, required this.userPlant});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
         
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/sad-plant.png', height: 160),
                  const SizedBox(height: 16),
                  const Text(
                    'No diary entries yet',
                    style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start documenting your plant\'s progress and memories!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

         
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/plant_diary', arguments: userPlant);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  margin: const EdgeInsets.only(bottom: 16, right: 8),
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF399942),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
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
        ],
      ),
    );
  }
}
