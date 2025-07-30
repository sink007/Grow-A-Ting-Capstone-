import 'dart:io';
import 'package:flutter/material.dart';

class DiagnosisPopup extends StatelessWidget {
  final String title;
  final String description;
  final String solution;
  final File? image;
  final String? imageUrl;
  final double? confidence;
  final VoidCallback onClose;

  const DiagnosisPopup({
    super.key,
    required this.title,
    required this.description,
    required this.solution,
    this.image,
    this.imageUrl,
    this.confidence,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      child: SizedBox.expand(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Top heading row
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Diagnosis",
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: image != null
                          ? Image.file(image!, fit: BoxFit.cover)
                          : (imageUrl != null && imageUrl!.isNotEmpty)
                          ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                      )
                          : const Center(child: Icon(Icons.image_not_supported)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  if (confidence != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Confidence: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "${(confidence! * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: confidence! >= 0.85
                                ? Colors.green.shade800
                                : confidence! >= 0.6
                                ? Colors.orange.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "What you should do",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: solution.split('\n').map((line) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.eco, color: Colors.green, size: 20),
                              const SizedBox(width: 6),
                              Expanded(child: Text(line.trim())),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
