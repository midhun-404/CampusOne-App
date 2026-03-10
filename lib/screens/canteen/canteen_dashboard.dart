import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/canteen_model.dart';
import '../../core/constants/kerala_colleges.dart';

// Color palette for canteen admin
const _kDark = Color(0xFF1A1D2E);
const _kCard = Color(0xFF252839);
const _kAccent = Color(0xFFFFB300);
const _kGreen = Color(0xFF4CAF50);
const _kOrange = Color(0xFFFF7043);

class CanteenDashboard extends StatefulWidget {
  const CanteenDashboard({super.key});

  @override
  State<CanteenDashboard> createState() => _CanteenDashboardState();
}

class _CanteenDashboardState extends State<CanteenDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() => _currentTab = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDark,
      appBar: AppBar(
        backgroundColor: _kDark,
        elevation: 0,
        title: StreamBuilder<CanteenProfileModel?>(
          stream: Provider.of<FirestoreService>(context).getCanteenProfile(),
          builder: (context, snapshot) {
            final name = snapshot.data?.canteenName ?? 'Canteen Admin';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Admin Panel', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              if (context.mounted) context.go('/role_selection');
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kAccent,
          labelColor: _kAccent,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Menu'),
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Analytics'),
            Tab(icon: Icon(Icons.storefront), text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MenuManagementTab(),
          _KanbanOrdersTab(),
          _AnalyticsTab(),
          _CanteenProfileTab(),
        ],
      ),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton.extended(
              backgroundColor: _kAccent,
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('Add Item', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : _currentTab == 1
              ? FloatingActionButton.extended(
                  backgroundColor: _kGreen,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _OrderScannerScreen())),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text('Scan QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null,
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    String selectedCategory = 'Lunch';
    final fs = Provider.of<FirestoreService>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: _kCard,
          title: const Text('Add Menu Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _darkField(nameCtrl, 'Item Name', Icons.fastfood),
                const SizedBox(height: 12),
                _darkField(descCtrl, 'Description', Icons.description),
                const SizedBox(height: 12),
                _darkField(priceCtrl, 'Price (₹)', Icons.currency_rupee, isNumber: true),
                const SizedBox(height: 12),
                _darkField(imageCtrl, 'Image URL (optional)', Icons.image_outlined),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: _kCard,
                  style: const TextStyle(color: Colors.white),
                  decoration: _darkDecoration('Category', Icons.category),
                  items: ['Breakfast', 'Lunch', 'Snacks', 'Drinks', 'Other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val ?? 'Other'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.black),
              onPressed: () async {
                final price = double.tryParse(priceCtrl.text) ?? 0;
                if (nameCtrl.text.isNotEmpty && price > 0) {
                  final imageUrl = imageCtrl.text.trim().isEmpty ? null : imageCtrl.text.trim();
                  final item = CanteenItemModel(
                    id: '', name: nameCtrl.text, description: descCtrl.text,
                    price: price, isAvailable: true, category: selectedCategory,
                    imageUrl: imageUrl,
                  );
                  await fs.addCanteenItem(item);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _darkField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
  return TextField(
    controller: ctrl,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    style: const TextStyle(color: Colors.white),
    decoration: _darkDecoration(label, icon),
  );
}

InputDecoration _darkDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white54),
    prefixIcon: Icon(icon, color: Colors.white38, size: 20),
    filled: true,
    fillColor: Colors.white.withOpacity(0.08),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kAccent)),
  );
}

// -----------------------------------------------------------------------
// MENU MANAGEMENT TAB
// -----------------------------------------------------------------------
class _MenuManagementTab extends StatefulWidget {
  const _MenuManagementTab();
  @override State<_MenuManagementTab> createState() => _MenuManagementTabState();
}
class _MenuManagementTabState extends State<_MenuManagementTab> {
  String _filter = 'All';
  final _categories = ['All', 'Breakfast', 'Lunch', 'Snacks', 'Drinks', 'Other'];

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: _categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _filter == c ? _kAccent : _kCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c, style: TextStyle(color: _filter == c ? Colors.black : Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CanteenItemModel>>(
            stream: fs.getCanteenMenu(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _kAccent));
              final items = (snapshot.data ?? []).where((i) => _filter == 'All' || i.category == _filter).toList();
              if (items.isEmpty) return Center(child: Text('No ${_filter == 'All' ? '' : _filter} items.', style: const TextStyle(color: Colors.white54)));
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final item = items[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(color: _kAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.fastfood, color: _kAccent),
                      ),
                      title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text('₹${item.price.toStringAsFixed(0)} · ${item.category}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            activeColor: _kGreen,
                            value: item.isAvailable,
                            onChanged: (val) => fs.updateCanteenItem(item.id, {'isAvailable': val}),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => fs.deleteCanteenItem(item.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------
// KANBAN ORDERS TAB
// -----------------------------------------------------------------------
class _KanbanOrdersTab extends StatelessWidget {
  const _KanbanOrdersTab();

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);
    return StreamBuilder<List<CanteenOrderModel>>(
      stream: fs.getCanteenOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: _kAccent));
        final all = snapshot.data ?? [];
        final pending = all.where((o) => o.status == 'Pending').toList();
        final preparing = all.where((o) => o.status == 'Preparing').toList();
        final ready = all.where((o) => o.status == 'Ready').toList();

        return Row(
          children: [
            _KanbanColumn(title: 'Pending', color: Colors.orange, orders: pending, nextStatus: 'Preparing', nextLabel: 'Start Preparing'),
            _KanbanColumn(title: 'Preparing', color: Colors.blue, orders: preparing, nextStatus: 'Ready', nextLabel: 'Mark Ready'),
            _KanbanColumn(title: 'Ready 🔔', color: _kGreen, orders: ready, nextStatus: 'Delivered', nextLabel: 'Deliver'),
          ],
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<CanteenOrderModel> orders;
  final String nextStatus;
  final String nextLabel;

  const _KanbanColumn({required this.title, required this.color, required this.orders, required this.nextStatus, required this.nextLabel});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Flexible(child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 4),
                Text('(${orders.length})', style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              itemCount: orders.length,
              itemBuilder: (ctx, i) => _KanbanCard(order: orders[i], color: color, nextStatus: nextStatus, nextLabel: nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final CanteenOrderModel order;
  final Color color;
  final String nextStatus;
  final String nextLabel;

  const _KanbanCard({required this.order, required this.color, required this.nextStatus, required this.nextLabel});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(order.orderTime);
    final elapsedStr = elapsed.inMinutes < 60 ? '${elapsed.inMinutes}m ago' : '${elapsed.inHours}h ago';

    return GestureDetector(
      onTap: () => _showOrderActions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(order.studentName.split(' ').first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                Text(elapsedStr, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            // Show item names preview
            if (order.items.isNotEmpty)
              Text(
                order.items.take(2).map((i) => '${i['quantity']}× ${i['name']}').join(', ') +
                    (order.items.length > 2 ? ' +${order.items.length - 2} more' : ''),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text('₹${order.totalAmount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showOrderActions(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${order.studentName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Time: ${DateFormat.jm().format(order.orderTime)}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            ...order.items.map((i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${i['quantity']}x ${i['name']}', style: const TextStyle(color: Colors.white70)),
                  Text('₹${((i['price'] as num) * (i['quantity'] as num)).toStringAsFixed(0)}', style: const TextStyle(color: _kAccent)),
                ],
              ),
            )),
            const Divider(color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('₹${order.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            if (nextStatus == 'Preparing') ...[
              const Text('Estimated Prep Time', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _PrepTimeSelector(onChanged: (mins) {
                // We'll calculate the ready time based on this
                final readyTime = DateTime.now().add(Duration(minutes: mins));
                fs.updateOrderStatus(order.id, nextStatus, estimatedReadyTime: readyTime);
              }),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                if (order.studentPhone != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone),
                        label: const Text('Call Student'),
                        style: OutlinedButton.styleFrom(foregroundColor: _kAccent, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () {
                          // In a real app, use url_launcher
                        },
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // If we didn't set prep time already (only if next is Preparing)
                      await fs.updateOrderStatus(order.id, nextStatus);
                      
                      if (order.studentFcmToken != null && order.studentFcmToken!.isNotEmpty) {
                        await NotificationService.sendCanteenStatusNotification(
                          fcmToken: order.studentFcmToken!,
                          newStatus: nextStatus,
                          canteenName: order.canteenName ?? 'the canteen',
                        );
                      }
                    },
                    child: Text(nextLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrepTimeSelector extends StatefulWidget {
  final ValueChanged<int> onChanged;
  const _PrepTimeSelector({required this.onChanged});
  @override State<_PrepTimeSelector> createState() => _PrepTimeSelectorState();
}

class _PrepTimeSelectorState extends State<_PrepTimeSelector> {
  int _selected = 15;
  final _options = [5, 10, 15, 20, 30, 45];
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((m) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('$m min'),
            selected: _selected == m,
            onSelected: (val) { if (val) setState(() => _selected = m); widget.onChanged(m); },
            backgroundColor: _kCard,
            selectedColor: _kAccent,
            labelStyle: TextStyle(color: _selected == m ? Colors.black : Colors.white70),
          ),
        )).toList(),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// ANALYTICS TAB
// -----------------------------------------------------------------------
class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: fs.getCanteenAnalytics(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _kAccent));
        final data = snapshot.data!;
        final revenue = data['revenue'] as double;
        final orders = data['orders'] as int;
        final rating = data['avgRating'] as double;
        final itemSales = data['itemSales'] as Map<String, int>;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Performance Overview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatCard(title: 'Total Revenue', value: '₹${revenue.toStringAsFixed(0)}', icon: Icons.payments, color: _kGreen),
                const SizedBox(width: 12),
                _StatCard(title: 'Total Orders', value: '$orders', icon: Icons.shopping_basket, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            _StatCard(title: 'Avg. Rating', value: rating == 0 ? 'No ratings' : '${rating.toStringAsFixed(1)} ★', 
                icon: Icons.star, color: _kAccent, isFullWidth: true),
            const SizedBox(height: 32),
            const Text('Top Selling Items', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ...itemSales.entries.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _kAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.fastfood, color: _kAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Text('${e.value} sold', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isFullWidth;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color, this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.15))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
    return isFullWidth ? body : Expanded(child: body);
  }
}

// -----------------------------------------------------------------------
// CANTEEN PROFILE TAB
// -----------------------------------------------------------------------
class _CanteenProfileTab extends StatefulWidget {
  const _CanteenProfileTab();
  @override State<_CanteenProfileTab> createState() => _CanteenProfileTabState();
}

class _CanteenProfileTabState extends State<_CanteenProfileTab> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _prepCtrl = TextEditingController(text: '15');
  final _openCtrl = TextEditingController(text: '8:00 AM');
  final _closeCtrl = TextEditingController(text: '5:00 PM');
  String? _selectedCollege;
  String _preview = 'Campus Canteen';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<CanteenProfileModel?>(
      stream: fs.getCanteenProfile(),
      builder: (context, snap) {
        final profile = snap.data;
        if (profile != null && _selectedCollege == null) {
          _selectedCollege = profile.college.isNotEmpty ? profile.college : null;
          _nameCtrl.text = profile.adminName;
          _phoneCtrl.text = profile.phone ?? '';
          _prepCtrl.text = profile.defaultPrepTime.toString();
          _openCtrl.text = profile.openTime;
          _closeCtrl.text = profile.closeTime;
          _preview = profile.canteenName;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFFF8C00)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront, color: Colors.white, size: 36),
                    const SizedBox(height: 12),
                    Text(_preview, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${_openCtrl.text} – ${_closeCtrl.text}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('Canteen Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              // College dropdown
              DropdownButtonFormField<String>(
                value: _selectedCollege,
                dropdownColor: _kCard,
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _darkDecoration('Select Your College', Icons.school),
                hint: const Text('Select college...', style: TextStyle(color: Colors.white38)),
                items: KeralaColleges.list.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCollege = val;
                    _preview = val != null ? CanteenProfileModel.deriveCanteenName(val) : 'Campus Canteen';
                  });
                },
              ),
              const SizedBox(height: 16),
              _darkField(_nameCtrl, 'Admin / Staff Name', Icons.person),
              const SizedBox(height: 16),
              _darkField(_phoneCtrl, 'Contact Phone', Icons.phone, isNumber: true),
              const SizedBox(height: 16),
              _darkField(_prepCtrl, 'Default Prep Time (mins)', Icons.timer, isNumber: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _darkField(_openCtrl, 'Opens At', Icons.access_time)),
                  const SizedBox(width: 12),
                  Expanded(child: _darkField(_closeCtrl, 'Closes At', Icons.access_time_filled)),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _kAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _saving ? null : () async {
                    if (_selectedCollege == null) return;
                    setState(() => _saving = true);
                    try {
                      final profile = CanteenProfileModel(
                        id: 'config',
                        college: _selectedCollege!,
                        canteenName: CanteenProfileModel.deriveCanteenName(_selectedCollege!),
                        adminName: _nameCtrl.text,
                        phone: _phoneCtrl.text,
                        defaultPrepTime: int.tryParse(_prepCtrl.text) ?? 15,
                        openTime: _openCtrl.text,
                        closeTime: _closeCtrl.text,
                      );
                      await fs.setCanteenProfile(profile);
                      setState(() { _preview = profile.canteenName; });
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
                    } finally {
                      setState(() => _saving = false);
                    }
                  },
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text('Save Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------
// QR SCANNER FOR ORDER DELIVERY
// -----------------------------------------------------------------------
class _OrderScannerScreen extends StatefulWidget {
  const _OrderScannerScreen();

  @override
  State<_OrderScannerScreen> createState() => _OrderScannerScreenState();
}

class _OrderScannerScreenState extends State<_OrderScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);
      final fs = Provider.of<FirestoreService>(context, listen: false);
      try {
        final orderDoc = await fs.getCanteenOrders().first.then(
          (list) => list.firstWhere((o) => o.id == code, orElse: () => throw Exception('Order not found')));

        if (mounted) {
          showModalBottomSheet(
            context: context, isDismissible: false, enableDrag: false,
            backgroundColor: _kCard,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (ctx) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner, size: 48, color: _kAccent),
                  const SizedBox(height: 12),
                  Text(orderDoc.studentName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('${orderDoc.items.length} items · ₹${orderDoc.totalAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _kOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('Status: ${orderDoc.status}', style: const TextStyle(color: _kOrange, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () { Navigator.pop(ctx); setState(() => _isProcessing = false); },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await fs.updateOrderStatus(code, 'Delivered', studentFcmToken: orderDoc.studentFcmToken);
                            if (orderDoc.studentFcmToken != null) {
                              await NotificationService.sendCanteenStatusNotification(
                                fcmToken: orderDoc.studentFcmToken!,
                                newStatus: 'Delivered',
                                canteenName: orderDoc.canteenName ?? 'the canteen',
                              );
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order marked as Delivered')));
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Deliver', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: Order not found')));
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan Food Token'), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Stack(
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: _kAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 60, left: 0, right: 0,
            child: Text('Align student\'s Food Token QR here', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
