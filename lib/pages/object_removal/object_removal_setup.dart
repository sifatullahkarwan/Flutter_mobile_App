import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pixelwipe/models/processed_image.dart';
import 'package:pixelwipe/pages/object_removal/object_removal_setup_controller.dart';
import 'object_removal_setup_controller.dart';
import 'object_removal_setup_view.dart';

class ObjectRemovalSetupPage extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String) onSaveImage;
  final VoidCallback onShowPaywall;

  const ObjectRemovalSetupPage({
    Key? key,
    required this.onBack,
    required this.onSaveImage,
    required this.onShowPaywall, required void Function(ProcessedImage image) onSaveToGallery,
  }) : super(key: key);

  @override
  _ObjectRemovalSetupPageState createState() => _ObjectRemovalSetupPageState();
}

class _ObjectRemovalSetupPageState extends State<ObjectRemovalSetupPage> {
  final ObjectRemovalSetupController _controller = ObjectRemovalSetupController();

  @override
  void initState() {
    super.initState();
    // No need to set context, remove this line
  }

  @override
  Widget build(BuildContext context) {
    return ObjectRemovalSetupView(
      controller: _controller,
      onBack: widget.onBack,
      onSaveImage: widget.onSaveImage,
      onShowPaywall: widget.onShowPaywall, onSaveToGallery: (ProcessedImage p1) {  },
    );
  }
}