import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../models/gate_pass_model.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../core/theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  static const List<String> _quickReplies = [
    'How do I apply for a gate pass?',
    'What is a Short Pass?',
    'How do I order from canteen?',
    'Where can I see my pass status?',
  ];

  @override
  void initState() {
    super.initState();
    // Initial greeting
    final auth = Provider.of<AuthService>(context, listen: false);
    final name = auth.currentUser?.name.split(' ').first ?? 'there';
    _messages.add(ChatMessage(
      role: 'assistant',
      content:
          'Hi $name! 👋 I\'m your CampusOne AI assistant. I can help you with gate passes, canteen orders, and anything else about the app. What do you need?',
    ));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _textCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: trimmed));
      _isTyping = true;
    });
    _scrollToBottom();

    // Build conversation history (exclude greeting, max 10 messages for context)
    final historyCap = _messages.length > 11 ? _messages.length - 11 : 0;
    final history = _messages.skip(1).take(_messages.length - 1 - 1).skip(historyCap).toList();

    final reply = await AiService.chat(
      userMessage: trimmed,
      conversationHistory: history,
    );

    if (!mounted) return;

    String finalReplyText = reply;
    
    // Try to extract JSON block
    String jsonStr = '';
    final match = RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true).firstMatch(reply);
    if (match != null) {
      jsonStr = match.group(1) ?? '';
    } else if (reply.trim().startsWith('{') && reply.trim().endsWith('}')) {
      jsonStr = reply.trim();
    }

    if (jsonStr.isNotEmpty) {
      try {
        final actionData = jsonDecode(jsonStr);
        finalReplyText = await _handleAiAction(actionData);
      } catch (e) {
        print('Failed to parse AI action: $e');
        finalReplyText = "I encountered an error trying to perform that action.";
      }
    }

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: finalReplyText));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _handleAiAction(Map<String, dynamic> actionData) async {
    final action = actionData['action'];
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final user = auth.currentUser;

    if (user == null) return "You must be logged in to do that.";

    if (action == 'apply_gatepass') {
      final type = actionData['type'] ?? 'Short Pass';
      final reason = actionData['reason'] ?? 'Personal';
      final destination = actionData['destination'] ?? 'Outside';
      
      final pass = GatePassModel(
        id: '',
        studentId: user.id,
        studentName: user.name,
        department: user.department ?? 'Unknown',
        semester: user.semester?.toString(),
        division: user.division,
        passType: type == 'Short Pass' ? AppConstants.passTypeShort : AppConstants.passTypeFullDay,
        reason: reason,
        destination: destination,
        status: AppConstants.statusPendingMentor,
        appliedAt: DateTime.now(),
      );
      
      await firestore.createGatePass(pass);
      return "I have successfully applied for your \$type to \$destination! Your mentor has been notified. ✅";
    } 
    else if (action == 'check_status') {
      final passes = await firestore.getStudentActivePasses(user.id);
      if (passes.isEmpty) {
        return "You don't have any active gate passes at the moment.";
      }
      // Sort by newest first just in case
      passes.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      final latest = passes.first;
      return "You have a \${latest.passType} applied on \${latest.appliedAt.day}/\${latest.appliedAt.month} that is currently: **\${latest.status}**.";
    }
    else if (action == 'open_canteen') {
      context.push('/student/canteen');
      return "I'm opening the canteen for you now! 🍔";
    }

    return "Action completed successfully.";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : const Color(0xFFF0F4F8);
    final surfaceColor = isDark ? AppTheme.darkSurface : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CampusOne AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Powered by NVIDIA Nemotron',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _TypingBubble(surfaceColor: surfaceColor);
                }
                final msg = _messages[index];
                return _ChatBubble(
                  message: msg,
                  surfaceColor: surfaceColor,
                  isDark: isDark,
                );
              },
            ),
          ),

          // Quick Replies (only show at start)
          if (_messages.length <= 2 && !_isTyping)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(
                    _quickReplies[index],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white : AppTheme.primaryBlue,
                    ),
                  ),
                  backgroundColor: isDark
                      ? AppTheme.primaryBlue.withOpacity(0.3)
                      : AppTheme.primaryBlue.withOpacity(0.08),
                  side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
                  onPressed: () => _sendMessage(_quickReplies[index]),
                ),
              ),
            ),

          if (_messages.length <= 2 && !_isTyping) const SizedBox(height: 8),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    onSubmitted: _sendMessage,
                    textInputAction: TextInputAction.send,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendMessage(_textCtrl.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _isTyping
                          ? null
                          : const LinearGradient(
                              colors: [AppTheme.primaryBlue, Color(0xFF3A5A9F)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: _isTyping ? Colors.grey.shade300 : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _isTyping ? Colors.grey : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Color surfaceColor;
  final bool isDark;

  const _ChatBubble({
    required this.message,
    required this.surfaceColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, Color(0xFF3A5A9F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryBlue : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF1A1F20)),
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final Color surfaceColor;
  const _TypingBubble({required this.surfaceColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, Color(0xFF3A5A9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i / 3.0;
            final value = (((_controller.value + delay) % 1.0) * 2 * 3.14159);
            final opacity = (0.5 + 0.5 * (1.0 + (value).clamp(-1.0, 1.0))).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
