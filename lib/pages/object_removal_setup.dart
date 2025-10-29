import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelwipe/models/rectangle.dart';
import 'package:pixelwipe/pages/object_removal_result.dart';
import '../models/bounding_rectangle.dart';
import 'object_removal_result_page.dart';

class ObjectRemovalSetupPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onSaveImage;
  final VoidCallback onShowPaywall;

  const ObjectRemovalSetupPage({
    Key? key,
    required this.onBack,
    required this.onSaveImage,
    required this.onShowPaywall,
  }) : super(key: key);

  @override
  _ObjectRemovalSetupPageState createState() => _ObjectRemovalSetupPageState();
}

class _ObjectRemovalSetupPageState extends State<ObjectRemovalSetupPage> {
  File? _originalImage;
  final TextEditingController _descriptionController = TextEditingController();
  final List<BoundingRectangle> _boundingBoxes = [];
  final List<Offset> _currentPoints = [];
  bool _isDrawing = false;
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageSize;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _originalImage = File(pickedFile.path);
        _boundingBoxes.clear();
        _currentPoints.clear();
        _isDrawing = false;
        _imageSize = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getImageSize();
      });
    }
  }

  void _getImageSize() {
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      setState(() {
        _imageSize = renderBox.size;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _originalImage = null;
      _boundingBoxes.clear();
      _currentPoints.clear();
      _isDrawing = false;
      _descriptionController.clear();
      _imageSize = null;
    });
  }

  void _startDrawing() {
    if (_originalImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    
    setState(() {
      _isDrawing = true;
      _currentPoints.clear();
    });
  }

  void _addPoint(Offset localPosition) {
    if (!_isDrawing) return;

    setState(() {
      _currentPoints.add(localPosition);
    });

    // If we have 4 points, automatically complete the bounding box
    if (_currentPoints.length >= 4) {
      _completeBoundingBox();
    }
  }

  void _completeBoundingBox() {
    if (_currentPoints.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Need 4 points to create a bounding box')),
      );
      return;
    }

    if (_imageSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image not loaded yet, please try again')),
      );
      return;
    }

    // Convert points to normalized rectangle coordinates (0.0 to 1.0)
    final xValues = _currentPoints.map((p) => p.dx).toList();
    final yValues = _currentPoints.map((p) => p.dy).toList();
    
    // Get absolute coordinates
    final absX1 = xValues.reduce((a, b) => a < b ? a : b);
    final absY1 = yValues.reduce((a, b) => a < b ? a : b);
    final absX2 = xValues.reduce((a, b) => a > b ? a : b);
    final absY2 = yValues.reduce((a, b) => a > b ? a : b);

    // Convert to normalized coordinates (0.0 to 1.0)
    final normX1 = absX1 / _imageSize!.width;
    final normY1 = absY1 / _imageSize!.height;
    final normX2 = absX2 / _imageSize!.width;
    final normY2 = absY2 / _imageSize!.height;

    // Ensure coordinates are within [0,1] range
    final clampedX1 = normX1.clamp(0.0, 1.0);
    final clampedY1 = normY1.clamp(0.0, 1.0);
    final clampedX2 = normX2.clamp(0.0, 1.0);
    final clampedY2 = normY2.clamp(0.0, 1.0);

    // Create rectangle with normalized coordinates
    final rectangle = BoundingRectangle.fromNormalized(
      clampedX1, clampedY1, clampedX2, clampedY2
    );
    
    setState(() {
      _boundingBoxes.add(rectangle);
      _isDrawing = false;
      _currentPoints.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bounding box ${_boundingBoxes.length} added!')),
    );
  }

  void _clearCurrentDrawing() {
    setState(() {
      _isDrawing = false;
      _currentPoints.clear();
    });
  }

  void _removeLastBoundingBox() {
    if (_boundingBoxes.isNotEmpty) {
      setState(() {
        _boundingBoxes.removeLast();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Last bounding box removed')),
      );
    }
  }

  void _clearAllBoundingBoxes() {
    setState(() {
      _boundingBoxes.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All bounding boxes cleared')),
    );
  }

  void _navigateToResultPage() {
    if (_originalImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (_boundingBoxes.isEmpty && _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide either bounding boxes or object description')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObjectRemovalResultPage(
          originalImage: _originalImage!,
          boundingBoxes: _boundingBoxes,
          objectDescription: _descriptionController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text('Remove Objects'),
        centerTitle: true,
        backgroundColor: Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        actions: [
          if (_boundingBoxes.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_all),
              onPressed: _clearAllBoundingBoxes,
              tooltip: 'Clear all boxes',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Image',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                        if (_originalImage != null)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: _removeImage,
                            tooltip: 'Remove image',
                          ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (_originalImage == null)
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library),
                            SizedBox(width: 8),
                            Text('Choose Image'),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            constraints: BoxConstraints(maxHeight: 400), // Larger for better point selection
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                key: _imageKey,
                                children: [
                                  Image.file(
                                    _originalImage!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTapDown: (details) {
                                        final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                                        if (renderBox != null) {
                                          final localPosition = renderBox.globalToLocal(details.globalPosition);
                                          _addPoint(localPosition);
                                        }
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        child: CustomPaint(
                                          painter: _BoundingBoxPainter(
                                            points: _currentPoints,
                                            boxes: _boundingBoxes,
                                            isDrawing: _isDrawing,
                                            imageSize: _imageSize,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: _pickImage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF7C3AED),
                              side: BorderSide(color: Color(0xFF7C3AED)),
                            ),
                            child: Text('Change Image'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Bounding Box Controls
            if (_originalImage != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mark Objects to Remove',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Drawing Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (!_isDrawing)
                            ElevatedButton(
                              onPressed: _startDrawing,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.crop_square, size: 16),
                                  SizedBox(width: 6),
                                  Text('Add Box'),
                                ],
                              ),
                            ),
                          
                          if (_isDrawing)
                            ElevatedButton(
                              onPressed: _completeBoundingBox,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF10B981),
                                foregroundColor: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check, size: 16),
                                  SizedBox(width: 6),
                                  Text('Complete'),
                                ],
                              ),
                            ),
                          
                          if (_isDrawing)
                            OutlinedButton(
                              onPressed: _clearCurrentDrawing,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.clear, size: 16),
                                  SizedBox(width: 6),
                                  Text('Cancel'),
                                ],
                              ),
                            ),
                          
                          if (_boundingBoxes.isNotEmpty)
                            OutlinedButton(
                              onPressed: _removeLastBoundingBox,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: BorderSide(color: Colors.orange),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.undo, size: 16),
                                  SizedBox(width: 6),
                                  Text('Remove Last'),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      // Drawing Instructions
                      if (_isDrawing) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Tap on the image to add 4 points around the object',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blue[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Points added: ${_currentPoints.length}/4',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Bounding Boxes Counter
                      if (_boundingBoxes.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Text(
                          '${_boundingBoxes.length} bounding box(es) defined',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],

            // Object Description Input
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Object Description (Optional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4C1D95),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Describe what you want to remove from the image',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Remove person on the left, delete text, erase watermark...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF7C3AED)),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                      style: TextStyle(fontSize: 15),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Leave empty if using bounding boxes only',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Process Button
            if (_originalImage != null)
              ElevatedButton(
                onPressed: _navigateToResultPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Remove Objects',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Custom painter for drawing bounding boxes and points
class _BoundingBoxPainter extends CustomPainter {
  final List<Offset> points;
  final List<BoundingRectangle> boxes;
  final bool isDrawing;
  final Size? imageSize;

  _BoundingBoxPainter({
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

        final rect = Rect.fromLTRB(
          absX1,
          absY1,
          absX2,
          absY2,
        );
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
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return points != oldDelegate.points || 
           boxes != oldDelegate.boxes || 
           isDrawing != oldDelegate.isDrawing ||
           imageSize != oldDelegate.imageSize;
  }
}