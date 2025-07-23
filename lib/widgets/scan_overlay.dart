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
    return LayoutBuilder(builder: (_, constraints) {
      final screenW = constraints.maxWidth;
      final screenH = constraints.maxHeight;
      final left = (screenW - frameSize) / 2;
      final top = (screenH - frameSize) / 2;

      return Stack(
        children: [
          CustomPaint(
            size: Size(screenW, screenH),
            painter: _MaskPainter(frameSize),
          ),
          ..._buildCorners(left, top),
        ],
      );
    });
  }

  List<Widget> _buildCorners(double left, double top) {
    final right = left + frameSize;
    final bottom = top + frameSize;

    return [
      Positioned(left: left, top: top, child: _corner()),
      Positioned(left: right - borderLength, top: top, child: _corner(rotate: true)),
      Positioned(left: left, top: bottom - borderLength, child: _corner(flipY: true)),
      Positioned(left: right - borderLength, top: bottom - borderLength, child: _corner(rotate: true, flipY: true)),
    ];
  }

  Widget _corner({bool rotate = false, bool flipY = false}) {
    return Transform(
      alignment: Alignment.topLeft,
      transform: Matrix4.identity()
        ..rotateZ(rotate ? 1.5708 : 0) // 90 degrees
        ..scale(1.0, flipY ? -1.0 : 1.0),
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
