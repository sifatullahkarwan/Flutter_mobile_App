import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isSubscribed = false;
  Offerings? _currentOfferings;

  Future<void> initialize() async {
    try {
      await _loadOfferings();
      await _loadSubscriptionStatus();
      print('RevenueCat initialized successfully');
    } catch (e) {
      print('RevenueCat initialization error: $e');
    }
  }

  Future<void> _loadOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        _currentOfferings = offerings;
        print('Current offering: ${offerings.current!.identifier}');
        print('Available packages: ${offerings.current!.availablePackages.length}');
      }
    } catch (e) {
      print('Error loading offerings: $e');
    }
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _isSubscribed = customerInfo.entitlements.active.containsKey("premium");
      print('Subscription status: $_isSubscribed');
    } catch (e) {
      print('Error loading subscription status: $e');
    }
  }

  List<Package> getAvailablePackages() {
    if (_currentOfferings?.current != null) {
      List<Package> availablePackages = _currentOfferings!.current!.availablePackages;
      print('Returning ${availablePackages.length} packages');
      return availablePackages;
    }
    return [];
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = (await Purchases.purchasePackage(package)) as CustomerInfo;
      _isSubscribed = customerInfo.entitlements.active.containsKey("premium");
      return _isSubscribed;
    } catch (e) {
      print('Purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _isSubscribed = customerInfo.entitlements.active.containsKey("premium");
    } catch (e) {
      print('Restore purchases failed: $e');
      rethrow;
    }
  }

  bool get isSubscribed => _isSubscribed;
  Offerings? get currentOfferings => _currentOfferings;
}