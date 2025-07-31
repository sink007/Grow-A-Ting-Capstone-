import 'package:flutter/material.dart';

class ScanOverlay extends StatelessWidget {
  final double borderLength;
  final double borderWidth;
  final double frameSize;

  const ScanOverlay({
    super.key,
    this.borderLength = 30,
    this.borderWidth = 4,
    this.frameSize = 250,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final left = (screenW - frameSize) / 2;
    final top = (screenH - frameSize) / 2;

    return Stack(
      children: [
        CustomPaint(
          size: Size(screenW, screenH),
          painter: _MaskPainter(frameSize),
        ),
        // Overlay corners
        Positioned(left: left, top: top, child: _corner()),
        Positioned(left: left + frameSize - borderLength, top: top, child: _corner(rotation: 90)),
        Positioned(left: left, top: top + frameSize - borderLength, child: _corner(rotation: 270)),
        Positioned(left: left + frameSize - borderLength, top: top + frameSize - borderLength, child: _corner(rotation: 180)),
      ],
    );
  }

  Widget _corner({int rotation = 0}) {
    return Transform.rotate(
      angle: rotation * 3.14159265 / 180,
      child: SizedBox(
        width: borderLength,
        height: borderLength,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: borderLength,
                height: borderWidth,
                color: Colors.white,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: borderWidth,
                height: borderLength,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final double frameSize;

  _MaskPainter(this.frameSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRect(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: frameSize,
        height: frameSize,
      ));
    final overlay = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(overlay, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
