import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/canteen_model.dart';

// ─── Theme ────────────────────────────────────────────────────────────────────
const _kBg     = Color(0xFFF0F2F8);
const _kDark   = Color(0xFF1A1D2E);
const _kCard   = Color(0xFF252839);

Color _darken(Color c, double amount) => Color.fromARGB(
      c.alpha,
      (c.red * (1 - amount)).round().clamp(0, 255),
      (c.green * (1 - amount)).round().clamp(0, 255),
      (c.blue * (1 - amount)).round().clamp(0, 255),
    );

Color _statusColor(String status) {
  switch (status) {
    case 'Preparing': return const Color(0xFF2196F3);
    case 'Ready':     return const Color(0xFF4CAF50);
    case 'Delivered': return const Color(0xFF78909C);
    default:          return const Color(0xFFFF8C00);
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'Preparing': return Icons.soup_kitchen_rounded;
    case 'Ready':     return Icons.notifications_active_rounded;
    case 'Delivered': return Icons.check_circle_rounded;
    default:          return Icons.access_time_rounded;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'Preparing': return 'Being prepared';
    case 'Ready':     return 'Ready to collect 🔔';
    case 'Delivered': return 'Collected ✅';
    default:          return 'Awaiting confirmation';
  }
}

// ─── Root screen ──────────────────────────────────────────────────────────────
class StudentOrdersScreen extends StatelessWidget {
  const StudentOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs   = Provider.of<FirestoreService>(context);
    final user = Provider.of<AuthService>(context, listen: false).currentUser!;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: _kDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: StreamBuilder<List<CanteenOrderModel>>(
        stream: fs.getStudentOrders(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return _EmptyOrders(onBrowse: () => context.pop());
          }

          final active = orders.where((o) => o.status != 'Delivered').toList();
          final past   = orders.where((o) => o.status == 'Delivered').toList();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              if (active.isNotEmpty) ...[
                _sectionHeader('Active Orders', active.length),
                const SizedBox(height: 12),
                ...active.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _FoodTokenCard(order: o),
                )),
                const SizedBox(height: 8),
              ],
              if (past.isNotEmpty) ...[
                _sectionHeader('Order History', past.length),
                const SizedBox(height: 12),
                ...past.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FoodTokenCard(order: o),
                )),
              ],
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, int count) => Row(
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kDark)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: const Color(0xFFFF8C00).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
        child: Text('$count', style: const TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    ],
  );
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyOrders({required this.onBrowse});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.fastfood_outlined, size: 60, color: Color(0xFFFF8C00)),
        ),
        const SizedBox(height: 24),
        const Text('No orders yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kDark)),
        const SizedBox(height: 8),
        Text('Place your first canteen order!', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: onBrowse,
          icon: const Icon(Icons.restaurant_menu),
          label: const Text('Browse Menu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF8C00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    ),
  );
}

// ─── Premium Food Token Card ──────────────────────────────────────────────────
class _FoodTokenCard extends StatelessWidget {
  final CanteenOrderModel order;
  const _FoodTokenCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final color    = _statusColor(order.status);
    final isActive = order.status != 'Delivered';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isActive ? 0.28 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // ── Ticket header ─────────────────────────────────────────────
              _TicketHeader(order: order, color: color, isActive: isActive),

              // ── Tear-line separator ───────────────────────────────────────
              _TearLine(color: color),

              // ── QR / Delivered body ───────────────────────────────────────
              _TicketBody(order: order, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ticket Header ────────────────────────────────────────────────────────────
class _TicketHeader extends StatelessWidget {
  final CanteenOrderModel order;
  final Color color;
  final bool isActive;
  const _TicketHeader({required this.order, required this.color, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [color.withOpacity(0.92), _darken(color, 0.18)]
              : [const Color(0xFF546E7A), const Color(0xFF37474F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status icon badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                child: Icon(_statusIcon(order.status), color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.canteenName ?? 'Campus Canteen',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -1, height: 1.1),
                    ),
                  ],
                ),
              ),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  order.status.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Items preview
          Text(
            order.items.take(3).map((i) => '${i['quantity']}× ${i['name']}').join(' · ') +
                (order.items.length > 3 ? ' +${order.items.length - 3}' : ''),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Colors.white54, size: 13),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd · h:mm a').format(order.orderTime),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Spacer(),
              if (isActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (order.status == 'Ready')
                        const Icon(Icons.notifications_active, color: Colors.white, size: 12)
                      else
                        const SizedBox(
                          width: 10, height: 10,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
                        ),
                      const SizedBox(width: 5),
                      Text(_statusLabel(order.status), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dashed tear-line ─────────────────────────────────────────────────────────
class _TearLine extends StatelessWidget {
  final Color color;
  const _TearLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _circle(),
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              final dashCount = (c.maxWidth / 8).floor();
              return Row(
                children: List.generate(dashCount, (i) => Expanded(
                  child: Container(height: 1.5, color: i.isEven ? color.withOpacity(0.35) : Colors.transparent),
                )),
              );
            }),
          ),
          _circle(),
        ],
      ),
    );
  }

  Widget _circle() => Container(
    width: 18, height: 18,
    decoration: BoxDecoration(color: _kBg, shape: BoxShape.circle, border: Border.all(color: Colors.transparent)),
  );
}

