import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pixelwipe/models/bounding_rectangle.dart';

class ObjectRemovalSetupController extends ChangeNotifier {
  File? _originalImage;
  final List<Offset> _currentPoints = [];
  final List<BoundingRectangle> _boundingBoxes = [];
  bool _isDrawing = false;
  final TextEditingController descriptionController = TextEditingController();
  Size? _imageSize;
  BoundingRectangle? _selectedBox;
  double _zoomLevel = 1.0;
  Offset _panOffset = Offset.zero;
  bool _isPanning = false;
  Offset _lastPanPoint = Offset.zero;
  bool _isResizing = false;
  int? _selectedHandleIndex;

  File? get originalImage => _originalImage;
  List<Offset> get currentPoints => _currentPoints;
  List<BoundingRectangle> get boundingBoxes => _boundingBoxes;
  bool get isDrawing => _isDrawing;
  Size? get imageSize => _imageSize;
  BoundingRectangle? get selectedBox => _selectedBox;
  double get zoomLevel => _zoomLevel;
  Offset get panOffset => _panOffset;
  bool get isPanning => _isPanning;

  final ImagePicker _imagePicker = ImagePicker();

  void setImageSize(Size size) {
    // Only update if the size has actually changed
    if (_imageSize == null || _imageSize!.width != size.width || _imageSize!.height != size.height) {
      _imageSize = size;
      print('Image size set to: $size');
      notifyListeners();
    }
  }

  // Get raw polygons for API
  List<List<List<double>>> getRawPolygons() {
    List<List<List<double>>> polygons = [];
    
    for (final box in _boundingBoxes) {
      // All shapes are polygons now
      final polygon = box.polygonPoints.map((point) => 
        [point.dx, point.dy]
      ).toList();
      polygons.add(polygon);
      print('Polygon with ${polygon.length} points');
    }
    
    print('Total polygons: ${polygons.length}');
    return polygons;
  }

