import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:grow_a_ting/widgets/scan_overlay.dart';
import 'package:image/image.dart' as img;

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
  File? _previewFile;
  FlashMode _flashMode = FlashMode.off;

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
    await _controller!.setFlashMode(FlashMode.off);
    if (!mounted) return;
    setState(() => _isCameraReady = true);
  }


  Future<void> _captureAndScan() async {
    if (!_controller!.value.isInitialized || _isScanning) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final rawPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_raw.jpg');
      final croppedPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_cropped.jpg');

      final xFile = await _controller!.takePicture();
      await xFile.saveTo(rawPath);
      final rawFile = File(rawPath);

      final original = img.decodeImage(await rawFile.readAsBytes());
      if (original == null) return;

      final img.Image oriented = img.bakeOrientation(original);

      final imgW = oriented.width;
      final imgH = oriented.height;

      final screenW = MediaQuery.of(context).size.width;
      final screenH = MediaQuery.of(context).size.height;
      const frameSize = 250.0;

      final scaleX = imgW / screenW;
      final scaleY = imgH / screenH;

      final cropW = (frameSize * scaleX).round();
      final cropH = (frameSize * scaleY).round();
      final cropX = ((screenW - frameSize) / 2 * scaleX).round();
      final cropY = ((screenH - frameSize) / 2 * scaleY).round();

      final cropped = img.copyCrop(
        oriented,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );
      final croppedFile = File(croppedPath)..writeAsBytesSync(img.encodeJpg(cropped));

      if (mounted) {
        setState(() => _previewFile = croppedFile);
      }
    } catch (e) {
      print("❌ Camera crop error: $e");
    }
  }

  void _onRetry() {
    setState(() => _previewFile = null);
  }

  Future<void> _onConfirm() async {
    if (_previewFile == null) return;
    setState(() => _isScanning = true);
    Navigator.pop(context);
    await widget.onImageCaptured(_previewFile!);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;

    FlashMode newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _controller!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      print('⚠️ Failed to toggle flash: $e');
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
          ? (_previewFile != null
          ? Stack(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _previewFile!,
                width: 320,
                height: 320,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade800,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _onConfirm,
                  icon: const Icon(Icons.search),
                  label: const Text("Diagnose"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          const ScanOverlay(),

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

          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(
                _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
          ),

          if (_isScanning)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ),
        ],
      ))
          : const Center(child: CircularProgressIndicator()),
    );
  }
}