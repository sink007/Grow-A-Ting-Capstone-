import 'package:flutter/material.dart';
import '../../model/plant.dart';
import '../../model/user_plant.dart';
import '../../widgets/plant_timeline_widget.dart';
import '../../widgets/plant_tasks_widget.dart';
import '../../widgets/plant_diary_widget.dart';
import '../care_guide/care_guide.dart';

class UserPlantPage extends StatefulWidget {
  final UserPlant userPlant;
  final Plant plant;

  const UserPlantPage({
    super.key,
    required this.userPlant,
    required this.plant,
  });

  @override
  State<UserPlantPage> createState() => _UserPlantPageState();
}

class _UserPlantPageState extends State<UserPlantPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    // final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 20,
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
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Plant Header Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Plant Image
                Container(
                  width: 120,
                  height: 120,
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
                const SizedBox(width: 16),

              // Plant Details
             // Plant Info with Care Guide Button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.commonName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.scientificName ?? 'Unknown species',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF399942),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Needs ${plant.sunlight?.toLowerCase() ?? 'unknown'}, ${plant.water?.toLowerCase() ?? 'unknown watering'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CareGuidePage(plant: widget.plant),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF399942),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'See Care Guide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
  
              ],
            ),
          ),
          

          // Tab Bar
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                dividerColor: Colors.transparent, 
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF399942),
                indicatorWeight: 3,
                labelColor: const Color(0xFF399942),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
                tabs: const [
                  Tab(text: 'Timeline'),
                  Tab(text: 'Tasks'),
                  Tab(text: 'Diary'),
                ],
              ),
            ),
          ),

          // Tab Content
          Expanded(
          child: Container(
            color: Colors.white, 
            child: TabBarView(
              controller: _tabController,
              children: [
                PlantTimelineWidget(userPlant: widget.userPlant),
                PlantTasksWidget(userPlant: widget.userPlant),
                PlantDiaryWidget(userPlant: widget.userPlant),
              ],
            ),
          ),
        ),

        ],
      ),
    );
  }
}
