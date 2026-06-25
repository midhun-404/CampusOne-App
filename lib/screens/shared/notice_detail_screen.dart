import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notice_model.dart';
import '../../core/theme/app_theme.dart';

class NoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;
  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(notice.title, style: const TextStyle(shadows: [Shadow(blurRadius: 10, color: Colors.black26)])),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF3E5B9E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(Icons.campaign, size: 80, color: Colors.white.withOpacity(0.2)),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notice.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Posted on ${DateFormat('MMM dd, yyyy • hh:mm a').format(notice.timestamp)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Content',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notice.content,
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
