import 'package:flutter/material.dart';
import 'package:pixelwipe/services/revenue_cat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallPage extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onSubscriptionComplete;

  const PaywallPage({
    Key? key,
    required this.onClose,
    required this.onSubscriptionComplete,
  }) : super(key: key);

  @override
  _PaywallPageState createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  final RevenueCatService _revenueCat = RevenueCatService();
  List<Package> _packages = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  Package? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  void _loadPackages() async {
    final packages = _revenueCat.getAvailablePackages();
    setState(() {
      _packages = packages;
      _isLoading = false;
      if (_packages.isNotEmpty) {
        _selectedPackage = _packages.first;
      }
    });
  }

  Future<void> _purchaseSelectedPackage() async {
    if (_selectedPackage == null || _isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await _revenueCat.purchasePackage(_selectedPackage!);
      if (success) {
        widget.onSubscriptionComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      await _revenueCat.restorePurchases();
      if (_revenueCat.isSubscribed) {
        widget.onSubscriptionComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No active subscriptions found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  String _getPackageTypeName(PackageType type) {
    switch (type) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Yearly';
      case PackageType.sixMonth:
        return '6 Months';
      case PackageType.threeMonth:
        return '3 Months';
      case PackageType.twoMonth:
        return '2 Months';
      case PackageType.lifetime:
        return 'Lifetime';
      default:
        return 'Premium';
    }
  }

  String? _getDiscountTag(PackageType type) {
    switch (type) {
      case PackageType.monthly:
        return 'Popular';
      case PackageType.annual:
        return 'Best Value';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onClose,
        ),
        title: Text('PixelWipe Premium', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF7C3AED),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _packages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No subscription plans available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: widget.onClose,
                        child: Text('Go Back'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF9D4DFD),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'PixelWipe Premium',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Unlock all features',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),

                      // Features
                      _buildFeatureItem('🚀', 'Unlimited Object Removal'),
                      _buildFeatureItem('⚡', 'Fast Processing'),
                      _buildFeatureItem('🎨', 'High Quality Results'),
                      _buildFeatureItem('📱', 'All Devices Supported'),
                      SizedBox(height: 30),

                      // Package Selection
                      Text(
                        'Choose Your Plan',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),

                      ..._packages.map((package) {
                        final isSelected = _selectedPackage == package;
                        final discountTag = _getDiscountTag(package.packageType);

                        return _buildPackageCard(
                          package: package,
                          isSelected: isSelected,
                          discountTag: discountTag,
                          onTap: () {
                            setState(() {
                              _selectedPackage = package;
                            });
                          },
                        );
                      }).toList(),

                      SizedBox(height: 24),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isPurchasing ? null : _purchaseSelectedPackage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isPurchasing
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Restore Purchases
                      Center(
                        child: TextButton(
                          onPressed: _isPurchasing ? null : _restorePurchases,
                          child: Text(
                            'Restore Purchases',
                            style: TextStyle(color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Footer
                      Center(
                        child: Text(
                          'Auto-renewable subscription. Cancel anytime.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required Package package,
    required bool isSelected,
    required String? discountTag,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: isSelected ? Color(0xFF7C3AED).withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Color(0xFF7C3AED) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Color(0xFF7C3AED) : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(0xFF7C3AED),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getPackageTypeName(package.packageType),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 8),
                        if (discountTag != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: discountTag == 'Best Value' 
                                  ? Color(0xFF10B981) 
                                  : Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              discountTag,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      package.storeProduct.priceString,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      package.storeProduct.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}