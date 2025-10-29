import 'package:pixelwipe/services/object_removal_service.dart';

class BoundingRectangle {
  final double x1, y1, x2, y2; // Now using double for normalized coordinates
  
  BoundingRectangle(this.x1, this.y1, this.x2, this.y2);
  
  // Factory constructor for normalized coordinates
  factory BoundingRectangle.fromNormalized(double x1, double y1, double x2, double y2) {
    return BoundingRectangle(x1, y1, x2, y2);
  }
  
  // Convert to absolute coordinates if needed
  Rectangle toAbsolute(double imageWidth, double imageHeight) {
    return Rectangle(
      (x1 * imageWidth).toInt(),
      (y1 * imageHeight).toInt(),
      (x2 * imageWidth).toInt(),
      (y2 * imageHeight).toInt(),
    );
  }
}