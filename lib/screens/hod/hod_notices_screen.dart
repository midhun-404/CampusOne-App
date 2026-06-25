import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/notice_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class HodNoticesScreen extends StatefulWidget {
  const HodNoticesScreen({super.key});

  @override
  State<HodNoticesScreen> createState() => _HodNoticesScreenState();
}

class _HodNoticesScreenState extends State<HodNoticesScreen> {
  final _titleCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isSending    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _showAddNoticeDialog() {
    _titleCtrl.clear();
    _contentCtrl.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded, color: AppTheme.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Broadcast Notice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Short descriptive title',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentCtrl,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    hintText: 'Detailed notice message...',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This notice will auto-expire in 24 hours',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSending
                  ? null
                  : () async {
                      final title   = _titleCtrl.text.trim();
                      final content = _contentCtrl.text.trim();
                      if (title.isEmpty || content.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in both title and content')),
                        );
                        return;
                      }

                      setDialogState(() => _isSending = true);

                      try {
                        final auth = Provider.of<AuthService>(context, listen: false);
                        final fs   = Provider.of<FirestoreService>(context, listen: false);

                        final now    = DateTime.now();
                        final expiry = now.add(const Duration(hours: 24));

                        final notice = NoticeModel(
                          id:          '',
                          title:       title,
                          content:     content,
                          authorName:  auth.currentUser?.name ?? 'HOD',
                          timestamp:   now,
                          expiryAt:    expiry,
                        );

                        await fs.addNotice(notice);

                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Notice broadcasted! Expires in 24 hours.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send notice: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        if (mounted) setDialogState(() => _isSending = false);
                      }
                    },
              icon: _isSending
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_isSending ? 'Sending...' : 'Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotice(FirestoreService fs, NoticeModel notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Notice'),
        content: Text('Delete "${notice.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await fs.deleteNotice(notice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notice deleted'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs    = Provider.of<FirestoreService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notice Board'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: _showAddNoticeDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NoticeModel>>(
        stream: fs.getNoticesStream(includeExpired: true), // HOD sees all, including expired
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No notices yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tap + Add to broadcast a notice', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notices.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final notice  = notices[index];
              final expired = notice.isExpired;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: expired
                        ? Colors.red.withOpacity(0.3)
                        : AppTheme.primaryBlue.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notice.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: expired ? Colors.grey : (isDark ? Colors.white : AppTheme.primaryBlue),
                              ),
                            ),
                          ),
                          if (expired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Expired', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deleteNotice(fs, notice),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notice.content,
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(notice.authorName, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          const Spacer(),
                          Icon(Icons.access_time, size: 12, color: expired ? Colors.red.shade300 : Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            notice.expiryAt != null
                                ? 'Expires ${DateFormat('MMM d, h:mm a').format(notice.expiryAt!)}'
                                : DateFormat.yMMMd().format(notice.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: expired ? Colors.red.shade400 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
