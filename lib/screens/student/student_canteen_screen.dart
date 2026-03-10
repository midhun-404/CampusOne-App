import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';
import '../../core/constants/app_constants.dart';

// ─── Category food images (curated Unsplash) ──────────────────────────────────
const _kCategoryImages = {
  'Breakfast': 'https://images.unsplash.com/photo-1533089860892-a7c6f0a88666?w=600&q=80',
  'Lunch':     'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80',
  'Snacks':    'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=80',
  'Drinks':    'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=600&q=80',
  'Other':     'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=600&q=80',
};

// Banner images per category for hero header
const _kBannerImages = {
  'All':       'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=900&q=80',
  'Breakfast': 'https://images.unsplash.com/photo-1528736235302-52922df5c122?w=900&q=80',
  'Lunch':     'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=900&q=80',
  'Snacks':    'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=900&q=80',
  'Drinks':    'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=900&q=80',
  'Other':     'https://images.unsplash.com/photo-1476224203421-9ac39bcb3327?w=900&q=80',
};

class StudentCanteenScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialCart;
  const StudentCanteenScreen({super.key, this.initialCart});

  @override
  State<StudentCanteenScreen> createState() => _StudentCanteenScreenState();
}

class _StudentCanteenScreenState extends State<StudentCanteenScreen> {
  final Map<String, int> _cart = {};
  late Razorpay _razorpay;
  String _selectedCategory = 'All';
  final _categories = ['All', 'Breakfast', 'Lunch', 'Snacks', 'Drinks', 'Other'];

  List<Map<String, dynamic>>? _pendingOrderItems;
  double _pendingTotal = 0;
  String? _razorpayOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    if (widget.initialCart != null) {
      for (var item in widget.initialCart!) {
        final id = item['itemId'] as String?;
        final qty = item['quantity'] as int?;
        if (id != null && qty != null) {
          _cart[id] = qty;
        }
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final fs       = Provider.of<FirestoreService>(context, listen: false);
    final authUser = Provider.of<AuthService>(context, listen: false).currentUser!;
    final orderId  = _razorpayOrderId ?? DateTime.now().millisecondsSinceEpoch.toString();

    CanteenProfileModel? profile;
    try { profile = await fs.getCanteenProfile().first; } catch (_) {}

    final order = CanteenOrderModel(
      id: orderId,
      studentId: authUser.id,
      studentName: authUser.name,
      studentPhone: authUser.phone,
      studentFcmToken: authUser.fcmToken,
      items: _pendingOrderItems ?? [],
      totalAmount: _pendingTotal,
      paymentId: response.paymentId ?? 'test_txn',
      status: 'Pending',
      orderTime: DateTime.now(),
      canteenName: profile?.canteenName,
    );

    await fs.createCanteenOrder(order);

    if (mounted) {
      setState(() => _cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Order Placed! Your food token is ready.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      context.push('/student/canteen/orders');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  void _checkout(List<CanteenItemModel> menu) {
    if (_cart.isEmpty) return;
    final authUser = Provider.of<AuthService>(context, listen: false).currentUser!;
    double total = 0;
    List<Map<String, dynamic>> orderItems = [];
    _cart.forEach((itemId, qty) {
      if (qty > 0) {
        final item = menu.firstWhere((e) => e.id == itemId);
        total += item.price * qty;
        orderItems.add({'itemId': item.id, 'name': item.name, 'quantity': qty, 'price': item.price});
      }
    });
    if (total == 0) return;
    _pendingOrderItems = orderItems;
    _pendingTotal = total;
    _razorpayOrderId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      _razorpay.open({
        'key': AppConstants.razorpayTestKey,
        'amount': (total * 100).toInt(),
        'name': 'CampusOne Canteen',
        'description': 'Food Order',
        'prefill': {'contact': '9999999999', 'email': authUser.email},
      });
    } catch (e) {
      debugPrint('Razorpay error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: StreamBuilder<CanteenProfileModel?>(
        stream: fs.getCanteenProfile(),
        builder: (context, profileSnap) {
          final profile     = profileSnap.data;
          final canteenName = profile?.canteenName ?? 'Campus Canteen';
          final openHours   = profile != null ? '${profile.openTime} – ${profile.closeTime}' : '';
          final bannerUrl   = _kBannerImages[_selectedCategory] ?? _kBannerImages['All']!;

          return CustomScrollView(
            slivers: [
              // ── Premium Hero Header ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 240,
                floating: false,
                pinned: true,
                backgroundColor: Colors.deepOrange.shade800,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canteenName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 6)]),
                      ),
                      if (openHours.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white70, size: 10),
                            const SizedBox(width: 3),
                            Text(openHours, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                    ],
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Image.network(
                          bannerUrl,
                          key: ValueKey(bannerUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.deepOrange.shade800),
                        ),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                      tooltip: 'My Orders',
                      onPressed: () => context.push('/student/canteen/orders'),
                    ),
                  ),
                ],
              ),

              // ── Category chips ─────────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryBarDelegate(
                  categories: _categories,
                  selected: _selectedCategory,
                  onSelect: (c) => setState(() => _selectedCategory = c),
                ),
              ),

              // ── Food items ────────────────────────────────────────────────
              StreamBuilder<List<CanteenItemModel>>(
                stream: fs.getCanteenMenu(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00))),
                    );
                  }
                  final menu     = (snap.data ?? []).where((e) => e.isAvailable).toList();
                  final filtered = _selectedCategory == 'All'
                      ? menu
                      : menu.where((e) => e.category == _selectedCategory).toList();

                  // Cart totals
                  double cartTotal = 0;
                  int    cartCount = 0;
                  _cart.forEach((id, qty) {
                    final item = menu.where((e) => e.id == id).firstOrNull;
                    if (item != null) { cartTotal += item.price * qty; cartCount += qty; }
                  });

                  if (filtered.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_food_rounded, size: 70, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('No ${_selectedCategory == "All" ? "" : "$_selectedCategory "}items available',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: cartTotal > 0 ? 120 : 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = filtered[index];
                          final qty  = _cart[item.id] ?? 0;
                          return _MenuItemCard(
                            item: item,
                            qty: qty,
                            onAdd:    () => setState(() => _cart[item.id] = qty + 1),
                            onRemove: () { if (qty > 0) setState(() => _cart[item.id] = qty - 1); },
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      // ── Floating cart bar ────────────────────────────────────────────────
      bottomSheet: StreamBuilder<List<CanteenItemModel>>(
        stream: fs.getCanteenMenu(),
        builder: (ctx, snap) {
          final menu = (snap.data ?? []).where((e) => e.isAvailable).toList();
          double total = 0;
          int    count = 0;
          _cart.forEach((id, qty) {
            final item = menu.where((e) => e.id == id).firstOrNull;
            if (item != null) { total += item.price * qty; count += qty; }
          });
          if (total <= 0) return const SizedBox.shrink();
          return _CartBottomBar(total: total, count: count, onCheckout: () => _checkout(menu));
        },
      ),
    );
  }
}

