import 'package:flutter/material.dart';
import 'package:pixelwipe/services/revenue_cat_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/paywall_service.dart';

class PaywallPage extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onSubscriptionComplete;

  const PaywallPage({
    Key? key,
    required this.onClose,
    required this.onSubscriptionComplete,
  }) : super(key: key);

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  final PaywallService _paywallService = PaywallService();
  final RevenueCatService _revenueCat = RevenueCatService();
  
  PaywallData? _paywallData;
  bool _isLoading = true;
  bool _isPurchasing = false;
  Package? _selectedPackage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPaywallData();
    _setupSubscriptionListener();
  }

  Future<void> _loadPaywallData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _paywallService.getPaywallData();
      setState(() {
        _paywallData = data;
        // Auto-select the popular plan (annual) if available
        final organized = _paywallService.getOrganizedPackages(data.availablePackages);
        if (organized['annual'] != null) {
          _selectedPackage = organized['annual'];
        } else if (organized['monthly'] != null) {
          _selectedPackage = organized['monthly'];
        } else if (organized['weekly'] != null) {
          _selectedPackage = organized['weekly'];
        }
      });
    } catch (e) {
      print('Error loading paywall data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setupSubscriptionListener() {
    _revenueCat.addSubscriptionListener((customerInfo) {
      if (_revenueCat.isSubscribed) {
        widget.onSubscriptionComplete();
      }
    });
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      final success = await _paywallService.purchasePackage(package);
      if (success) {
        widget.onSubscriptionComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase was not completed.')),
        );
      }
    } catch (e) {
      print('Purchase error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed. Please try again.')),
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
      await _paywallService.restorePurchases();
      if (_revenueCat.isSubscribed) {
        widget.onSubscriptionComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No active subscriptions found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed. Please try again.')),
      );
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Text(
            'At PixelWipe, we respect your privacy and are committed to protecting your personal data. '
            'We only collect necessary information to provide and improve our service.\n\n'
            '• We do not sell your personal data\n'
            '• We use secure payment processing\n'
            '• You can delete your data anytime\n'
            '• We comply with privacy regulations',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  void _showTermsOfUse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms of Use'),
        content: SingleChildScrollView(
          child: Text(
            'By using PixelWipe, you agree to our terms:\n\n'
            '• Subscription automatically renews unless canceled\n'
            '• Payments are processed through app stores\n'
            '• You can cancel anytime from your device settings\n'
            '• All sales are final for used subscriptions\n'
            '• We reserve the right to update these terms',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: _isPurchasing ? null : widget.onClose,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading ? _buildLoading() : _buildPaywallContent(screenHeight),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF7C3AED)),
          SizedBox(height: 16),
          Text('Loading plans...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPaywallContent(double screenHeight) {
    final organizedPackages = _paywallService.getOrganizedPackages(
      _paywallData?.availablePackages ?? []
    );

    // Create plans list from RevenueCat packages
    final List<Map<String, dynamic>> plans = [];
    
    final weekly = organizedPackages['weekly'];
    final monthly = organizedPackages['monthly'];
    final annual = organizedPackages['annual'];
    
    if (weekly != null) {
      plans.add({
        'package': weekly,
        'title': 'Weekly Plan',
        'subtitle': '${weekly.storeProduct.priceString} / week',
        'icon': Icons.calendar_view_week,
        'discountTag': null,
      });
    }
    
    if (monthly != null) {
      plans.add({
        'package': monthly,
        'title': 'Monthly Plan',
        'subtitle': '${monthly.storeProduct.priceString} / month',
        'icon': Icons.calendar_today,
        'discountTag': '-40%',
      });
    }
    
    if (annual != null) {
      plans.add({
        'package': annual,
        'title': 'Yearly Plan',
        'subtitle': '${annual.storeProduct.priceString} / year',
        'icon': Icons.star,
        'discountTag': 'Best Value',
      });
    }

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Top image + gradient stack
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: screenHeight * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF7C3AED).withOpacity(0.9),
                      Color(0xFF4C1D95).withOpacity(0.7),
                      Color(0xFF7C3AED).withOpacity(0.9),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "PixelWipe",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        "Premium",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildFeatureCarousel(),
                      SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom content with padding
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),

                // Plan selection tiles - FIXED: Each tile can trigger purchase directly
                ...plans.asMap().entries.map((entry) {
                  final plan = entry.value;
                  final isSelected = _selectedPackage == plan['package'];

                  return _buildSelectableTile(
                    isSelected: isSelected,
                    title: plan['title'],
                    subtitle: plan['subtitle'],
                    discountTag: plan['discountTag'],
                    onTap: () {
                      // FIX: When user clicks any plan, select it AND trigger purchase
                      setState(() {
                        _selectedPackage = plan['package'];
                      });
                      // Immediately start purchase process
                      _purchasePackage(plan['package']);
                    },
                  );
                }).toList(),

                SizedBox(height: 16),

                // Auto-renewable text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    "Auto-renewable, cancel anytime",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                // Continue button - FIXED: Always enabled since we auto-select a plan
                _buildContinueButton(),

                SizedBox(height: 16),

                // Footer links
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _showPrivacyPolicy,
                        child: Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: _showTermsOfUse,
                        child: Text(
                          "Terms of Use",
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: _isPurchasing ? null : _restorePurchases,
                        child: Text(
                          "Restore Purchase",
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCarousel() {
    final features = _paywallData?.features ?? [];
    
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return Container(
            width: 200,
            margin: EdgeInsets.symmetric(horizontal: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  feature.icon,
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 8),
                Text(
                  feature.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectableTile({
    required bool isSelected,
    required String title,
    required String subtitle,
    required String? discountTag,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF7C3AED).withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Color(0xFF7C3AED) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection indicator with loading state
                if (_isPurchasing && isSelected)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  )
                else
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
                
                // Plan details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
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
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Icon - show loading if this plan is being purchased
                if (_isPurchasing && isSelected)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    // FIXED: Button is always enabled because we auto-select a plan
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPurchasing ? null : () {
          if (_selectedPackage != null) {
            _purchasePackage(_selectedPackage!);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Color(0xFF7C3AED).withOpacity(0.3),
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
                'Continue with ${_selectedPackage?.packageType.displayName ?? 'Selected Plan'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _revenueCat.removeSubscriptionListener((_) {});
    _scrollController.dispose();
    super.dispose();
  }
}