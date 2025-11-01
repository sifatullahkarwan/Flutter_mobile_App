import 'dart:math';
import 'package:flutter/material.dart';

class BoundingRectangle {
  double x1, y1, x2, y2;
  List<Offset> polygonPoints;
  bool isPolygon;

  BoundingRectangle(this.x1, this.y1, this.x2, this.y2)
      : polygonPoints = [],
        isPolygon = false;

  BoundingRectangle.fromPolygon(List<Offset> points)
      : x1 = 0,
        y1 = 0,
        x2 = 0,
        y2 = 0,
        polygonPoints = List<Offset>.from(points),
        isPolygon = true {
    _calculateBoundingBox();
  }

  void _calculateBoundingBox() {
    if (polygonPoints.isEmpty) return;
    
    x1 = polygonPoints[0].dx;
    y1 = polygonPoints[0].dy;
    x2 = polygonPoints[0].dx;
    y2 = polygonPoints[0].dy;

    for (final point in polygonPoints) {
      x1 = min(x1, point.dx);
      y1 = min(y1, point.dy);
      x2 = max(x2, point.dx);
      y2 = max(y2, point.dy);
    }
  }

  // Convert to absolute coordinates for API
  List<List<double>> toAbsolute(double imageWidth, double imageHeight) {
    if (isPolygon) {
      return polygonPoints.map((point) => [point.dx, point.dy]).toList();
    } else {
      return [
        [x1, y1],
        [x2, y1],
        [x2, y2],
        [x1, y2]
      ];
    }
  }

  // Move the entire shape
  void move(Offset delta) {
    if (isPolygon) {
      for (int i = 0; i < polygonPoints.length; i++) {
        polygonPoints[i] = Offset(
          polygonPoints[i].dx + delta.dx,
          polygonPoints[i].dy + delta.dy,
        );
      }
      _calculateBoundingBox();
    } else {
      x1 += delta.dx;
      y1 += delta.dy;
      x2 += delta.dx;
      y2 += delta.dy;
    }
  }

  // Remove a point from polygon
  void removePolygonPoint(int index) {
    if (isPolygon && index >= 0 && index < polygonPoints.length) {
      polygonPoints.removeAt(index);
      _calculateBoundingBox();
    }
  }

  // Get resize handles for rectangles
  List<Offset> get resizeHandles {
    if (isPolygon) return [];
    
    return [
      Offset(x1, y1), // top-left
      Offset(x2, y1), // top-right
      Offset(x1, y2), // bottom-left
      Offset(x2, y2), // bottom-right
      Offset((x1 + x2) / 2, y1), // top-middle
      Offset((x1 + x2) / 2, y2), // bottom-middle
      Offset(x1, (y1 + y2) / 2), // left-middle
      Offset(x2, (y1 + y2) / 2), // right-middle
    ];
  }

  // Check if point is inside the shape
  bool containsPoint(Offset point) {
    if (isPolygon) {
      return _isPointInPolygon(point, polygonPoints);
    } else {
      return point.dx >= x1 && point.dx <= x2 && point.dy >= y1 && point.dy <= y2;
    }
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;
    
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) /
                     (polygon[j].dy - polygon[i].dy) + polygon[i].dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  @override
  String toString() {
    if (isPolygon) {
      return 'BoundingRectangle(polygon: ${polygonPoints.length} points)';
    } else {
      return 'BoundingRectangle(rect: ($x1, $y1) - ($x2, $y2))';
    }
  }
}