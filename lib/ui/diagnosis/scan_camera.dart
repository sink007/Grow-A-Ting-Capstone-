import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:grow_a_ting/widgets/scan_overlay.dart';

class ScanCameraPage extends StatefulWidget {
  final Future<void> Function(File imageFile) onImageCaptured;

  const ScanCameraPage({super.key, required this.onImageCaptured});

  @override
  State<ScanCameraPage> createState() => _ScanCameraPageState();
}

class _ScanCameraPageState extends State<ScanCameraPage> {
  CameraController? _controller;
  bool _isCameraReady = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final rear = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _controller = CameraController(rear, ResolutionPreset.medium);

    await _controller!.initialize();
    if (!mounted) return;
    setState(() => _isCameraReady = true);
  }

  Future<void> _captureAndScan() async {
    if (!_controller!.value.isInitialized || _isScanning) return;

    setState(() => _isScanning = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final xFile = await _controller!.takePicture();
      await xFile.saveTo(filePath);
      final file = File(filePath);

      if (mounted) {
        Navigator.pop(context); // ✅ pop camera screen
        await widget.onImageCaptured(file); // ✅ run diagnosis AFTER pop
      }
    } catch (e) {
      print("❌ Camera error: $e");
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraReady
          ? Stack(
        children: [
          // Live camera preview
          SizedBox.expand(child: CameraPreview(_controller!)),

          // Scan overlay with corners and dark mask
          const ScanOverlay(),

          // Shutter and label
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _captureAndScan,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade700, width: 3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tap to scan the leaf",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Scanning overlay
          if (_isScanning)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Getting to the root of it...",
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "We're checking for diseases, pests,\nor stress. Almost there!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
