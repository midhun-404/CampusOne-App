import 'dart:convert';
import 'package:http/http.dart' as http;

/// Chat message model for conversation history
class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// AI Service using Arcee AI Trinity Large Preview via OpenRouter
class AiService {
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _apiKey =
      'YOUR_OPENROUTER_API_KEY_HERE';
  static const String _model = 'nvidia/nemotron-3-nano-30b-a3b:free';

  /// System prompt that gives the AI context about CampusOne
  static const String _campusSystemPrompt = '''
You are "CampusOne AI", a helpful assistant built into the CampusOne Smart Gatepass & Campus Management App. 
You help students navigate the app and answer campus-related questions.

Key information about CampusOne:
- Gate Pass System: Students can apply for "Short Pass" (same-day return) or "Full Day Pass" (not returning today).
- Canteen: Students can order food online from the college canteen.
- Profile, ID Card, Notices, History are also available in the app.

Rules:
- Keep responses concise (2-4 sentences max).
- Be friendly and supportive.
- You can use a single emoji at the end of your response to be friendly.

TOOL CAPABILITIES (CRITICAL):
If the user asks you to perform an action on their behalf, you MUST respond with a pure JSON block wrapped in triple backticks. Do not add conversational text if you output a tool JSON.
Supported tools:
1. Apply for a gate pass: If the user wants to apply for a pass, extract the type (Short Pass or Full Day Pass), reason, and destination.
   Output format: ```json\n{"action": "apply_gatepass", "type": "Short Pass", "reason": "going to bank", "destination": "Bank"}\n```
2. Check pass status: If the user asks if their pass is approved or what the status is.
   Output format: ```json\n{"action": "check_status"}\n```
3. Open Canteen/Order Food: If the user wants to order food.
   Output format: ```json\n{"action": "open_canteen"}\n```
''';

  /// Send a chat message and get a response
  /// Pass [conversationHistory] for multi-turn conversations
  static Future<String> chat({
    required String userMessage,
    List<ChatMessage> conversationHistory = const [],
    String? systemPromptOverride,
  }) async {
    try {
      final messages = <Map<String, dynamic>>[
        {
          'role': 'system',
          'content': systemPromptOverride ?? _campusSystemPrompt,
        },
        // Include conversation history
        for (final msg in conversationHistory) msg.toJson(),
        // Current user message
        {'role': 'user', 'content': userMessage},
      ];

      print('AiService: Sending request to $_baseUrl');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://campusone.app',
          'X-Title': 'CampusOne',
          'User-Agent': 'CampusOneApp/1.0.0', // Added User-Agent
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'max_tokens': 300,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      print('AiService: Received response with status code ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content?.trim() ?? 'Sorry, I could not get a response. Please try again.';
      } else {
        print('AiService Error: ${response.statusCode} - ${response.body}');
        return 'Connection error (${response.statusCode}). Please check your internet and try again. If this persists in release mode, check server-side restrictions.';
      }
    } catch (e) {
      print('AiService Exception: $e');
      return 'Unable to connect to AI ($e). Please check your internet connection. 🌐';
    }
  }

  /// Generate a professional gate pass reason based on destination
  static Future<String> suggestPassReason(String destination) async {
    final prompt =
        'I am a college student and I need to leave campus to go to "$destination". '
        'Write ONE professional and concise reason (1 sentence, max 20 words) for my gate pass application. '
        'Write it directly from MY perspective using "I" or "my" (e.g., "I need to attend a medical appointment"). '
        'Just the reason text, no extra commentary or quotes.';

    return await chat(
      userMessage: prompt,
      systemPromptOverride:
          'You are a helpful assistant that writes short, professional gate pass reasons for college students. '
          'You MUST write the reason in the FIRST PERSON perspective (using "I", "me", "my"). '
          'Keep the response to ONE sentence only, no quotes, no extra text.',
    );
  }
}
