import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:grow_a_ting/model/plant_model.dart'; 
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;



class PlantDetailsPage extends StatelessWidget {
  final Plant plant;

  const PlantDetailsPage({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Add Plant',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ],
           flexibleSpace: FlexibleSpaceBar(
            background: Container(
              margin: const EdgeInsets.only(top: 100), 
              child: Center(
                child: Container(
                  width: 260,
                  height: 260, // square
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: plant.imageUrl != null && plant.imageUrl!.isNotEmpty
                        ? Image.network(
                            plant.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.local_florist,
                                  size: 80,
                                  color: Colors.green,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(
                              Icons.local_florist,
                              size: 80,
                              color: Colors.green,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plant name
                  Text(
                    plant.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Description
                  if (plant.description != null)
                    PlantDescription(description: plant.description!),

                  const SizedBox(height: 20),
                  
                  // Scheduling section
                  if (plant.growthStages.isNotEmpty) ...[
                    const Text(
                      'Scheduling',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: plant.growthStages.map((stage) {
                        return Flexible(
                          child: Container(
                            height: 195, // makes each box taller
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.all(16), // more breathing space
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stage.week,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded( // allows more space for description
                                  child: Text(
                                    stage.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                      height: 1.3,
                                    ),
                                    overflow: TextOverflow.fade,
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    ),
                    
                    const SizedBox(height: 40),
                  ],
                  
                  // Tools needed section
                  if (plant.toolsNeeded.isNotEmpty) ...[
                    const Text(
                      'Tools Needed',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    
                    // Tools grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: plant.toolsNeeded.length,
                      itemBuilder: (context, index) {
                        final tool = plant.toolsNeeded[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getIconForTool(tool.icon ?? tool.name),
                                size: 20,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tool.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (tool.description != null)
                                      Text(
                                        tool.description!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                        ),
                                        // maxLines: 1,
                                        // overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20), // Space for bottom button
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
     bottomNavigationBar: ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8), // More opaque white
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              addToGarden(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add to Garden',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    ),

    );
  }




  IconData _getIconForTool(String toolIdentifier) {
    final tool = toolIdentifier.toLowerCase();
    if (tool.contains('container') || tool.contains('pot') || tool.contains('gallon')) {
      return Icons.local_florist;
    } else if (tool.contains('soil') || tool.contains('compost')) {
      return Icons.grass;
    } else if (tool.contains('sun') || tool.contains('light')) {
      return Icons.wb_sunny;
    } else if (tool.contains('fertilizer') || tool.contains('nutrient')) {
      return Icons.science;
    } else if (tool.contains('water')) {
      return Icons.water_drop;
    } else {
      return Icons.eco;
    }
  }

  // void _addToGarden(BuildContext context) {
  //   // TODO: Implement add to garden functionality
  //   // This would typically make an API call to add the plant to user's garden
    
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('${plant.name} added to your garden!'),
  //       backgroundColor: Colors.green,
  //       behavior: SnackBarBehavior.floating,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(10),
  //       ),
  //       margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
  //     ),
  //   );
    
  //   Navigator.pop(context);
  // }
// Future<void> addToGarden(BuildContext context) async {
//   try {
//     final user = Supabase.instance.client.auth.currentUser;
//     if (user == null) {
//       throw Exception('User not authenticated');
//     }
    
//     // Make API call to your backend
//     final response = await http.post(
//       Uri.parse('http://10.0.2.2:3000/user/${user.id}/plant/${plant.plantId}'),
//       headers: {
//         'Content-Type': 'application/json',
//       },
//     );
    
//     if (response.statusCode != 201) {
//       throw Exception('API call failed with status: ${response.statusCode}');
//     }
    
//     if (!context.mounted) return;
    
//     // Show success message
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('${plant.name} added to your garden!'),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
//       ),
//     );
    
//     Navigator.pop(context);
//   } catch (e) {
//     if (!context.mounted) return;
    
//     // Handle errors
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to add ${plant.name} to your garden: ${e.toString()}'),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//         margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
//       ),
//     );
//   }
// }


Future<void> addToGarden(BuildContext context) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    

    
    // Print debugging info
    print('User ID: ${user.id}');
    print('Plant ID: ${plant.plantId}');
    print('POST URL: http://10.0.2.2:3000/user/${user.id}/plant/${plant.plantId}');
    print('User role: ${user.role}');

    // Make API call to your backend
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/user/${user.id}/plant/${plant.plantId}'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode != 201) {
      throw Exception('API call failed with status: ${response.statusCode}');
    }
    
    if (!context.mounted) return;
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plant.name} added to your garden!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
    
    Navigator.pop(context);
  } catch (e) {
    if (!context.mounted) return;
    
    // Handle errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to add ${plant.name} to your garden: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }
}








}


class PlantDescription extends StatefulWidget {
  final String description;

  const PlantDescription({super.key, required this.description});

  @override
  State<PlantDescription> createState() => _PlantDescriptionState();
}

class _PlantDescriptionState extends State<PlantDescription> {
  bool _expanded = false;

  String get _truncatedText {
    final sentences = widget.description.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length <= 2) return widget.description;
    return '${sentences.take(2).join(' ')}...';
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          height: 1.5,
        ),
        children: [
          TextSpan(text: _expanded ? widget.description : _truncatedText),
          if (widget.description.split(RegExp(r'(?<=[.!?])\s+')).length > 2)
            TextSpan(
              text: _expanded ? ' Read less' : ' Read more',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
            ),
        ],
      ),
    );
  }
}
