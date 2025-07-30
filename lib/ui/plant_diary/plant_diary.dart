import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../../services/auth_service.dart';

class PlantDiaryPage extends StatefulWidget {
  const PlantDiaryPage({super.key});

  @override
  State<PlantDiaryPage> createState() => _PlantDiaryPageState();
}

class _PlantDiaryPageState extends State<PlantDiaryPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();

  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<String?> _createDiary(String userId) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://grow-a-ting-capstone.onrender.com/user/$userId/diary'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'plant_id': 1, // Replace with actual plant_id if you have one
          'title': 'My Plant Diary'
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> diary = json.decode(response.body);
        return diary['diary_id'].toString();
      }
      return null;
    } catch (e) {
      print('Error creating diary: $e');
      return null;
    }
  }

  Future<String?> _getDiaryId() async {
    try {
      // Get the current authenticated user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        print('No authenticated user found');
        return null;
      }

      final userId = currentUser.id;
      final response = await http.get(
        Uri.parse(
            'https://grow-a-ting-capstone.onrender.com/user/$userId/diaries'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> diaries = json.decode(response.body);
        if (diaries.isNotEmpty) {
          return diaries.first['diary_id'].toString();
        } else {
          // No diary found, create one automatically
          return await _createDiary(userId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting diary ID: $e');
      return null;
    }
  }

  Future<void> _saveDiaryEntry() async {
    try {
      // Check if user is authenticated first
      if (!_authService.isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save diary entries.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final String note = _controller.text.trim();
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      // Validate that we have either note or images
      if (note.isEmpty && _selectedImages.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a note or image before saving.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final supabase = Supabase.instance.client;

      // 1. Get or create diary
      String? diaryId = await _getOrCreateDiary(currentUser.id);
      if (diaryId == null) {
        throw Exception('Unable to create or find diary');
      }

      // 2. Create diary entry first
      final now = DateTime.now().toIso8601String();
      final diaryEntryResponse = await supabase
          .from('diary_entry')
          .insert({
            'diary_id': int.parse(diaryId),
            'note': note.isNotEmpty ? note : null,
            'entry_date': now,
          })
          .select('entry_id')
          .single();

      final entryId = diaryEntryResponse['entry_id'];

      // 3. Upload images and link them to the diary entry
      if (_selectedImages.isNotEmpty) {
        List<Map<String, dynamic>> diaryImageEntries = [];

        for (int i = 0; i < _selectedImages.length; i++) {
          final image = _selectedImages[i];
          final file = File(image.path);
          final bytes = await file.readAsBytes();

          // Create a shorter, more predictable file name
          final originalName = path.basename(image.path);
          final extension = path.extension(originalName).toLowerCase();
          final timestamp = DateTime.now().millisecondsSinceEpoch;

          // Create a short, safe filename
          final fileName =
              'diary_${timestamp}_$i${extension.isEmpty ? '.jpg' : extension}';
          final filePath = 'diary_entries/$fileName';

          // Upload to Supabase storage
          await supabase.storage
              .from('private-uploads')
              .uploadBinary(filePath, bytes);

          // Get public URL
          final publicUrl =
              supabase.storage.from('private-uploads').getPublicUrl(filePath);

          // Insert image record into database
          final imageResponse = await supabase
              .from('image')
              .insert({
                'img_name': fileName,
                'url': publicUrl,
                'file_path': filePath,
                'date_info': DateTime.now().toIso8601String(),
              })
              .select('image_id')
              .single();

          // Prepare diary_images entry
          diaryImageEntries.add({
            'entry_id': entryId,
            'image_id': imageResponse['image_id'],
            'inserted_at': now,
          });
        }

        // Insert all diary_images entries at once
        await supabase.from('diary_images').insert(diaryImageEntries);
      }

      // 4. Success - show message and clear form
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diary entry saved successfully!'),
            backgroundColor: Color(0xFF399942),
          ),
        );
        // Clear the form and navigate back
        _controller.clear();
        setState(() {
          _selectedImages.clear();
        });
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving diary entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Error saving diary entry: $e');
    }
  }

  // Add this helper method to get or create diary
  Future<String?> _getOrCreateDiary(String userId) async {
    try {
      final supabase = Supabase.instance.client;

      // First, try to get existing diary for this user
      final existingDiaries = await supabase
          .from('diary')
          .select('diary_id')
          .eq('user_id', userId)
          .limit(1);

      if (existingDiaries.isNotEmpty) {
        return existingDiaries.first['diary_id'].toString();
      }

      // No diary found, create one
      final newDiary = await supabase
          .from('diary')
          .insert({
            'user_id': userId,
            'plant_id': null, // or specify a plant_id if you have one
            'creation_date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return newDiary['diary_id'].toString();
    } catch (e) {
      print('Error getting or creating diary: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              today,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: () async {
                await _saveDiaryEntry();
                // Only navigate back if save was successful (handled in _saveDiaryEntry)
                if (_controller.text.isEmpty && _selectedImages.isEmpty) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Color(0xFF399942),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: false, // Keyboard appears when page opens
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Add notes...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF399942)),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.photo, color: Color(0xFF399942)),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}