// ─── Pinned category bar delegate ─────────────────────────────────────────────
class _CategoryBarDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;
  const _CategoryBarDelegate({required this.categories, required this.selected, required this.onSelect});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  bool shouldRebuild(_CategoryBarDelegate old) =>
      old.selected != selected || old.categories != categories;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF5F5F7),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: categories.map((c) {
            final isSelected = c == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: GestureDetector(
                  onTap: () => onSelect(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFFB300)])
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFFFF8C00).withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: 8, offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Premium Menu Item Card ───────────────────────────────────────────────────
class _MenuItemCard extends StatelessWidget {
  final CanteenItemModel item;
  final int     qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _MenuItemCard({required this.item, required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final imgUrl = item.imageUrl ?? _kCategoryImages[item.category] ?? _kCategoryImages['Other']!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          // Food image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: Stack(
              children: [
                Image.network(
                  imgUrl,
                  width: 112, height: 112, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 112, height: 112,
                    color: Colors.orange.shade50,
                    child: Icon(Icons.fastfood_rounded, size: 40, color: Colors.orange.shade300),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 8, left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(item.category, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A2E)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 18),
                      ),
                      _QtyControl(qty: qty, onAdd: onAdd, onRemove: onRemove),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quantity control ─────────────────────────────────────────────────────────
class _QtyControl extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const _QtyControl({required this.qty, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (qty == 0) {
      return GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF8C00), Color(0xFFFFB300)]),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: const Color(0xFFFF8C00).withOpacity(0.4), blurRadius: 8)],
          ),
          child: const Text('ADD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 16),
            color: const Color(0xFFFF8C00),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onRemove,
          ),
          Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16),
            color: const Color(0xFFFF8C00),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

// ─── Floating cart bottom bar ─────────────────────────────────────────────────
class _CartBottomBar extends StatelessWidget {
  final double total;
  final int count;
  final VoidCallback onCheckout;
  const _CartBottomBar({required this.total, required this.count, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1D2E), Color(0xFF252839)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.orange.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          // Cart icon + count
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFFFB300), size: 22),
              ),
              Positioned(
                right: -4, top: -4,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Center(child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cart Total', style: TextStyle(color: Colors.white54, fontSize: 11)),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onCheckout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF8C00)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: const Color(0xFFFF8C00).withOpacity(0.5), blurRadius: 10)],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
