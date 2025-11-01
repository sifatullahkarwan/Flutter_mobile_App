// // services/paywall_service.dart
// import 'package:pixelwipe/services/revenue_cat_service.dart';
// import 'package:purchases_flutter/purchases_flutter.dart';

// class PaywallData {
//   final List<Package> availablePackages;
//   final List<PaywallFeature> features;

//   PaywallData({
//     required this.availablePackages,
//     required this.features,
//   });
// }

// class PaywallFeature {
//   final String icon;
//   final String title;
//   final String description;

//   PaywallFeature({
//     required this.icon,
//     required this.title,
//     required this.description,
//   });
// }

// class PaywallService {
//   final RevenueCatSingleton _revenueCat = RevenueCatSingleton();

//   Future<PaywallData> getPaywallData() async {
//     final packages = _revenueCat.getAvailablePackages();
    
//     // Define features for your paywall
//     final features = [
//       PaywallFeature(
//         icon: '🚀',
//         title: 'Unlimited Object Removal',
//         description: 'Remove as many objects as you want',
//       ),
//       PaywallFeature(
//         icon: '⚡',
//         title: 'Fast Processing',
//         description: 'AI-powered removal in seconds',
//       ),
//       PaywallFeature(
//         icon: '🎨',
//         title: 'High Quality Results',
//         description: 'Professional-grade image editing',
//       ),
//       PaywallFeature(
//         icon: '📱',
//         title: 'All Devices',
//         description: 'Use on all your devices',
//       ),
//     ];

//     return PaywallData(
//       availablePackages: packages,
//       features: features,
//     );
//   }

//   Map<String, Package?> getOrganizedPackages(List<Package> packages) {
//     Package? weekly;
//     Package? monthly;
//     Package? annual;

//     for (final package in packages) {
//       switch (package.packageType) {
//         case PackageType.weekly:
//           weekly = package;
//           break;
//         case PackageType.monthly:
//           monthly = package;
//           break;
//         case PackageType.annual:
//           annual = package;
//           break;
//         case PackageType.sixMonth:
//         case PackageType.threeMonth:
//         case PackageType.twoMonth:
//         case PackageType.lifetime:
//         case PackageType.unknown:
//           break;
//         case PackageType.custom:
//           // TODO: Handle this case.
//           throw UnimplementedError();
//       }
//     }

//     return {
//       'weekly': weekly,
//       'monthly': monthly,
//       'annual': annual,
//     };
//   }

//   Future<bool> purchasePackage(Package package) async {
//     return await _revenueCat.purchasePackage(package);
//   }

//   Future<void> restorePurchases() async {
//     await _revenueCat.restorePurchases();
//   }
// }