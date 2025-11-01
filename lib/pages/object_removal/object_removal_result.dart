import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixelwipe/models/bounding_rectangle.dart';
import 'package:pixelwipe/models/processed_image.dart';
import 'package:pixelwipe/services/object_removal_service.dart';

class ObjectRemovalResultPage extends StatefulWidget {
  final File originalImage;
  final List<BoundingRectangle> boundingBoxes;
  final List<List<List<double>>> polygons;
  final String objectDescription;
  final Function(ProcessedImage) onSaveToGallery;

  const ObjectRemovalResultPage({
    Key? key,
    required this.originalImage,
    required this.boundingBoxes,
    required this.polygons,
    required this.objectDescription,
    required this.onSaveToGallery,
  }) : super(key: key);

  @override
  _ObjectRemovalResultPageState createState() => _ObjectRemovalResultPageState();
}

class _ObjectRemovalResultPageState extends State<ObjectRemovalResultPage> {
  File? _processedImage;
  bool _isProcessing = true;
  bool _hasError = false;
  bool _isSaving = false;
  String _processingStatus = 'Starting object removal...';
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processImage();
    });
  }

  // Helper method to get image dimensions
// Helper method to get image dimensions properly
Future<Size> _getImageSize(File file) async {
  final completer = Completer<Size>();
  final bytes = await file.readAsBytes();
  
  Image.memory(
    bytes,
  ).image.resolve(ImageConfiguration()).addListener(
    ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(Size(
        info.image.width.toDouble(),
        info.image.height.toDouble()
      ));
    }),
  );
  
  return completer.future;
}

Future<void> _processImage() async {
  try {

    // Get image dimensions properly
    setState(() {
      _processingStatus = 'Reading image dimensions...';
    });

    final imageSize = await _getImageSize(widget.originalImage);
    _imageSize = imageSize;
    

    // Validate image size
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      throw Exception('Invalid image dimensions: ${imageSize.width}x${imageSize.height}');
    }

    // Log polygon details for debugging
    for (int i = 0; i < widget.polygons.length; i++) {
      for (int j = 0; j < widget.polygons[i].length; j++) {
      }
    }

    setState(() {
      _processingStatus = 'Processing polygons...';
    });

    final result = await ObjectRemovalService.removeObject(
      imageFile: widget.originalImage,
      polygons: widget.polygons,
      imageSize: imageSize,
    );

    if (result == null) {
      throw Exception('API returned unmodified image. Check polygon format.');
    }

    
    setState(() {
      _processedImage = result;
      _isProcessing = false;
      _processingStatus = 'Processing complete!';
    });

  } catch (e) {
    
    setState(() {
      _isProcessing = false;
      _hasError = true;
      _processingStatus = 'Error: ${e.toString()}';
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
}
  Future<void> _retryProcessing() async {
    setState(() {
      _isProcessing = true;
      _hasError = false;
      _processedImage = null;
      _processingStatus = 'Retrying object removal...';
    });
    
    await _processImage();
  }

  Future<void> _saveImage() async {
    if (_processedImage == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      final bytes = await _processedImage!.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageName = 'pixelwipe_$timestamp';
      
      final base64Image = base64Encode(bytes);
      final imageData = 'data:image/jpeg;base64,$base64Image';
      
      final processedImage = ProcessedImage(
        id: timestamp.toString(),
        data: imageData,
        timestamp: timestamp,
        name: imageName,
      );
      
      widget.onSaveToGallery(processedImage);

      if (status.isGranted) {
        final deviceResult = await ImageGallerySaverPlus.saveImage(
          Uint8List.fromList(bytes),
          quality: 100,
          name: imageName,
        );

        setState(() {
          _isSaving = false;
        });

        if (deviceResult['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to gallery successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image saved to app gallery only'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to app gallery only'),
            backgroundColor: Colors.orange,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share functionality coming soon!')),
      );
    }
  }

  void _processNewImage() {
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Original Image Section - Fixed height
              Expanded(
                flex: 2,
                child: Card(
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
                        Expanded(
                          child: Container(
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
                        ),
                        SizedBox(height: 8),
                        if (_imageSize != null)
                          Text(
                            'Dimensions: ${_imageSize!.width.round()}x${_imageSize!.height.round()} | Polygons: ${widget.polygons.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          )
                        else
                          Text(
                            'Polygons defined: ${widget.polygons.length}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Processed Image Section - Fixed height
              Expanded(
                flex: 3,
                child: Card(
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
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _processingStatus,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),
                                  if (_imageSize != null)
                                    Text(
                                      'Image: ${_imageSize!.width.round()}x${_imageSize!.height.round()}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 14,
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Processing ${widget.polygons.length} polygon(s)',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Total points: ${_calculateTotalPoints()}',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_hasError)
                          Expanded(
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
                                  Text(
                                    _processingStatus,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _retryProcessing,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF7C3AED),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text('Try Again'),
                                      ),
                                      SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Color(0xFF7C3AED),
                                          side: BorderSide(color: Color(0xFF7C3AED)),
                                        ),
                                        child: Text('Back to Editor'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_processedImage != null)
                          Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Container(
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
                            ),
                          )
                        else
                          Expanded(
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
              ),
              SizedBox(height: 16),

              // Action Buttons - Fixed height at bottom
              Container(
                height: 60,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, true),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateTotalPoints() {
    int total = 0;
    for (var polygon in widget.polygons) {
      total += polygon.length;
    }
    return total;
  }
}