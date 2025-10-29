import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pixelwipe/pages/object_removal_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/processed_image.dart';
import 'pages/landing_page.dart';
import 'pages/paywall_page.dart';

import 'pages/gallery_page.dart';
import 'pages/home_page.dart';
import 'package:pixelwipe/services/revenue_cat_service.dart';

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
    // Initialize RevenueCat
    await _revenueCat.initialize();
    
    // Load initial data
    await _loadInitialData();
    
    // Set up subscription listener
    _setupSubscriptionListener();
  }

  void _setupSubscriptionListener() {
    _revenueCat.addSubscriptionListener((customerInfo) {
      _updateSubscriptionStatus();
    });
  }

  Future<void> _loadInitialData() async {
    // First check RevenueCat for subscription status
    _updateSubscriptionStatus();
    
    // Then load local images
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
    
    // Also save to local storage for persistence
    _saveSubscriptionStatus();
  }

  Future<void> _saveSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pixelwipe_subscribed', _isSubscribed);
  }

  void _handleContinueFromLanding() {
    setState(() {
      _currentPage = 'paywall';
    });
  }

  void _handleSubscribe() async {
    // This is now handled by RevenueCat directly
    // We'll update the status through the subscription listener
    setState(() {
      _currentPage = 'home';
    });
  }

  void _handleClosePaywall() {
    setState(() {
      _currentPage = 'home';
    });
  }

  void _handleSubscriptionComplete() {
    setState(() {
      _isSubscribed = true;
      _currentPage = 'home';
    });
    _saveSubscriptionStatus();
  }

  void _handleShowPaywall() {
    setState(() {
      _currentPage = 'paywall';
    });
  }

  void _handleSaveImage(String imageData) async {
    final newImage = ProcessedImage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      data: imageData,
      timestamp: DateTime.now().millisecondsSinceEpoch,
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

  @override
  Widget build(BuildContext context) {
    switch (_currentPage) {
      case 'landing':
        return LandingPage(onContinue: _handleContinueFromLanding);
      case 'paywall':
        return PaywallPage(
          onClose: _handleClosePaywall,
          onSubscriptionComplete: _handleSubscriptionComplete,
        );
      case 'object_removal': // New case for object removal
        return ObjectRemovalSetupPage(
          onBack: () => setState(() => _currentPage = 'home'),
          onSaveImage: _handleSaveImage,
          onShowPaywall: _handleShowPaywall,
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
          onEditNewPhoto: () => setState(() => _currentPage = 'object_removal'), // Changed from 'editor' to 'object_removal'
          onViewGallery: () => setState(() => _currentPage = 'gallery'),
        );
    }
  }

  @override
  void dispose() {
    _revenueCat.removeSubscriptionListener((_) {});
    super.dispose();
  }
}