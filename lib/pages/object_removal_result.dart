import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; // Updated import
import 'package:permission_handler/permission_handler.dart';
import 'package:pixelwipe/models/rectangle.dart';
import 'package:pixelwipe/services/object_removal_service.dart';
import '../services/object_removal_service.dart' as removal_service;
import '../models/bounding_rectangle.dart';

class ObjectRemovalResultPage extends StatefulWidget {
  final File originalImage;
  final List<BoundingRectangle> boundingBoxes;
  final String objectDescription;

  const ObjectRemovalResultPage({
    Key? key,
    required this.originalImage,
    required this.boundingBoxes,
    required this.objectDescription,
  }) : super(key: key);

  @override
  _ObjectRemovalResultPageState createState() => _ObjectRemovalResultPageState();
}

class _ObjectRemovalResultPageState extends State<ObjectRemovalResultPage> {
  File? _processedImage;
  bool _isProcessing = true;
  bool _hasError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      // Convert BoundingRectangle to Rectangle
      List<Rectangle>? convertedBoxes;
      if (widget.boundingBoxes.isNotEmpty) {
        convertedBoxes = widget.boundingBoxes.map((bbox) => 
          Rectangle(bbox.x1 as int, bbox.y1 as int, bbox.x2 as int, bbox.y2 as int)
        ).toList();
      }

      final result = await removal_service.ObjectRemovalService.removeObject(
        imageFile: widget.originalImage,
        boundingBoxes: convertedBoxes,
        objectDescription: widget.objectDescription.isNotEmpty ? 
            widget.objectDescription : null,
      );

      setState(() {
        _processedImage = result;
        _isProcessing = false;
      });

    } catch (e) {
      print('Error processing image: $e');
      setState(() {
        _isProcessing = false;
        _hasError = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing image: $e')),
      );
    }
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        // Read the image file as bytes
        final bytes = await _processedImage!.readAsBytes();
        
        // Save to gallery using the updated package
        final result = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(bytes),
          quality: 100,
          name: 'pixelwipe_${DateTime.now().millisecondsSinceEpoch}',
        );

        setState(() {
          _isSaving = false;
        });

        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to gallery successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save image to gallery'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareImage() {
    if (_processedImage != null) {
      // TODO: Implement share functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share functionality coming soon!')),
      );
    }
  }

  void _processNewImage() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Results'),
        backgroundColor: Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          if (!_isProcessing && _processedImage != null)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: _shareImage,
              tooltip: 'Share image',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Original Image
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                    SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.originalImage,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Processed Image
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Processed Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                        SizedBox(width: 8),
                        if (_isProcessing)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Processing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (_hasError)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Error',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (!_isProcessing && !_hasError && _processedImage != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Completed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 12),

                    if (_isProcessing)
                      Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Removing objects...',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_hasError)
                      Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text(
                                'Failed to process image',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _processImage,
                                child: Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_processedImage != null)
                      Column(
                        children: [
                          Container(
                            constraints: BoxConstraints(maxHeight: 300),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _processedImage!,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveImage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: _isSaving
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.download, size: 20),
                                            SizedBox(width: 8),
                                            Text('Save Image'),
                                          ],
                                        ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _shareImage,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Color(0xFF7C3AED),
                                    side: BorderSide(color: Color(0xFF7C3AED)),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.share, size: 20),
                                      SizedBox(width: 8),
                                      Text('Share'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No processed image available',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFF7C3AED),
                      side: BorderSide(color: Color(0xFF7C3AED)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Back to Editor'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processNewImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('New Image'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}