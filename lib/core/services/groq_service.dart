import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api_constants.dart';

// ─── Message Model ────────────────────────────────────────────────────────────
class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

// ─── Groq Service ─────────────────────────────────────────────────────────────
class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // ⚠️ Use a stable Groq model (Updated to latest supported version)
  static const String _model = 'llama-3.1-8b-instant';

  static const String _systemPrompt =
      'You are LearnMate, an expert, encouraging AI Tutor. '
      'CRITICAL: You MUST respond in the SAME LANGUAGE as the user message or topic. '
      'If the user writes in Arabic, your entire response must be in Arabic. '
      'Help students understand complex topics with clear bullet points and step-by-step explanations. '
      'Do not give direct homework answers without explaining the reasoning.';

  final List<ChatMessage> _history = [
    ChatMessage(role: 'system', content: _systemPrompt),
  ];

  // ─── Generic POST ──────────────────────────────────────────────────────────
  Future<String> _post(List<Map<String, dynamic>> messages,
      {double temperature = 0.7, int maxTokens = 1024}) async {
    try {
      final uri = Uri.parse(_baseUrl);
      final body = jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': temperature,
        'max_tokens': maxTokens,
      });

      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (kDebugMode) {
        debugPrint('──── Groq Response ────');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['choices'][0]['message']['content'] as String;
      } else {
        // Return human-readable error from Groq's response
        try {
          final err = jsonDecode(response.body);
          final msg = err['error']?['message'] ?? 'Unknown error';
          return '⚠️ API Error ${response.statusCode}: $msg';
        } catch (_) {
          return '⚠️ Error ${response.statusCode}: ${response.body}';
        }
      }
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Groq Exception: $e');

      // Friendly message based on error type
      final msg = e.toString();
      if (msg.contains('XMLHttpRequest') || msg.contains('CORS')) {
        return '⚠️ CORS Error: Browser blocking. Try disabling web security.';
      } else if (msg.contains('TimeoutException')) {
        return '⚠️ AI Timeout: The generation took too long. Please try again.';
      } else if (msg.contains('SocketException') ||
          msg.contains('Connection refused')) {
        return '⚠️ Connection Error: Please check your internet.';
      }
      return '⚠️ Error: $msg';
    }
  }

  // ─── Chat ──────────────────────────────────────────────────────────────────
  Future<String> sendMessage(String userMessage) async {
    // If the message is short (likely a topic), provide 3 suggestions instead of a full explanation
    final words = userMessage.trim().split(RegExp(r'\s+'));
    final bool isShortTopic = words.length <= 3;

    String finalMessage = userMessage;
    if (isShortTopic) {
      finalMessage = 'The user mentioned: "$userMessage". '
          'Do NOT provide a detailed explanation. Instead, greet them and suggest 3 specific paths '
          'to explore this topic (e.g., 1. Basics, 2. Examples, 3. Study Path). '
          'Always respond in the same language as the user message.';
    }

    _history.add(ChatMessage(role: 'user', content: finalMessage));

    final reply = await _post(
      _history.map((m) => m.toJson()).toList(),
    );

    if (!reply.startsWith('⚠️')) {
      _history.add(ChatMessage(role: 'assistant', content: reply));
    }

    return reply;
  }

  // ─── Mind Map ──────────────────────────────────────────────────────────────
  Future<String> generateMindMap(String topic) async {
    final prompt =
        'Generate a clear, high-level mind map for "$topic" in JSON format only. '
        'The language of the content MUST match the language of the topic ("$topic"). '
        'Output ONLY raw JSON — no markdown, no code fences, no explanation. '
        'Structure: {"name":"Root","children":[{"name":"Branch","children":[{"name":"Leaf","children":[]}]}]}. '
        'Provide 3-5 main branches with a maximum of 2 levels of depth for clarity.';

    return _post(
      [
        {'role': 'system', 'content': 'You are a JSON generator. Output only valid JSON.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.2,
      maxTokens: 2048,
    );
  }

  // ─── Summary ───────────────────────────────────────────────────────────────
  Future<String> generateSummary(String topic) async {
    final prompt =
        'Provide a professional, clear summary of "$topic" with bullet points. '
        'The response MUST be in the same language as the topic ("$topic"). '
        'Format: Start with a 2-3 sentence overview, followed by a "Key Concepts" section with bullet points.';

    return _post([
      {'role': 'user', 'content': prompt},
    ]);
  }

  // ─── Quiz ──────────────────────────────────────────────────────────────────
  Future<String> generateQuiz(String topic, {int count = 5, List<String> types = const ['multiple choice']}) async {
    final typesStr = types.join(', ');
    final prompt =
        'Generate a quiz about "$topic" in JSON format. '
        'The language of the questions and options MUST match the language of the topic ("$topic"). '
        'Question count: $count. '
        'Allowed Question types: $typesStr. '
        'Distribute the questions among the allowed types. '
        'Format: {"questions": [{"question": "text", "options": ["a", "b", "c", "d"], "answer": "correct_option", "type": "type_from_allowed"}]}. '
        'Important: '
        '1. For "multiple choice", provide 4 options. '
        '2. For "true/false", provide 2 options: ["True", "False"] (in topic language). '
        '3. For "fill in the blanks", the answer is the missing word. '
        '4. For "define terms", the answer is the definition. '
        'Provide challenging questions.';

    return _post(
      [
        {'role': 'system', 'content': 'You are a JSON generator. Output only valid JSON.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.2,
      maxTokens: 3000,
    );
  }

  // ─── Flashcards ────────────────────────────────────────────────────────────
  Future<String> generateFlashcards(String topic) async {
    final prompt =
        'Generate 8 flashcards for "$topic" in JSON format. '
        'The language of the cards MUST match the language of the topic ("$topic"). '
        'Format: {"flashcards": [{"front": "Term/Question", "back": "Definition/Answer"}]}.';

    return _post(
      [
        {'role': 'system', 'content': 'You are a JSON generator. Output only valid JSON.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.2,
      maxTokens: 2048,
    );
  }

  // ─── Study Plan ───────────────────────────────────────────────────────────
  Future<String> generateStudyPlan(String topic) async {
    final prompt =
        'Generate a structured 5-day study plan for "$topic" in JSON format. '
        'The language of the content MUST match the language of the topic ("$topic"). '
        'Output ONLY raw JSON — no markdown, no code fences, no explanation. '
        'Structure: {'
        '  "total_duration_estimate": "Estimated total hours",'
        '  "plan": ['
        '    {'
        '      "day": 1,'
        '      "label": "Mon",'
        '      "date": "12",'
        '      "tasks": ['
        '        {"title": "task title", "description": "short description", "time": "09:00 AM", "duration": "45 mins", "module": "Module 1", "priority": "High"}'
        '      ]'
        '    }'
        '  ]'
        '}. '
        'Provide a plan for 5 days with at least 3 tasks per day.';

    return _post(
      [
        {'role': 'system', 'content': 'You are a JSON generator. Output only valid JSON.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.2,
      maxTokens: 2048,
    );
  }

  // ─── Educational Slides ────────────────────────────────────────────────────
  Future<String> generateSlides(String topic, {String? description}) async {
    final prompt =
        'Generate exactly 6 premium educational slides for "$topic" in JSON format only. '
        'The language MUST match the language of the topic ("$topic"). '
        '${description != null && description.isNotEmpty ? "User requirements: $description" : ""} '
        'Each slide must have "title", "layout" (Title|TwoColumn|Timeline|Stats), and "htmlContent". '
        'The "htmlContent" should be high-quality, concise, and professional. '
        'IMPORTANT RULES: '
        '1. KEEP TEXT CONCISE: Use bullet points. Do not overfill slides. '
        '2. Layouts: '
        '   - Title: Use for introductory or conclusion slides. '
        '   - TwoColumn: Perfect for comparing two concepts. '
        '   - Timeline: Use for history, steps, or processes. '
        '   - Stats: Use for data, percentages, or key numbers. '
        '3. CSS Classes (MANDATORY): '
        '   - <h1>Main Title</h1>'
        '   - <p class="subtitle">Brief sub-heading</p>'
        '   - <div class="two-column"><div class="left"><h3>Part 1</h3><ul><li>Point 1</li></ul></div><div class="right"><h3>Part 2</h3><ul><li>Point A</li></ul></div></div>'
        '   - <div class="timeline"><div class="timeline-item"><span class="date">Step 1</span><p>Description...</p></div></div>'
        '   - <div class="stats-grid"><div class="stat-card"><span class="stat-val">Value</span><p class="stat-label">Label</p></div></div>'
        'Design: Minimalist, professional, and clear. Structure your JSON like this: {"slides": [{"title": "...", "layout": "...", "htmlContent": "..."}]}.';

    return _post(
      [
        {'role': 'system', 'content': 'You are a professional educational designer. Output ONLY valid JSON. Content must be concise and visually balanced.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.4,
      maxTokens: 4000,
    );
  }
  // ─── Evaluation ────────────────────────────────────────────────────────────
  Future<String> evaluateAnswers(String topic, List<Map<String, dynamic>> quizResults) async {
    final prompt =
        'Evaluate the user\'s answers for a quiz about "$topic". '
        'For each answer, provide an accuracy score between 0.0 and 1.0 and a brief correction if wrong. '
        'Focus on semantic meaning, especially for definitions. '
        'Data: ${jsonEncode(quizResults)} '
        'Output format: {"evaluations": [{"index": 0, "accuracy": 0.9, "feedback": "Excellent definition", "is_correct": true}]}. '
        'Respond in the same language as the topic.';

    return _post(
      [
        {'role': 'system', 'content': 'You are an expert tutor. Evaluate answers logically, not just by word matching.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.1,
      maxTokens: 2048,
    );
  }

  // ─── Data Table ────────────────────────────────────────────────────────────
  Future<String> generateTable(String topic, {String? description}) async {
    final prompt =
        'Generate a structured data table for "$topic" in Markdown format. '
        'The language MUST match the language of the topic ("$topic"). '
        '${description != null && description.isNotEmpty ? "User requirements: $description" : ""} '
        'Ensure the table is well-organized with clear headers. Provide the table and a short context.';

    return _post([
      {'role': 'user', 'content': prompt},
    ]);
  }

  // ─── AI Podcast Script ────────────────────────────────────────────────────
  Future<String> generatePodcastScript(String topic) async {
    final prompt =
        'Create a fun and engaging AI Podcast script about "$topic". '
        'CRITICAL: The dialogue MUST be a balanced back-and-forth between two hosts: Alex (curious student) and Sarah (expert tutor). '
        'Alex should ask questions and Sarah should explain. '
        'The language MUST match the language of the topic ("$topic"). '
        'RULES: '
        '1. Use ONLY "Alex: " and "Sarah: " as markers. '
        '2. DO NOT use brackets [ ], parentheses ( ), or any special symbols like ** or #. '
        '3. DO NOT include "Narration" or "Scene" markers. '
        '4. Each turn should be 2-3 sentences. '
        '5. Ensure at least 8-10 turns of dialogue. '
        'Format: '
        'Alex: Hello Sarah, today I want to learn about... '
        'Sarah: That is a great topic Alex! Let me explain...';

    return _post([
      {'role': 'system', 'content': 'You are a professional podcast scriptwriter. Output ONLY the dialogue text with names. No extra formatting, no markdown, no brackets.'},
      {'role': 'user', 'content': prompt},
    ], temperature: 0.7, maxTokens: 3000);
  }

  // ─── AI Image Search Query ───────────────────────────────────────────────
  Future<String> generateImageSearchQuery(String topic) async {
    final prompt = 'Translate and extract 1-3 precise English keywords for an image search about this topic: "$topic". '
                  'Output ONLY the keywords separated by spaces. Example: "Solar System", "Artificial Intelligence".';

    try {
      final response = await _post([
        {'role': 'system', 'content': 'You are a professional translator and search specialist. Output keywords ONLY.'},
        {'role': 'user', 'content': prompt},
      ], temperature: 0.3, maxTokens: 50);
      return response.trim().replaceAll('"', '');
    } catch (e) {
      return topic; // Fallback to original if AI fails
    }
  }

  // ─── Video Script ──────────────────────────────────────────────────────────
  Future<String> generateVideoScript(String topic) async {
    final prompt =
        'Create a professional educational video script for "$topic". '
        'The language MUST match the language of the topic ("$topic"). '
        'Structure the script into 4-5 clear scenes. '
        'For each scene use this format: '
        '## Scene Title\n'
        'Narration: [narrator text]\n'
        'Visuals: [what to show on screen]\n'
        'Key Points: [bullet points]\n\n'
        'Make it engaging, educational, and suitable for students.';

    return _post([
      {'role': 'system', 'content': 'You are a professional educational content creator and scriptwriter.'},
      {'role': 'user', 'content': prompt},
    ], temperature: 0.6, maxTokens: 2000);
  }

  // ─── YouTube Video ID Finder ────────────────────────────────────────────────
  Future<String?> findYouTubeVideoId(String topic) async {
    final prompt = 
      'Task: Find a PROFESSIONAL EDUCATIONAL YouTube video about "$topic". '
      'Priority Channels: TED-Ed, CrashCourse, Khan Academy, National Geographic, or MIT. '
      'CRITICAL: Return ONLY the 11-character YouTube video ID. '
      'NO MUSIC VIDEOS. NO MEMES. NO INTRO. NO QUOTES. '
      'If you are unsure of a specific video, return "j7w2Gv7ueOc" (a high-quality general educational video about the brain/learning).';

    final result = await _post([
      {'role': 'system', 'content': 'You are an Educational Video Indexer. Output ONLY the 11-character YouTube ID for an academic/educational video.'},
      {'role': 'user', 'content': prompt},
    ], temperature: 0.1, maxTokens: 20);

    if (result.contains('⚠️') || result.length > 20) return null;
    final id = result.trim().replaceAll('"', '').replaceAll("'", "").replaceAll(' ', '');
    
    // Safety check: if it returned a known music video ID (like RickRoll or Gangnam Style), discard it.
    if (id == 'dQw4w9WgXcQ' || id == '9bZkp7q19f0') return "j7w2Gv7ueOc";
    
    return id;
  }

  // ─── Memory Game ───────────────────────────────────────────────────────────
  Future<String> generateMemoryGame(String topic) async {
    final prompt =
        'Design a "Memory Match" game for "$topic". '
        'Extract 5 essential terms and their very short, simple definitions. '
        'Return ONLY raw JSON — no markdown, no explanation. '
        'JSON Structure: '
        '{'
        '  "game_message": "A short encouraging message in the same language as the topic",'
        '  "pairs": ['
        '    {"term": "term 1", "definition": "definition 1"},'
        '    {"term": "term 2", "definition": "definition 2"},'
        '    {"term": "term 3", "definition": "definition 3"},'
        '    {"term": "term 4", "definition": "definition 4"},'
        '    {"term": "term 5", "definition": "definition 5"}'
        '  ]'
        '}';

    return _post(
      [
        {'role': 'system', 'content': 'You are a JSON generator. Output only valid JSON. Terms and definitions must be in the same language as the topic.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.2,
      maxTokens: 2048,
    );
  }

  // ─── Quiz Game ─────────────────────────────────────────────────────────────
  Future<String> generateQuizGame(String topic) async {
    final prompt =
        'Create a fun 5-question "Quiz Challenge" for "$topic". '
        'For each question, provide 4 options and the index of the correct answer (0-3). '
        'Return ONLY raw JSON — no markdown, no explanation. '
        'JSON Structure: '
        '{'
        '  "quiz_message": "An encouraging message in the same language as the topic",'
        '  "questions": ['
        '    {"question": "Q1 text", "options": ["Op1", "Op2", "Op3", "Op4"], "correct_index": 0},'
        '    {"question": "Q2 text", "options": ["Op1", "Op2", "Op3", "Op4"], "correct_index": 1}'
        '  ]'
        '}';

    return _post(
      [
        {'role': 'system', 'content': 'You are a JSON generator. Output only valid JSON. Content must be in the same language as the topic.'},
        {'role': 'user', 'content': prompt},
      ],
      temperature: 0.3,
      maxTokens: 3000,
    );
  }

  // ─── Translation (Internal) ───────────────────────────────────────────────
  Future<String> translateToEnglish(String text) async {
    final prompt = 'Translate the following topic to English for a search engine. Output ONLY the translated words, nothing else: "$text"';
    final result = await _post([
      {'role': 'system', 'content': 'You are a translation tool. Output only the English translation of the user input. No quotes, no intro, no explanation.'},
      {'role': 'user', 'content': prompt},
    ], temperature: 0.1, maxTokens: 100);
    
    if (result.contains('⚠️')) return text; // Fallback to original
    return result.trim().replaceAll('"', '').replaceAll('.', '');
  }
}
