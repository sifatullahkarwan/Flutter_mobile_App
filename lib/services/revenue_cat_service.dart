import 'package:purchases_flutter/purchases_flutter.dart';
import 'dart:io' show Platform;

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // Your RevenueCat API keys
  static const String appleApiKey = 'appl_your_apple_api_key_here';
  static const String googleApiKey = 'goog_your_google_api_key_here';
  
  bool _isSubscribed = false;
  Offerings? _currentOfferings;

  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.info);
      
      PurchasesConfiguration configuration;
      
      if (Platform.isIOS || Platform.isMacOS) {
        configuration = PurchasesConfiguration(appleApiKey);
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(googleApiKey);
      } else {
        throw Exception('Platform not supported');
      }
      
      await Purchases.configure(configuration);
      
      // Load initial data
      await _loadSubscriptionStatus();
      await _loadOfferings();
    } catch (e) {
      print('RevenueCat initialization failed: $e');
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateSubscriptionStatus(customerInfo);
    } catch (e) {
      print('Error loading subscription status: $e');
    }
  }

  Future<void> _loadOfferings() async {
    try {
      _currentOfferings = await Purchases.getOfferings();
    } catch (e) {
      print('Error loading offerings: $e');
    }
  }

  void _updateSubscriptionStatus(CustomerInfo customerInfo) {
    _isSubscribed = customerInfo.entitlements.all['pro']?.isActive == true;
  }

  bool get isSubscribed => _isSubscribed;

  Offerings? get currentOfferings => _currentOfferings;

  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaserInfo = await Purchases.purchasePackage(package);
      _updateSubscriptionStatus(purchaserInfo as CustomerInfo);
      return _isSubscribed;
    } catch (e) {
      print('Purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      final purchaserInfo = await Purchases.restorePurchases();
      _updateSubscriptionStatus(purchaserInfo);
    } catch (e) {
      print('Restore purchases failed: $e');
    }
  }

  void addSubscriptionListener(Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  void removeSubscriptionListener(Function(CustomerInfo) listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }
}