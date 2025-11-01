import 'package:flutter/material.dart';
import 'package:pixelwipe/models/bounding_rectangle.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Offset> points;
  final List<BoundingRectangle> boxes;
  final bool isDrawing;
  final Size imageSize;
  final bool isPolygonMode;
  final BoundingRectangle? selectedBox;
  final double zoomLevel;

  BoundingBoxPainter({
    required this.points,
    required this.boxes,
    required this.isDrawing,
    required this.imageSize,
    this.isPolygonMode = false,
    this.selectedBox,
    this.zoomLevel = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.0 / zoomLevel
      ..style = PaintingStyle.stroke;

    final selectedPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 1.0 / zoomLevel
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.red.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final selectedFillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0 / zoomLevel
      ..style = PaintingStyle.stroke;

    // Draw current points being placed
    if (isDrawing) {
      for (final point in points) {
        // Draw point
        canvas.drawCircle(point, 6 / zoomLevel, Paint()..color = Colors.red);
        
        // Draw remove button (X) for each point in polygon mode
        if (isPolygonMode) {
          canvas.drawCircle(point, 8 / zoomLevel, Paint()..color = Colors.red);
          
          // Draw X mark
          final xPaint = Paint()
            ..color = Colors.white
            ..strokeWidth = 2.0 / zoomLevel
            ..style = PaintingStyle.stroke;
          
          canvas.drawLine(
            Offset(point.dx - 6 / zoomLevel, point.dy - 6 / zoomLevel),
            Offset(point.dx + 6 / zoomLevel, point.dy + 6 / zoomLevel),
            xPaint,
          );
          canvas.drawLine(
            Offset(point.dx + 6 / zoomLevel, point.dy - 6 / zoomLevel),
            Offset(point.dx - 6 / zoomLevel, point.dy + 6 / zoomLevel),
            xPaint,
          );
        }
      }

      // Draw connecting lines for current points
      if (points.length > 1) {
        for (int i = 0; i < points.length - 1; i++) {
          canvas.drawLine(points[i], points[i + 1], paint);
        }
        
        // Close the polygon if in polygon mode
        if (isPolygonMode && points.length > 2) {
          canvas.drawLine(points.last, points.first, paint);
        }
      }
    }

    // Draw completed bounding boxes
    for (final box in boxes) {
      final isSelected = selectedBox == box;
      final currentPaint = isSelected ? selectedPaint : paint;
      final currentFillPaint = isSelected ? selectedFillPaint : fillPaint;

      if (box.isPolygon) {
        // Draw polygon
        if (box.polygonPoints.length > 2) {
          final path = Path();
          path.moveTo(box.polygonPoints[0].dx, box.polygonPoints[0].dy);
          for (int i = 1; i < box.polygonPoints.length; i++) {
            path.lineTo(box.polygonPoints[i].dx, box.polygonPoints[i].dy);
          }
          path.close();
          
          canvas.drawPath(path, currentFillPaint);
          canvas.drawPath(path, currentPaint);
          
          // Draw polygon points with remove buttons
          for (int i = 0; i < box.polygonPoints.length; i++) {
            final point = box.polygonPoints[i];
            canvas.drawCircle(point, 6 / zoomLevel, Paint()..color = Colors.red);
            
            // Draw remove button for selected polygons
            if (isSelected) {
              canvas.drawCircle(point, 12 / zoomLevel, Paint()..color = Colors.red);
              
              // Draw X mark
              final xPaint = Paint()
                ..color = Colors.white
                ..strokeWidth = 2.0 / zoomLevel
                ..style = PaintingStyle.stroke;
              
              canvas.drawLine(
                Offset(point.dx - 6 / zoomLevel, point.dy - 6 / zoomLevel),
                Offset(point.dx + 6 / zoomLevel, point.dy + 6 / zoomLevel),
                xPaint,
              );
              canvas.drawLine(
                Offset(point.dx + 6 / zoomLevel, point.dy - 6 / zoomLevel),
                Offset(point.dx - 6 / zoomLevel, point.dy + 6 / zoomLevel),
                xPaint,
              );
            }
          }
        }
      } else {
        // Draw rectangle
        final rect = Rect.fromLTRB(box.x1, box.y1, box.x2, box.y2);
        
        // Draw filled rectangle
        canvas.drawRect(rect, currentFillPaint);
        
        // Draw border
        canvas.drawRect(rect, currentPaint);
        
        // Draw resize handles for selected rectangles
        if (isSelected) {
          final handles = box.resizeHandles;
          for (final handle in handles) {
            canvas.drawCircle(handle, 6 / zoomLevel, handleBorderPaint);
            canvas.drawCircle(handle, 4 / zoomLevel, handlePaint);
          }
        } else {
          // Draw corner points for non-selected rectangles
          canvas.drawCircle(Offset(box.x1, box.y1), 4 / zoomLevel, Paint()..color = Colors.red);
          canvas.drawCircle(Offset(box.x2, box.y1), 4 / zoomLevel, Paint()..color = Colors.red);
          canvas.drawCircle(Offset(box.x1, box.y2), 4 / zoomLevel, Paint()..color = Colors.red);
          canvas.drawCircle(Offset(box.x2, box.y2), 4 / zoomLevel, Paint()..color = Colors.red);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}