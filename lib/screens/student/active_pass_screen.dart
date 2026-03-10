import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/gate_pass_model.dart';
import '../../models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_constants.dart';

class ActivePassScreen extends StatefulWidget {
  final GatePassModel pass;
  const ActivePassScreen({super.key, required this.pass});

  @override
  State<ActivePassScreen> createState() => _ActivePassScreenState();
}

class _ActivePassScreenState extends State<ActivePassScreen> {
  Timer? _timer;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  Duration _remaining = Duration.zero;
  late DateTime _expiry;

  @override
  void initState() {
    super.initState();
    _expiry = widget.pass.expiryTimestamp ?? DateTime.now().add(const Duration(minutes: 15));
    _startTimer();
    _startClock();
  }

  void _startTimer() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    if (_expiry.isAfter(now)) {
      if (mounted) {
        setState(() {
          _remaining = _expiry.difference(now);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _remaining = Duration.zero;
        });
      }
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<GatePassModel?>(
      stream: fs.getGatePassStream(widget.pass.id),
      builder: (context, passSnapshot) {
        final currentPass = passSnapshot.data ?? widget.pass;
        bool isExpired = _remaining.inSeconds == 0;
        bool isVerified = currentPass.status == AppConstants.statusVerified;

        if (currentPass.expiryTimestamp != null && currentPass.expiryTimestamp != _expiry) {
          _expiry = currentPass.expiryTimestamp!;
        }

        // Fetch latest student profile to ensure photo is ALWAYS up-to-date
        return StreamBuilder<UserModel?>(
          stream: fs.getUserStream(currentPass.studentId),
          builder: (context, userSnapshot) {
            final user = userSnapshot.data;
            final profilePic = user?.profileImageUrl ?? currentPass.profileImageUrl;

            return Scaffold(
              backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF1F5F9),
              appBar: AppBar(
                title: const Text('E-Gate Pass'),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              extendBodyBehindAppBar: true,
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
                  child: Column(
                    children: [
                      // THE TICKET
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            // 1. Ticket Header (Profile & Name)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isVerified 
                                    ? Colors.green.shade600 
                                    : (isExpired ? Colors.red.shade600 : AppTheme.primaryBlue),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: profilePic != null ? NetworkImage(profilePic) : null,
                                      child: profilePic == null ? const Icon(Icons.person, size: 30) : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentPass.studentName,
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        Text(
                                          '${currentPass.semester} ${currentPass.department}',
                                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            currentPass.passType == 'full_day' ? 'FULL DAY' : 'SHORT PASS',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 2. Ticket Body (Destination & Status)
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      _buildInfoItem('DESTINATION', currentPass.destination ?? 'N/A', Icons.location_on_outlined),
                                      _buildInfoItem('STATUS', isVerified ? 'Verified' : (isExpired ? 'Expired' : 'Active'), isVerified ? Icons.verified : Icons.info_outline),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Dashed Divider / Perforation
                                  Row(
                                    children: List.generate(20, (index) => Expanded(
                                      child: Container(
                                        color: index % 2 == 0 ? Colors.transparent : Colors.grey.withOpacity(0.3),
                                        height: 2,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                      ),
                                    )),
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // 3. QR Code Section
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade200, width: 2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: QrImageView(
                                          data: currentPass.id,
                                          version: QrVersions.auto,
                                          size: 180.0,
                                          dataModuleStyle: const QrDataModuleStyle(
                                            dataModuleShape: QrDataModuleShape.square,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          eyeStyle: const QrEyeStyle(
                                            eyeShape: QrEyeShape.square,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                      if (isExpired && !isVerified)
                                        _buildStamp('EXPIRED', Colors.red),
                                      if (isVerified)
                                        _buildStamp('VERIFIED', Colors.green),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // 4. Expiry / Timer
                                  if (!isVerified) ...[
                                    const Text('EXPIRES IN', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDuration(_remaining),
                                      style: TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'monospace',
                                        color: isExpired ? Colors.red : AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('VERIFIED BY SECURITY', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  Text(
                                    'Valid Till: ${currentPass.expiryTimestamp != null ? DateFormat('hh:mm a').format(currentPass.expiryTimestamp!) : 'N/A'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Live Anti-Spoofing Clock
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd MMM | hh:mm:ss a').format(_now),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStamp(String text, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24)
      ),
      width: 200,
      height: 200,
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: -0.2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text, 
            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)
          ),
        ),
      ),
    );
  }
}

