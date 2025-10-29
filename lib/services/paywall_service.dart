import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenue_cat_service.dart';

class PaywallService {
  static final PaywallService _instance = PaywallService._internal();
  factory PaywallService() => _instance;
  PaywallService._internal();

  final RevenueCatService _revenueCat = RevenueCatService();

  Future<PaywallData> getPaywallData() async {
    final offerings = _revenueCat.currentOfferings;
    
    if (offerings?.current == null) {
      return PaywallData(
        availablePackages: [],
        features: _getDefaultFeatures(),
        popularPlan: 'monthly',
      );
    }

    final packages = offerings!.current!.availablePackages;
    final popularPlan = _getPopularPlan(packages);
    
    return PaywallData(
      availablePackages: packages,
      features: _getDefaultFeatures(),
      popularPlan: popularPlan,
    );
  }

  String _getPopularPlan(List<Package> packages) {
    // Determine which plan to highlight as popular
    final hasAnnual = packages.any((p) => p.packageType == PackageType.annual);
    final hasMonthly = packages.any((p) => p.packageType == PackageType.monthly);
    
    if (hasAnnual) return 'annual'; // Usually annual is the best value
    if (hasMonthly) return 'monthly';
    return 'weekly';
  }

  List<PaywallFeature> _getDefaultFeatures() {
    return [
      PaywallFeature(
        icon: '🎯',
        title: 'Unlimited Object Removal',
        description: 'Remove as many objects as you want from photos',
      ),
      PaywallFeature(
        icon: '💧',
        title: 'No Watermarks',
        description: 'Clean, professional results without branding',
      ),
      PaywallFeature(
        icon: '🖼️',
        title: 'High Quality Exports',
        description: 'Save images in maximum resolution',
      ),
      PaywallFeature(
        icon: '⚡',
        title: 'Priority Processing',
        description: 'Faster AI processing for quick results',
      ),
      PaywallFeature(
        icon: '📱',
        title: 'All Devices',
        description: 'Use on all your devices with one subscription',
      ),
      PaywallFeature(
        icon: '🔄',
        title: 'Easy Cancel',
        description: 'Cancel anytime from your app store settings',
      ),
    ];
  }

  // Get packages organized by type
  Map<String, Package> getOrganizedPackages(List<Package> packages) {
    final organized = <String, Package>{};
    
    for (final package in packages) {
      switch (package.packageType) {
        case PackageType.monthly:
          organized['monthly'] = package;
          break;
        case PackageType.annual:
          organized['annual'] = package;
          break;
        case PackageType.weekly:
          organized['weekly'] = package;
          break;
        case PackageType.sixMonth:
          organized['sixMonth'] = package;
          break;
        case PackageType.threeMonth:
          organized['threeMonth'] = package;
          break;
        case PackageType.lifetime:
          organized['lifetime'] = package;
          break;
        default:
          organized['other'] = package;
      }
    }
    
    return organized;
  }

  // Calculate savings for annual plan
  String? calculateAnnualSavings(Package? monthly, Package? annual) {
    if (monthly == null || annual == null) return null;
    
    try {
      final monthlyPrice = monthly.storeProduct.price;
      final annualPrice = annual.storeProduct.price;
      
      if (monthlyPrice > 0 && annualPrice > 0) {
        final monthlyCostPerYear = monthlyPrice * 12;
        final savings = monthlyCostPerYear - annualPrice;
        final savingsPercentage = ((savings / monthlyCostPerYear) * 100).round();
        
        if (savings > 0) {
          return 'Save $savingsPercentage%';
        }
      }
    } catch (e) {
      print('Error calculating savings: $e');
    }
    
    return null;
  }

  Future<bool> purchasePackage(Package package) async {
    return await _revenueCat.purchasePackage(package);
  }

  Future<void> restorePurchases() async {
    await _revenueCat.restorePurchases();
  }
}

class PaywallData {
  final List<Package> availablePackages;
  final List<PaywallFeature> features;
  final String popularPlan;

  PaywallData({
    required this.availablePackages,
    required this.features,
    required this.popularPlan,
  });
}

class PaywallFeature {
  final String icon;
  final String title;
  final String description;

  PaywallFeature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// Extension to get display names for package types
extension PackageTypeExtension on PackageType {
  String get displayName {
    switch (this) {
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annual';
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.sixMonth:
        return '6 Months';
      case PackageType.threeMonth:
        return '3 Months';
      case PackageType.lifetime:
        return 'Lifetime';
      case PackageType.custom:
        return 'Custom';
      case PackageType.unknown:
        return 'Unknown';
      case PackageType.twoMonth:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String get periodDescription {
    switch (this) {
      case PackageType.monthly:
        return 'per month';
      case PackageType.annual:
        return 'per year';
      case PackageType.weekly:
        return 'per week';
      case PackageType.sixMonth:
        return 'for 6 months';
      case PackageType.threeMonth:
        return 'for 3 months';
      case PackageType.lifetime:
        return 'one-time payment';
      case PackageType.custom:
        return '';
      case PackageType.unknown:
        return '';
      case PackageType.twoMonth:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}