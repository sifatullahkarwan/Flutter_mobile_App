import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/processed_image.dart';

class LocalStorage {
  static const String _subscribedKey = 'pixelwipe_subscribed';
  static const String _imagesKey = 'pixelwipe_images';

  static Future<bool> getSubscribedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_subscribedKey) ?? false;
  }

  static Future<void> setSubscribedStatus(bool subscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscribedKey, subscribed);
  }

  static Future<List<ProcessedImage>> getProcessedImages() async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = prefs.getString(_imagesKey);
    
    if (imagesJson == null) return [];
    
    try {
      final List<dynamic> imagesList = json.decode(imagesJson);
      return imagesList.map((json) => ProcessedImage.fromJson(json)).toList();
    } catch (e) {
      print('Failed to load images: $e');
      return [];
    }
  }

  static Future<void> saveProcessedImages(List<ProcessedImage> images) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = json.encode(images.map((img) => img.toJson()).toList());
    await prefs.setString(_imagesKey, imagesJson);
  }
}