import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/revenue_cat_service.dart';

class EditorPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onSaveImage;
  final VoidCallback onShowPaywall;

  const EditorPage({
    Key? key, 
    required this.onBack, 
    required this.onSaveImage,
    required this.onShowPaywall,
  }) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final RevenueCatService _revenueCat = RevenueCatService();
  bool _isProcessing = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _saveActualImage() async {
    if (_selectedImage != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final imageBytes = await _selectedImage!.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        final imageData = 'data:image/jpeg;base64,$base64Image';
        
        widget.onSaveImage(imageData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image saved to gallery!'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onBack();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _handleSaveAction() {
    if (_revenueCat.isSubscribed) {
      _saveActualImage();
    } else {
      _showSaveLimitDialog();
    }
  }

  void _showSaveLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.workspace_premium, size: 50, color: Color(0xFF7C3AED)),
            SizedBox(height: 8),
            Text(
              'Upgrade to Pro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4C1D95),
              ),
            ),
          ],
        ),
        content: Text(
          'Free users can preview images. Upgrade to Pro to save unlimited images to your gallery.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue Free', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onShowPaywall();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: Text('View Plans'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = _revenueCat.isSubscribed;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Text('Edit Photo', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF7C3AED),
        actions: [
          if (_selectedImage != null)
            IconButton(
              icon: _isProcessing 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(Icons.save, color: Colors.white),
              onPressed: _isProcessing ? null : _handleSaveAction,
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.5,
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2),
              color: Colors.grey[50],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _buildImageContent(isSubscribed),
            ),
          ),
          
          Spacer(),
          
          if (_selectedImage != null) _buildInfoText(isSubscribed),
          if (_selectedImage != null) SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(Icons.photo_library),
                    label: Text(_selectedImage == null ? 'Pick Photo' : 'Change Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF7C3AED),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Color(0xFF7C3AED)),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                if (_selectedImage != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _handleSaveAction,
                      icon: _isProcessing 
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Icon(Icons.auto_awesome),
                      label: _isProcessing 
                          ? Text('Saving...')
                          : Text(isSubscribed ? 'Save to Gallery' : 'Save (Pro)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubscribed ? Color(0xFF7C3AED) : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent(bool isSubscribed) {
    if (_selectedImage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text('Select a photo to edit', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 8),
            Text('Tap "Pick Photo" below to start', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Center(
          child: Image.file(_selectedImage!, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
        ),
        Positioned(
          top: 8, right: 8,
          child: Container(
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
            child: IconButton(icon: Icon(Icons.close, color: Colors.white, size: 20), onPressed: _removeImage),
          ),
        ),
        if (!isSubscribed)
          Positioned(
            top: 8, left: 8,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
              child: Text('FREE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoText(bool isSubscribed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            isSubscribed 
                ? 'Press save to add this image to your gallery'
                : 'Free users can preview images. Upgrade to Pro to save.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (!isSubscribed) SizedBox(height: 8),
          if (!isSubscribed)
            Text(
              '⭐ Upgrade to unlock unlimited saves',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}