// ─── Ticket body (QR or Delivered) ────────────────────────────────────────────
class _TicketBody extends StatelessWidget {
  final CanteenOrderModel order;
  final Color color;
  const _TicketBody({required this.order, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: order.status == 'Delivered'
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 22),
                      const SizedBox(width: 8),
                      Text('Order Collected', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              children: [
                const Text(
                  'FOOD TOKEN · SHOW AT COUNTER',
                  style: TextStyle(letterSpacing: 1.8, color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 10),
                ),
                const SizedBox(height: 14),
                order.status == 'Ready'
                    ? _PulsingQR(orderId: order.id, color: color)
                    : _StaticQR(orderId: order.id, color: color),
                const SizedBox(height: 10),
                Text(
                  '#${order.id.substring(math.max(0, order.id.length - 8)).toUpperCase()}',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11, letterSpacing: 1.5, fontFamily: 'monospace'),
                ),
              ],
            ),
    );
  }
}

// ─── Static QR ────────────────────────────────────────────────────────────────
class _StaticQR extends StatelessWidget {
  final String orderId;
  final Color color;
  const _StaticQR({required this.orderId, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16)],
      ),
      child: QrImageView(data: orderId, version: QrVersions.auto, size: 140),
    );
  }
}

// ─── Pulsing QR (when Ready) ──────────────────────────────────────────────────
class _PulsingQR extends StatefulWidget {
  final String orderId;
  final Color color;
  const _PulsingQR({required this.orderId, required this.color});
  @override
  State<_PulsingQR> createState() => _PulsingQRState();
}

class _PulsingQRState extends State<_PulsingQR> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.04).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.color, width: 2.5),
          boxShadow: [
            BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 24, spreadRadius: 2),
          ],
        ),
        child: QrImageView(data: widget.orderId, version: QrVersions.auto, size: 150),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ORDER DETAIL SCREEN (premium redesign)
