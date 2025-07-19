import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PlantDiaryPage extends StatefulWidget {
  const PlantDiaryPage({super.key});

  @override
  State<PlantDiaryPage> createState() => _PlantDiaryPageState();
}

class _PlantDiaryPageState extends State<PlantDiaryPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String today = DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
              onPressed: () {
                // Save diary entry logic here
                Navigator.pop(context);
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true, // Keyboard appears when page opens
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Color(0xFF399942)),
                  onPressed: () {
                    // Add camera logic here
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.photo, color: Color(0xFF399942)),
                  onPressed: () {
                    // Add gallery logic here
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
