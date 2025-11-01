import 'package:flutter/material.dart';
import 'package:pixelwipe/pages/object_removal/bounding_box_painter.dart';
import 'package:pixelwipe/pages/object_removal/object_removal_result.dart';
import 'package:pixelwipe/models/processed_image.dart';
import 'object_removal_setup_controller.dart';

class ObjectRemovalSetupView extends StatefulWidget {
  final ObjectRemovalSetupController controller;
  final VoidCallback onBack;
  final Function(ProcessedImage) onSaveToGallery;
  final VoidCallback onShowPaywall;
  final Function(String) onSaveImage;

  const ObjectRemovalSetupView({
    Key? key,
    required this.controller,
    required this.onBack,
    required this.onSaveToGallery,
    required this.onShowPaywall,
    required this.onSaveImage,
  }) : super(key: key);

  @override
  _ObjectRemovalSetupViewState createState() => _ObjectRemovalSetupViewState();
}

class _ObjectRemovalSetupViewState extends State<ObjectRemovalSetupView> {
  final GlobalKey _imageKey = GlobalKey();
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      await widget.controller.pickImage();
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToResultPage() async {
    if (!widget.controller.canNavigateToResultPage()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an image and mark polygons to remove'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.controller.originalImage == null) return;

    // Get raw polygons for API
    List<List<List<double>>> polygons = widget.controller.getRawPolygons();
    
    print('Navigating to result page with:');
    print('   - ${polygons.length} polygons');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObjectRemovalResultPage(
          originalImage: widget.controller.originalImage!,
          boundingBoxes: widget.controller.boundingBoxes,
          polygons: polygons,
          objectDescription: '', // Empty since we removed text description
          onSaveToGallery: widget.onSaveToGallery,
        ),
      ),
    );
    
