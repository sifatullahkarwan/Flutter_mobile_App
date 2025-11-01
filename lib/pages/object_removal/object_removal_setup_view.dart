import 'package:flutter/material.dart';
import 'package:pixelwipe/pages/object_removal/bounding_box_painter.dart';
import 'object_removal_setup_controller.dart';
import 'bounding_box_painter.dart';

class ObjectRemovalSetupView extends StatefulWidget {
  final ObjectRemovalSetupController controller;
  final VoidCallback onBack;
  final Function(String) onSaveImage;
  final VoidCallback onShowPaywall;

  const ObjectRemovalSetupView({
    Key? key,
    required this.controller,
    required this.onBack,
    required this.onSaveImage,
    required this.onShowPaywall,
  }) : super(key: key);

  @override
  _ObjectRemovalSetupViewState createState() => _ObjectRemovalSetupViewState();
}

class _ObjectRemovalSetupViewState extends State<ObjectRemovalSetupView> {
  final GlobalKey _imageKey = GlobalKey();

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
        if (widget.controller.boundingBoxes.isNotEmpty)
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: widget.controller.clearAllBoundingBoxes,
            tooltip: 'Clear all boxes',
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
            _buildBoundingBoxControls(),
            SizedBox(height: 20),
          ],
          _buildObjectDescriptionInput(),
          SizedBox(height: 20),
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
      onPressed: widget.controller.pickImage,
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
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              key: _imageKey,
              children: [
                Image.file(
                  widget.controller.originalImage!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (details) {
                      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
                      if (renderBox != null) {
                        final localPosition = renderBox.globalToLocal(details.globalPosition);
                        widget.controller.addPoint(localPosition);
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      child: CustomPaint(
                        painter: BoundingBoxPainter(
                          points: widget.controller.currentPoints,
                          boxes: widget.controller.boundingBoxes,
                          isDrawing: widget.controller.isDrawing,
                          imageSize: widget.controller.imageSize,
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
          onPressed: widget.controller.pickImage,
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF7C3AED),
            side: BorderSide(color: Color(0xFF7C3AED)),
          ),
          child: Text('Change Image'),
        ),
      ],
    );
  }

  Widget _buildBoundingBoxControls() {
    return Card(
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
            _buildDrawingControls(),
            if (widget.controller.isDrawing) _buildDrawingInstructions(),
            if (widget.controller.boundingBoxes.isNotEmpty) _buildBoundingBoxesCounter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!widget.controller.isDrawing)
          ElevatedButton(
            onPressed: widget.controller.startDrawing,
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
        if (widget.controller.isDrawing)
          ElevatedButton(
            onPressed: widget.controller.completeBoundingBox,
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
        if (widget.controller.isDrawing)
          OutlinedButton(
            onPressed: widget.controller.clearCurrentDrawing,
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
        if (widget.controller.boundingBoxes.isNotEmpty)
          OutlinedButton(
            onPressed: widget.controller.removeLastBoundingBox,
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
                'Points added: ${widget.controller.currentPoints.length}/4',
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

  Widget _buildBoundingBoxesCounter() {
    return Column(
      children: [
        SizedBox(height: 12),
        Text(
          '${widget.controller.boundingBoxes.length} bounding box(es) defined',
          style: TextStyle(
            color: Colors.green[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildObjectDescriptionInput() {
    return Card(
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
              controller: widget.controller.descriptionController,
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
    );
  }

  Widget _buildProcessButton() {
    return ElevatedButton(
      onPressed: () {
        if (widget.controller.canNavigateToResultPage()) {
          // Navigate to result page
        }
      },
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
    );
  }
}