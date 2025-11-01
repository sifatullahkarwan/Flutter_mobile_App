import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/bounding_rectangle.dart';

class ObjectRemovalSetupController {
  File? _originalImage;
  final TextEditingController _descriptionController = TextEditingController();
  final List<BoundingRectangle> _boundingBoxes = [];
  final List<Offset> _currentPoints = [];
  bool _isDrawing = false;
  Size? _imageSize;
  BuildContext? _context;

  // Getters
  File? get originalImage => _originalImage;
  TextEditingController get descriptionController => _descriptionController;
  List<BoundingRectangle> get boundingBoxes => _boundingBoxes;
  List<Offset> get currentPoints => _currentPoints;
  bool get isDrawing => _isDrawing;
  Size? get imageSize => _imageSize;

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      _originalImage = File(pickedFile.path);
      _boundingBoxes.clear();
      _currentPoints.clear();
      _isDrawing = false;
      _imageSize = null;
      notifyListeners();
    }
  }

  void removeImage() {
    _originalImage = null;
    _boundingBoxes.clear();
    _currentPoints.clear();
    _isDrawing = false;
    _descriptionController.clear();
    _imageSize = null;
    notifyListeners();
  }

  void setImageSize(Size size) {
    _imageSize = size;
    notifyListeners();
  }

  void startDrawing() {
    if (_originalImage == null) {
      _showSnackBar('Please select an image first');
      return;
    }
    
    _isDrawing = true;
    _currentPoints.clear();
    notifyListeners();
  }

  void addPoint(Offset localPosition) {
    if (!_isDrawing) return;

    _currentPoints.add(localPosition);
    notifyListeners();

    // If we have 4 points, automatically complete the bounding box
    if (_currentPoints.length >= 4) {
      completeBoundingBox();
    }
  }

  void completeBoundingBox() {
    if (_currentPoints.length < 4) {
      _showSnackBar('Need 4 points to create a bounding box');
      return;
    }

    if (_imageSize == null) {
      _showSnackBar('Image not loaded yet, please try again');
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

    final rectangle = BoundingRectangle.fromNormalized(
      clampedX1, clampedY1, clampedX2, clampedY2
    );
    
    _boundingBoxes.add(rectangle);
    _isDrawing = false;
    _currentPoints.clear();
    notifyListeners();

    _showSnackBar('Bounding box ${_boundingBoxes.length} added!');
  }

  void clearCurrentDrawing() {
    _isDrawing = false;
    _currentPoints.clear();
    notifyListeners();
  }

  void removeLastBoundingBox() {
    if (_boundingBoxes.isNotEmpty) {
      _boundingBoxes.removeLast();
      notifyListeners();
      _showSnackBar('Last bounding box removed');
    }
  }

  void clearAllBoundingBoxes() {
    _boundingBoxes.clear();
    notifyListeners();
    _showSnackBar('All bounding boxes cleared');
  }

  bool canNavigateToResultPage() {
    if (_originalImage == null) {
      _showSnackBar('Please select an image first');
      return false;
    }

    if (_boundingBoxes.isEmpty && _descriptionController.text.isEmpty) {
      _showSnackBar('Please provide either bounding boxes or object description');
      return false;
    }

    return true;
  }

  void _showSnackBar(String message) {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void notifyListeners() {
    // This would typically be part of a ChangeNotifier
    // For now, we'll rely on the view to rebuild when state changes
  }
}