import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ObjectRemovalService {
  static const String baseUrl = 'https://pixelwipe-app-613582967408.us-central1.run.app/';
  
  static Future<File?> removeObject({
    required File imageFile,
    required List<List<List<double>>> polygons,
    required Size imageSize, // Add image size for normalization
  }) async {
    try {
      if (polygons.isEmpty) {
        throw Exception('Please mark polygons on the image to remove objects');
      }

      print('Sending ${polygons.length} polygons to API');
      print('Image size: $imageSize');
      
      // Try multiple formats to find what works
      File? result;
      
      // Try Format 1: Absolute coordinates (current)
      try {
        print('Trying Format 1: Absolute coordinates');
        result = await _sendRequestWithAbsoluteCoords(imageFile, polygons);
        if (result != null) {
          final fileSize = await result.length();
          print('Format 1 success - File size: $fileSize bytes');
          return result;
        }
      } catch (e) {
        print('Format 1 failed: $e');
      }
      
      // Try Format 2: Normalized coordinates (0-1 range)
      try {
        print('Trying Format 2: Normalized coordinates');
        result = await _sendRequestWithNormalizedCoords(imageFile, polygons, imageSize);
        if (result != null) {
          final fileSize = await result.length();
          print('Format 2 success - File size: $fileSize bytes');
          return result;
        }
      } catch (e) {
        print('Format 2 failed: $e');
      }
      
      // Try Format 3: Bounding box format
      try {
        print('Trying Format 3: Bounding box format');
        result = await _sendRequestWithBoundingBox(imageFile, polygons);
        if (result != null) {
          final fileSize = await result.length();
          print('Format 3 success - File size: $fileSize bytes');
          return result;
        }
      } catch (e) {
        print('Format 3 failed: $e');
      }
      
      throw Exception('All polygon formats failed. The API might not support polygon-based removal.');
      
    } catch (e) {
      print('API Error: $e');
      throw Exception('Error removing object: $e');
    }
  }

  // Format 1: Absolute coordinates (your current format)
  static Future<File?> _sendRequestWithAbsoluteCoords(File imageFile, List<List<List<double>>> polygons) async {
    var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    List<String> polygonStrings = [];
    for (var polygon in polygons) {
      List<String> pointStrings = [];
      for (var point in polygon) {
        if (point.length == 2) {
          pointStrings.add('${point[0].round()}');
          pointStrings.add('${point[1].round()}');
        }
      }
      polygonStrings.add(pointStrings.join(','));
    }
    
    final polygonsString = polygonStrings.join('|');
    print('Absolute coords: $polygonsString');
    request.fields['polygons'] = polygonsString;
    
    return await _sendAndProcessRequest(request);
  }

  // Format 2: Normalized coordinates (0-1 range)
  static Future<File?> _sendRequestWithNormalizedCoords(File imageFile, List<List<List<double>>> polygons, Size imageSize) async {
    var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    List<String> polygonStrings = [];
    for (var polygon in polygons) {
      List<String> pointStrings = [];
      for (var point in polygon) {
        if (point.length == 2) {
          // Normalize to 0-1 range
          double normalizedX = point[0] / imageSize.width;
          double normalizedY = point[1] / imageSize.height;
          pointStrings.add(normalizedX.toStringAsFixed(6));
          pointStrings.add(normalizedY.toStringAsFixed(6));
        }
      }
      polygonStrings.add(pointStrings.join(','));
    }
    
    final polygonsString = polygonStrings.join('|');
    print('Normalized coords: $polygonsString');
    request.fields['polygons'] = polygonsString;
    
    return await _sendAndProcessRequest(request);
  }

  // Format 3: Bounding box format [x1,y1,x2,y2]
  static Future<File?> _sendRequestWithBoundingBox(File imageFile, List<List<List<double>>> polygons) async {
    var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
    
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    
    List<String> bboxStrings = [];
    for (var polygon in polygons) {
      // Calculate bounding box from polygon
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;
      
      for (var point in polygon) {
        if (point.length == 2) {
          minX = point[0] < minX ? point[0] : minX;
          minY = point[1] < minY ? point[1] : minY;
          maxX = point[0] > maxX ? point[0] : maxX;
          maxY = point[1] > maxY ? point[1] : maxY;
        }
      }
      
      bboxStrings.add('${minX.round()},${minY.round()},${maxX.round()},${maxY.round()}');
    }
    
    final bboxString = bboxStrings.join('|');
    print('Bounding boxes: $bboxString');
    request.fields['polygons'] = bboxString; // Some APIs use same field for bbox
    
    return await _sendAndProcessRequest(request);
  }

  static Future<File?> _sendAndProcessRequest(http.MultipartRequest request) async {
    print('Sending request to API...');
    print('Request fields: ${request.fields}');
    
    try {
      final response = await request.send().timeout(Duration(seconds: 60));
      
      print('API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        print('Received ${bytes.length} bytes of image data');
        
        if (bytes.length < 100) {
          final responseString = String.fromCharCodes(bytes);
          print('Small response received: $responseString');
          throw Exception('Server returned error: $responseString');
        }
        
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/removed_object_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(bytes);
        
        if (await tempFile.exists()) {
          final fileLength = await tempFile.length();
          print('Image saved successfully: ${tempFile.path} ($fileLength bytes)');
          
          // Check if file size suggests actual processing occurred
          if (fileLength < 1000) {
            print('Warning: Very small file size - processing may not have worked');
            return null;
          }
          
          return tempFile;
        } else {
          throw Exception('Failed to create output file');
        }
        
      } else {
        final responseBody = await response.stream.bytesToString();
        print('Error response body: $responseBody');
        
        String errorMessage = 'Server returned status code ${response.statusCode}';
        try {
          final errorData = json.decode(responseBody);
          errorMessage = errorData['error'] ?? errorData['message'] ?? responseBody;
        } catch (e) {
          errorMessage = responseBody.isNotEmpty ? responseBody : errorMessage;
        }
        
        throw Exception('Failed to remove object: $errorMessage');
      }
    } on http.ClientException catch (e) {
      print('HTTP Client Exception: $e');
      throw Exception('Network error: $e');
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      throw Exception('Network connection failed: $e');
    } on TimeoutException catch (e) {
      print('Timeout Exception: $e');
      throw Exception('Request timeout: $e');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // Debug method to check API requirements
  static Future<void> debugEndpoint() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      print('Endpoint response: ${response.statusCode}');
      print('Headers: ${response.headers}');
      if (response.body.length < 500) {
        print('Body: ${response.body}');
      }
    } catch (e) {
      print('Debug endpoint failed: $e');
    }
  }
}