  bool canNavigateToResultPage() {
    return _originalImage != null && _boundingBoxes.isNotEmpty;
  }

  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _originalImage = File(pickedFile.path);
        _resetDrawingState();
        notifyListeners();
      }
    } catch (e) {
      print('Error picking image: $e');
      rethrow;
    }
  }

  void removeImage() {
    _originalImage = null;
    _resetDrawingState();
    notifyListeners();
  }

  void _resetDrawingState() {
    _currentPoints.clear();
    _boundingBoxes.clear();
    _isDrawing = false;
    _imageSize = null;
    _selectedBox = null;
    descriptionController.clear();
    _zoomLevel = 1.0;
    _panOffset = Offset.zero;
    _isPanning = false;
    _isResizing = false;
    _selectedHandleIndex = null;
  }

  void updateZoom(double newZoomLevel) {
    _zoomLevel = newZoomLevel.clamp(0.1, 5.0);
    notifyListeners();
  }

  void resetZoom() {
    _zoomLevel = 1.0;
    _panOffset = Offset.zero;
    notifyListeners();
  }

  void startPan(Offset localPosition) {
    _isPanning = true;
    _lastPanPoint = localPosition;
    notifyListeners();
  }

  void updatePan(Offset localPosition) {
    if (!_isPanning) return;
    
    final delta = localPosition - _lastPanPoint;
    _panOffset += delta;
    _lastPanPoint = localPosition;
    notifyListeners();
  }

  void stopPan() {
    _isPanning = false;
    notifyListeners();
  }

  // Drawing methods - Only polygon mode
  void startDrawing() {
    if (_originalImage == null) return;
    _isDrawing = true;
    _currentPoints.clear();
    _selectedBox = null;
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (!_isDrawing) return;
    
    final adjustedPoint = _adjustPointForZoomAndPan(point);
    
    print('Adding point: $adjustedPoint');
    
    _currentPoints.add(adjustedPoint);
    notifyListeners();
  }

  void removeCurrentPoint(int index) {
    if (index >= 0 && index < _currentPoints.length) {
      _currentPoints.removeAt(index);
      notifyListeners();
    }
  }

  void completeBoundingBox() {
    if (_currentPoints.length >= 3) {
      try {
        final bbox = BoundingRectangle.fromPolygon(_currentPoints);
        _boundingBoxes.add(bbox);
        print('Added polygon: $bbox');
      } catch (e) {
        print('Error creating polygon: $e');
      }
    }
    
    _currentPoints.clear();
    _isDrawing = false;
    notifyListeners();
  }

  void clearCurrentDrawing() {
    _currentPoints.clear();
    _isDrawing = false;
    notifyListeners();
  }

  // Selection and interaction methods
  void handleTap(Offset localPosition) {
    final adjustedPoint = _adjustPointForZoomAndPan(localPosition);
    
    print('Tap at: $localPosition, adjusted: $adjustedPoint');
    
    // Check if tap is on a remove button for current drawing points
    if (_isDrawing) {
      for (int i = 0; i < _currentPoints.length; i++) {
        final point = _applyZoomAndPan(_currentPoints[i]);
        final distance = (localPosition - point).distance;
        print('Checking drawing point $i: $point, distance: $distance');
        if (distance < 20) {
          print('Removing drawing point $i');
          removeCurrentPoint(i);
          return;
        }
      }
    }
    
    // Check if tap is on a remove button for selected polygon points
    if (_selectedBox != null) {
      for (int i = 0; i < _selectedBox!.polygonPoints.length; i++) {
        final point = _applyZoomAndPan(_selectedBox!.polygonPoints[i]);
        final distance = (localPosition - point).distance;
        print('Checking polygon point $i: $point, distance: $distance');
        if (distance < 20) {
          print('Removing polygon point $i');
          removePointFromSelectedBox(i);
          return;
        }
      }
    }
    
    // Check if tap is on an existing polygon to select it
    BoundingRectangle? tappedBox;
    for (final box in _boundingBoxes.reversed) {
      if (_isPointInBox(adjustedPoint, box)) {
        tappedBox = box;
        break;
      }
    }
    
    if (tappedBox != null) {
      print('Selected polygon: $tappedBox');
      selectBox(tappedBox);
      return;
    }
    
    // If drawing is active, add point
    if (_isDrawing) {
      print('Adding new point while drawing');
      addPoint(localPosition);
    } else {
      // Deselect if tapping elsewhere
      print('Deselecting polygon');
      deselectBox();
    }
  }

  void handleDragStart(Offset localPosition) {
    if (_selectedBox != null) {
      // Start moving the selected polygon
      _isPanning = true;
      _lastPanPoint = localPosition;
    } else {
      // Start panning the canvas
      startPan(localPosition);
    }
  }

  void handleDragUpdate(Offset localPosition) {
    if (_isPanning && _selectedBox != null) {
      // Move the selected polygon
      final delta = (localPosition - _lastPanPoint) / _zoomLevel;
      _selectedBox!.move(delta);
      _lastPanPoint = localPosition;
      notifyListeners();
    } else if (_isPanning) {
      // Pan the canvas
      updatePan(localPosition);
    }
  }

  void handleDragEnd() {
    stopPan();
  }

  // Helper methods
  Offset _adjustPointForZoomAndPan(Offset point) {
    return Offset(
      (point.dx - _panOffset.dx) / _zoomLevel,
      (point.dy - _panOffset.dy) / _zoomLevel,
    );
  }

  Offset _applyZoomAndPan(Offset point) {
    return Offset(
      point.dx * _zoomLevel + _panOffset.dx,
      point.dy * _zoomLevel + _panOffset.dy,
    );
  }

  bool _isPointInBox(Offset point, BoundingRectangle box) {
    return _isPointInPolygon(point, box.polygonPoints);
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

  // Selection methods
  void selectBox(BoundingRectangle box) {
    _selectedBox = box;
    _isDrawing = false;
    notifyListeners();
  }

  void deselectBox() {
    _selectedBox = null;
    _isResizing = false;
    _selectedHandleIndex = null;
    notifyListeners();
  }

  void removePointFromSelectedBox(int index) {
    if (_selectedBox != null) {
      _selectedBox!.removePolygonPoint(index);
      // If polygon becomes invalid after removal, remove the entire polygon
      if (_selectedBox!.polygonPoints.length < 3) {
        removeSelectedBox();
      } else {
        notifyListeners();
      }
    }
  }

  // Removal methods
  void removeSelectedBox() {
    if (_selectedBox != null) {
      _boundingBoxes.remove(_selectedBox);
      _selectedBox = null;
      _isResizing = false;
      _selectedHandleIndex = null;
      notifyListeners();
    }
  }

  void removeLastBoundingBox() {
    if (_boundingBoxes.isNotEmpty) {
      if (_selectedBox == _boundingBoxes.last) {
        _selectedBox = null;
      }
      _boundingBoxes.removeLast();
      notifyListeners();
    }
  }

  void clearAllBoundingBoxes() {
    _boundingBoxes.clear();
    _selectedBox = null;
    _currentPoints.clear();
    _isDrawing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }
}