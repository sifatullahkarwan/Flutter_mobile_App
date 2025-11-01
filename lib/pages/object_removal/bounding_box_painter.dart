import 'package:flutter/material.dart';
import 'package:pixelwipe/models/bounding_rectangle.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Offset> points;
  final List<BoundingRectangle> boxes;
  final bool isDrawing;
  final Size? imageSize;

  BoundingBoxPainter({
    required this.points,
    required this.boxes,
    required this.isDrawing,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final boxPaint = Paint()
      ..color = Color(0xFFFF6B35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw existing bounding boxes
    for (final box in boxes) {
      if (imageSize != null) {
        // Convert normalized coordinates back to absolute for display
        final absX1 = box.x1 * imageSize!.width;
        final absY1 = box.y1 * imageSize!.height;
        final absX2 = box.x2 * imageSize!.width;
        final absY2 = box.y2 * imageSize!.height;

        final rect = Rect.fromLTRB(absX1, absY1, absX2, absY2);
        canvas.drawRect(rect, boxPaint);
        
        // Add box number
        _drawText(canvas, '${boxes.indexOf(box) + 1}', 
            Offset(absX1 + 5, absY1 + 5));
      }
    }

    // Draw current points and connecting lines
    if (isDrawing) {
      // Draw points
      for (final point in points) {
        canvas.drawCircle(point, 6, pointPaint);
        // Draw point number
        _drawText(canvas, '${points.indexOf(point) + 1}', point + Offset(8, -8));
      }

      // Draw connecting lines
      if (points.length > 1) {
        for (int i = 0; i < points.length - 1; i++) {
          canvas.drawLine(points[i], points[i + 1], linePaint);
        }
      }

      // Connect last point to first point if we have 4 points
      if (points.length == 4) {
        canvas.drawLine(points[3], points[0], linePaint);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset position) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant BoundingBoxPainter oldDelegate) {
    return points != oldDelegate.points || 
           boxes != oldDelegate.boxes || 
           isDrawing != oldDelegate.isDrawing ||
           imageSize != oldDelegate.imageSize;
  }
}