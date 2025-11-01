import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pixelwipe/pages/object_removal/object_removal_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/processed_image.dart';
import 'pages/landing_page.dart';
import 'pages/gallery_page.dart';
import 'pages/home_page.dart';
import 'package:pixelwipe/services/revenue_cat_service.dart';
import 'package:pixelwipe/pages/paywall_page.dart';

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  String _currentPage = 'landing';
  bool _isSubscribed = false;
  List<ProcessedImage> _processedImages = [];
  final RevenueCatService _revenueCat = RevenueCatService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _revenueCat.initialize();
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _updateSubscriptionStatus();
    
    final prefs = await SharedPreferences.getInstance();
    final savedImages = prefs.getString('pixelwipe_images');

    if (savedImages != null) {
      try {
        final List<dynamic> imagesList = json.decode(savedImages);
        setState(() {
          _processedImages = imagesList.map((json) => ProcessedImage.fromJson(json)).toList();
        });
      } catch (e) {
        print('Failed to load images: $e');
      }
    }
  }

  void _updateSubscriptionStatus() {
    setState(() {
      _isSubscribed = _revenueCat.isSubscribed;
    });
    _saveSubscriptionStatus();
  }

  Future<void> _saveSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pixelwipe_subscribed', _isSubscribed);
  }

  void _handleContinueFromLanding() {
    setState(() {
      _currentPage = 'home';
    });
  }

  void _handleShowPaywall() {
    setState(() {
      _currentPage = 'paywall';
    });
  }

  void _handleClosePaywall() {
    setState(() {
      _currentPage = 'home';
    });
    _updateSubscriptionStatus();
  }

  void _handleSubscriptionComplete() {
    setState(() {
      _isSubscribed = true;
      _currentPage = 'home';
    });
    _saveSubscriptionStatus();
  }

  void _handleSaveImage(String imageData) async {
    final newImage = ProcessedImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: imageData,
      timestamp: DateTime.now().millisecondsSinceEpoch, 
      name: 'pixelwipe_${DateTime.now().millisecondsSinceEpoch}',
    );

    final updatedImages = [newImage, ..._processedImages];
    setState(() {
      _processedImages = updatedImages;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = json.encode(updatedImages.map((img) => img.toJson()).toList());
      await prefs.setString('pixelwipe_images', imagesJson);
    } catch (e) {
      print('Failed to save images: $e');
    }
  }

  void _handleDeleteImage(String id) async {
    final updatedImages = _processedImages.where((img) => img.id != id).toList();
    setState(() {
      _processedImages = updatedImages;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = json.encode(updatedImages.map((img) => img.toJson()).toList());
      await prefs.setString('pixelwipe_images', imagesJson);
    } catch (e) {
      print('Failed to save images: $e');
    }
  }

  void _handleSaveToGallery(ProcessedImage image) {
    _handleSaveImage(image.data);
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPage) {
      case 'landing':
        return LandingPage(
          onContinue: _handleContinueFromLanding, 
          onShowPaywall: _handleShowPaywall,
        );
      case 'paywall':
        return PaywallPage(
          onClose: _handleClosePaywall,
          onSubscriptionComplete: _handleSubscriptionComplete,
        );
      case 'object_removal':
        return ObjectRemovalSetupPage(
          onBack: () => setState(() => _currentPage = 'home'),
          onSaveImage: _handleSaveImage,
          onShowPaywall: _handleShowPaywall,
          onSaveToGallery: _handleSaveToGallery,
        );
      case 'gallery':
        return GalleryPage(
          onBack: () => setState(() => _currentPage = 'home'),
          images: _processedImages,
          onDeleteImage: _handleDeleteImage,
        );
      case 'home':
      default:
        return HomePage(
          isSubscribed: _isSubscribed,
          processedImages: _processedImages,
          onUpgrade: _handleShowPaywall,
          onEditNewPhoto: () => setState(() => _currentPage = 'object_removal'),
          onViewGallery: () => setState(() => _currentPage = 'gallery'),
        );
    }
  }
}