    if (mounted && (result == true || result == null)) {
      widget.controller.clearAllBoundingBoxes();
      widget.controller.deselectBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: widget.onBack,
        icon: Icon(Icons.arrow_back, color: Colors.white),
      ),
      title: Text('Remove Objects'),
      centerTitle: true,
      backgroundColor: Color(0xFF7C3AED),
      foregroundColor: Colors.white,
      actions: [
        if (widget.controller.zoomLevel != 1.0)
          IconButton(
            icon: Icon(Icons.zoom_out_map),
            onPressed: () => widget.controller.resetZoom(),
            tooltip: 'Reset zoom',
          ),
        if (widget.controller.boundingBoxes.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: widget.controller.clearAllBoundingBoxes,
            tooltip: 'Clear all polygons',
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImageSelectionSection(),
          SizedBox(height: 20),
          if (widget.controller.originalImage != null) ...[
            _buildZoomControls(),
            SizedBox(height: 10),
            _buildPolygonControls(),
            SizedBox(height: 20),
          ],
          if (widget.controller.originalImage != null)
            _buildProcessButton(),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildImageSelectionSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildImageHeader(),
            SizedBox(height: 12),
            widget.controller.originalImage == null
                ? _buildImagePickerButton()
                : _buildImagePreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Row(
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
        if (widget.controller.originalImage != null)
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: widget.controller.removeImage,
            tooltip: 'Remove image',
          ),
      ],
    );
  }

  Widget _buildImagePickerButton() {
    return ElevatedButton(
      onPressed: _isPickingImage ? null : _pickImage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isPickingImage
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library),
                SizedBox(width: 8),
                Text('Choose Image'),
              ],
            ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          constraints: BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.black12,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GestureDetector(
              onTapDown: (details) {
                _handleImageTap(details.globalPosition);
              },
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: Stack(
                key: _imageKey,
                children: [
                  Transform(
                    transform: Matrix4.identity()
                      ..translate(
                        widget.controller.panOffset.dx,
                        widget.controller.panOffset.dy,
                      )
                      ..scale(widget.controller.zoomLevel),
                    child: Image.file(
                      widget.controller.originalImage!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _updateImageSize();
                        });
                        return child;
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.red, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  Positioned.fill(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..translate(
                          widget.controller.panOffset.dx,
                          widget.controller.panOffset.dy,
                        )
                        ..scale(widget.controller.zoomLevel),
                      child: CustomPaint(
                        painter: BoundingBoxPainter(
                          points: widget.controller.currentPoints,
                          boxes: widget.controller.boundingBoxes,
                          isDrawing: widget.controller.isDrawing,
                          imageSize: widget.controller.imageSize ?? Size.zero,
                          isPolygonMode: true, // Always polygon mode now
                          selectedBox: widget.controller.selectedBox,
                          zoomLevel: widget.controller.zoomLevel,
                        ),
                      ),
                    ),
                  ),
                  
                  if (widget.controller.zoomLevel != 1.0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Zoom: ${(widget.controller.zoomLevel * 100).round()}%',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 12),
        _buildImageControls(),
      ],
    );
  }

  void _updateImageSize() {
    // Only update if we don't already have the image size
    if (widget.controller.imageSize == null) {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        if (size.height > 0 && size.width > 0) {
          print('Image size detected: $size');
          widget.controller.setImageSize(size);
        } else {
          print('Invalid image size: $size');
        }
      } else {
        print('RenderBox not available');
      }
    }
  }

  Widget _buildImageControls() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isPickingImage ? null : _pickImage,
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF7C3AED),
              side: BorderSide(color: Color(0xFF7C3AED)),
            ),
            child: _isPickingImage
                ? SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  )
                : Text('Change Image'),
          ),
        ),
        SizedBox(width: 8),
        if (widget.controller.selectedBox != null)
          Expanded(
            child: ElevatedButton(
              onPressed: () => widget.controller.removeSelectedBox(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Remove Selected'),
            ),
          ),
      ],
    );
  }

  // ... Rest of the methods remain the same (zoom controls, polygon controls, etc.)
  // [Include all the other methods from your previous ObjectRemovalSetupView here]
  // They remain unchanged, just make sure to include them in the class

  Widget _buildZoomControls() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Zoom: ${(widget.controller.zoomLevel * 100).round()}%',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.zoom_out),
                  onPressed: () {
                    widget.controller.updateZoom(widget.controller.zoomLevel - 0.1);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.zoom_in),
                  onPressed: () {
                    widget.controller.updateZoom(widget.controller.zoomLevel + 0.1);
                  },
                ),
                if (widget.controller.zoomLevel != 1.0)
                  TextButton(
                    onPressed: () => widget.controller.resetZoom(),
                    child: Text('Reset'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolygonControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mark Polygons to Remove',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C1D95),
              ),
            ),
            SizedBox(height: 12),
            _buildDrawingControls(),
            if (widget.controller.isDrawing) _buildDrawingInstructions(),
            if (widget.controller.boundingBoxes.isNotEmpty) _buildPolygonsCounter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingControls() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (!widget.controller.isDrawing)
          ElevatedButton(
            onPressed: () {
              print('Add Polygon button pressed');
              widget.controller.startDrawing();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.polyline, size: 16),
                SizedBox(width: 6),
                Text('Add Polygon'),
              ],
            ),
          ),
        if (widget.controller.isDrawing)
          ElevatedButton(
            onPressed: () {
              print('Complete button pressed');
              widget.controller.completeBoundingBox();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, size: 16),
                SizedBox(width: 6),
                Text('Complete'),
              ],
            ),
          ),
        if (widget.controller.isDrawing && widget.controller.currentPoints.isNotEmpty)
          OutlinedButton(
            onPressed: () {
              print('Remove Last Point button pressed');
              if (widget.controller.currentPoints.isNotEmpty) {
                widget.controller.removeCurrentPoint(widget.controller.currentPoints.length - 1);
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: BorderSide(color: Colors.orange),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.undo, size: 16),
                SizedBox(width: 6),
                Text('Remove Last Point'),
              ],
            ),
          ),
        if (widget.controller.isDrawing)
          OutlinedButton(
            onPressed: () {
              print('Cancel button pressed');
              widget.controller.clearCurrentDrawing();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.clear, size: 16),
                SizedBox(width: 6),
                Text('Cancel'),
              ],
            ),
          ),
        if (widget.controller.boundingBoxes.isNotEmpty)
          OutlinedButton(
            onPressed: () {
              print('Remove Last Polygon button pressed');
              widget.controller.removeLastBoundingBox();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: BorderSide(color: Colors.orange),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.undo, size: 16),
                SizedBox(width: 6),
                Text('Remove Last Polygon'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDrawingInstructions() {
    return Column(
      children: [
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
                'Tap to add polygon points (min 3 points)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Points added: ${widget.controller.currentPoints.length}',
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
    );
  }

  Widget _buildPolygonsCounter() {
    return Column(
      children: [
        SizedBox(height: 12),
        Text(
          '${widget.controller.boundingBoxes.length} polygon(s) defined',
          style: TextStyle(
            color: Colors.green[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessButton() {
    return ElevatedButton(
      onPressed: _navigateToResultPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'Remove Objects',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _handleImageTap(Offset globalPosition) {
    if (widget.controller.originalImage == null) {
      print('No image selected');
      return;
    }
    
    final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(globalPosition);
      print('Tap detected:');
      print('   Global: $globalPosition');
      print('   Local: $localPosition');
      print('   Is drawing: ${widget.controller.isDrawing}');
      print('   Image size: ${widget.controller.imageSize}');
      
      widget.controller.handleTap(localPosition);
    } else {
      print('RenderBox is null');
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (widget.controller.originalImage == null) return;
    
    final renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.localFocalPoint);
      widget.controller.startPan(localPosition);
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (widget.controller.originalImage == null) return;
    
    if (details.scale != 1.0) {
      final newZoom = widget.controller.zoomLevel * details.scale;
      widget.controller.updateZoom(newZoom);
    } else {
      final renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
      if (renderBox != null) {
        final localPosition = renderBox.globalToLocal(details.localFocalPoint);
        widget.controller.updatePan(localPosition);
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    widget.controller.stopPan();
  }
}