import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FarmerChatService {
  static final String _geminiKey =
      dotenv.env['GEMINI_API_KEY'] ?? '';

  static final String _groqKey =
      dotenv.env['GROQ_API_KEY'] ?? '';

  static final String _geminiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent";

  static final String _groqUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  // 🔥 MAIN METHOD (WITH FALLBACK)
  static Future<String> ask(String message) async {
    try {
      return await _geminiCall(message);
    } catch (e) {
      print("❌ Gemini failed: $e");

      // fallback only for API issues
      if (e.toString().contains('429') ||
          e.toString().contains('404') ||
          e.toString().contains('API')) {
        print("🔄 Switching to GROQ...");
        return await _groqCall(message);
      }

      rethrow;
    }
  }

  // 🤖 GEMINI CALL
  static Future<String> _geminiCall(String message) async {
    if (_geminiKey.isEmpty) {
      throw Exception("Gemini API key missing");
    }

    final response = await http.post(
      Uri.parse("$_geminiUrl?key=$_geminiKey"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": """
You are an expert agriculture assistant for Sri Lankan farmers.

Rules:
- Use simple English or simple Sinhala
- Give practical farming advice
- Keep answers short
- Focus on rice, tea, coconut, vegetables

User question:
$message
"""
              }
            ]
          }
        ]
      }),
    );

    print("🌐 GEMINI STATUS: ${response.statusCode}");
    print("🌐 GEMINI BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Gemini API Error: ${response.body}");
    }

    final data = jsonDecode(response.body);

    return data["candidates"][0]["content"]["parts"][0]["text"];
  }

  // ⚡ GROQ FALLBACK
  static Future<String> _groqCall(String message) async {
    if (_groqKey.isEmpty) {
      throw Exception("Groq API key missing");
    }

    final response = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_groqKey",
      },
    body: jsonEncode({
  "model": "llama-3.3-70b-versatile",
  "messages": [
    {
      "role": "user",
      "content": """
You are an agriculture assistant for Sri Lanka.

Answer clearly and simply.

$message
"""
    }
  ]
}),
    );

    print("⚡ GROQ STATUS: ${response.statusCode}");
    print("⚡ GROQ BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Groq API Error: ${response.body}");
    }

    final data = jsonDecode(response.body);

    return data["choices"][0]["message"]["content"];
  }
}