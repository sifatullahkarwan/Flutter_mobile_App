import 'dart:io';
import 'package:http/http.dart' as http;

class ObjectRemovalService {
  static const String baseUrl = 'https://enhance-app-930445283274.us-central1.run.app/'; // Fix URL format
  
  static Future<File?> removeObject({
    required File imageFile,
    List<Rectangle>? boundingBoxes,
    String? objectDescription,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
      
      // Add bounding boxes if provided
      if (boundingBoxes != null && boundingBoxes.isNotEmpty) {
        final bboxString = boundingBoxes
            .map((rect) => '${rect.x1},${rect.y1},${rect.x2},${rect.y2}')
            .join('|');
        request.fields['bboxes'] = bboxString;
      }
      
      // Add object description if provided
      if (objectDescription != null && objectDescription.isNotEmpty) {
        request.fields['description'] = objectDescription;
      }
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        // Get the processed image
        final bytes = await response.stream.toBytes();
        
        // Save to temporary file
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/removed_object_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(bytes);
        
        return tempFile;
      } else {
        final error = await response.stream.bytesToString();
        throw Exception('Failed to remove object: ${response.statusCode} - $error');
      }
    } catch (e) {
      throw Exception('Error removing object: $e');
    }
  }
}

class Rectangle {
  final int x1, y1, x2, y2;
  
  Rectangle(this.x1, this.y1, this.x2, this.y2);
  
  // Helper method to create from coordinates
  static Rectangle fromCoordinates(int x1, int y1, int x2, int y2) {
    return Rectangle(x1, y1, x2, y2);
  }
}