// ═══════════════════════════════════════════════════════════════════════════════
class OrderDetailScreen extends StatelessWidget {
  final CanteenOrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    const statuses = ['Pending', 'Preparing', 'Ready', 'Delivered'];
    final currentIdx = statuses.indexOf(order.status);
    final color = _statusColor(order.status);

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: _kDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), _darken(color, 0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(_statusIcon(order.status), color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(order.canteenName ?? 'Campus Canteen', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('₹${order.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1, height: 1)),
                  const SizedBox(height: 6),
                  Text(DateFormat('EEEE, MMM dd · h:mm a').format(order.orderTime),
                      style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Status timeline ──────────────────────────────────────────────
            const Text('Order Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kDark)),
            const SizedBox(height: 16),
            _StatusTimeline(statuses: statuses, currentIdx: currentIdx, color: color),

            const SizedBox(height: 28),

            // ── Rating & Feedback (if Delivered) ──────────────────────────────
            if (order.status == 'Delivered') ...[
              const SizedBox(height: 28),
              const Text('How was your meal?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kDark)),
              const SizedBox(height: 12),
              _RatingCard(order: order),
            ],

            // ── Items ────────────────────────────────────────────────────────
            const SizedBox(height: 28),
            const Text('Items Ordered', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kDark)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
              ),
              child: Column(
                children: [
                  ...order.items.map((item) => _ItemRow(item: item)),
                  Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark)),
                        Text('₹${order.totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF2E7D32))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── QR Food Token ──────────────────────────────────────────────
            if (order.status != 'Delivered') ...[
              const SizedBox(height: 28),
              const Text('Food Token', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _kDark)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
                ),
                child: Column(
                  children: [
                    const Text('SHOW THIS AT THE COUNTER',
                        style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 20),
                    order.status == 'Ready'
                        ? _PulsingQR(orderId: order.id, color: color)
                        : _StaticQR(orderId: order.id, color: color),
                    const SizedBox(height: 14),
                    Text('Order #${order.id.substring(math.max(0, order.id.length - 8)).toUpperCase()}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                    if (order.status == 'Ready') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text('Your food is ready! Please collect now.',
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            // Actions
            if (order.status == 'Pending')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, order.id),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),

            if (order.status == 'Delivered')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/student/canteen', extra: order.items),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Order Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('BACK')),
          TextButton(
            onPressed: () async {
              await Provider.of<FirestoreService>(context, listen: false).cancelOrder(orderId);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Cancelled')));
              }
            },
            child: const Text('CANCEL ORDER', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Rating Card Widget ──────────────────────────────────────────────────────
class _RatingCard extends StatefulWidget {
  final CanteenOrderModel order;
  const _RatingCard({required this.order});
  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  double _rating = 0;
  final _feedbackCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.order.rating != null) {
      _rating = widget.order.rating!;
      _feedbackCtrl.text = widget.order.feedback ?? '';
      _submitted = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
              onPressed: _submitted ? null : () => setState(() => _rating = i + 1.0),
              icon: Icon(
                _rating > i ? Icons.star_rounded : Icons.star_outline_rounded,
                color: _rating > i ? const Color(0xFFFFB300) : Colors.grey.shade300,
                size: 32,
              ),
            )),
          ),
          if (!_submitted) ...[
            TextField(
              controller: _feedbackCtrl,
              decoration: InputDecoration(
                hintText: 'Any feedback? (optional)',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating == 0 ? null : () async {
                  await Provider.of<FirestoreService>(context, listen: false)
                      .updateOrderRating(widget.order.id, _rating, _feedbackCtrl.text);
                  setState(() => _submitted = true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Rating'),
              ),
            ),
          ] else ...[
            if (_feedbackCtrl.text.isNotEmpty)
              Text('"${_feedbackCtrl.text}"', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 13)),
            const SizedBox(height: 4),
            const Text('Thank you for your feedback! ❤️', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ─── Status timeline ──────────────────────────────────────────────────────────
class _StatusTimeline extends StatelessWidget {
  final List<String> statuses;
  final int currentIdx;
  final Color color;
  const _StatusTimeline({required this.statuses, required this.currentIdx, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(statuses.length, (i) {
        final done   = i <= currentIdx;
        final active = i == currentIdx;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: active ? 40 : 32,
                      height: active ? 40 : 32,
                      decoration: BoxDecoration(
                        color: done ? color : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: active ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12)] : [],
                      ),
                      child: Center(
                        child: done
                            ? Icon(Icons.check_rounded, color: Colors.white, size: active ? 20 : 16)
                            : Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statuses[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        color: active ? color : (done ? Colors.grey.shade600 : Colors.grey.shade400),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (i < statuses.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 22),
                    color: i < currentIdx ? color.withOpacity(0.5) : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Item row ─────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.fastfood_rounded, color: Colors.orange.shade600, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${item['name']}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: _kDark, fontSize: 14)),
          ),
          Text('×${item['quantity']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(width: 12),
          Text(
            '₹${((item['price'] as num) * (item['quantity'] as num)).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
