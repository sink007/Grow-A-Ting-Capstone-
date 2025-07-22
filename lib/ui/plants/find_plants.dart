import 'package:flutter/material.dart';
import 'package:grow_a_ting/ui/plant_detail/plant_detail.dart';
import 'package:grow_a_ting/widgets/sidemenu_widget.dart';
import 'package:http/http.dart' as http;
import 'package:grow_a_ting/model/plant.dart';
import 'dart:convert';

class FindPlantsPage extends StatefulWidget {
  const FindPlantsPage({super.key});

  @override
  State<FindPlantsPage> createState() => _FindPlantsPageState();
}

class _FindPlantsPageState extends State<FindPlantsPage> {
  List<Plant> plants = [];
  List<Plant> filteredPlants = [];
  String? userEmail;

  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  static const String apiUrl = 'http://10.0.2.2:3000/plants';

  @override
  void initState() {
    super.initState();
    fetchPlants();
    searchController.addListener(_filterPlants); 
  }

  Future<void> fetchPlants() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          plants = data.map((json) => Plant.fromJson(json)).toList();
          filteredPlants = plants; // Initialize filtered list
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load plants: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plants: $e')),
        );
      }
    }
  }

 void _filterPlants() {
  final query = searchController.text.toLowerCase();
  setState(() {
    if (query.isEmpty) {
      filteredPlants = plants;
    } else {
      filteredPlants = plants.where((plant) {
        return plant.commonName.toLowerCase().contains(query) ||
               (plant.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      ),
      drawer: SideMenu(userEmail: userEmail),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading
            const Text(
              'Find Your',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const Text(
              'Next Plant to Grow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),

            // Search and filter row
            Row(
              children: [
                // Search bar
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search plants',
                        hintStyle: TextStyle(
                        color: Colors.grey, 
                      ),        
                      border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Filter button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Plants grid 
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredPlants.isEmpty
                      ? Center(
                          child: Text(
                            searchController.text.isEmpty 
                                ? 'No plants available'
                                : 'No plants found matching "${searchController.text}"',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await fetchPlants();
                            _filterPlants(); // Re-apply filter after refresh
                          },
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: filteredPlants.length, // Use filteredPlants
                            itemBuilder: (context, index) {
                              final plant = filteredPlants[index]; // Use filteredPlants
                              return PlantCard(plant: plant);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.removeListener(_filterPlants); 
    searchController.dispose();
    super.dispose();
  }
}

class PlantCard extends StatelessWidget {
  final Plant plant;
  
  const PlantCard({super.key, required this.plant});

  // Helper method to wrap text if more than 2 words
  List<String> _wrapTextIfNeeded(String text) {
    List<String> words = text.split(' ');
    if (words.length > 2) {
      return [words[0], words.sublist(1).join(' ')];
    }
    return [text];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFF399942), 
          width: 1,
        ),
      ),
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlantDetailsPage(plant: plant),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Plant image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                      ? Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Icon(
                                Icons.local_florist,
                                size: 40,
                                color: Colors.green,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFF5F5F5),
                          child: const Icon(
                            Icons.local_florist,
                            size: 40,
                            color: Colors.green,
                          ),
                        ),
                ),
              ),
            ),

            // Plant info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plant name and add button row
                    Row(
                      children: [
                        // Plant name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...(_wrapTextIfNeeded(plant.commonName).map((line) => 
                                Text(
                                  line,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF025A1E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              )),
                            ],
                          ),
                        ),
                        
                        // Add button
                        const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 20,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),

                    // Scientific name
                    if (plant.scientificName != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...(_wrapTextIfNeeded(plant.scientificName!).map((line) => 
                            Text(
                              line,
                              style: const TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF4B7742),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          )),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}