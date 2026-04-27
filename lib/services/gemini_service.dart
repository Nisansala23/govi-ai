import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<Map<String, dynamic>> analyzeCropImageBytes(
    Uint8List imageBytes,
  ) async {
    // ✅ Check API key exists
    if (_apiKey.isEmpty) {
      debugPrint('❌ GROQ_API_KEY not found in .env');
      return _errorResult('API key not configured');
    }

    // ✅ Check image size (Groq has limits)
    if (imageBytes.isEmpty) {
      return _errorResult('No image provided');
    }

    try {
      final base64Image = base64Encode(imageBytes);

      debugPrint('📡 Sending image to Groq API...');
      debugPrint('📦 Image size: ${imageBytes.length} bytes');

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text': '''You are an expert agricultural AI assistant 
specializing in Sri Lankan crops (Paddy, Tea, Tomato).

Analyze this crop leaf image carefully and respond ONLY in this 
exact JSON format with no extra text, no markdown, no explanation:

{
  "disease": "disease name or Healthy",
  "confidence": "High/Medium/Low",
  "crop": "detected crop type",
  "description": "brief description of the disease in simple English (2-3 sentences)",
  "sinhala_remedy": "treatment advice in simple colloquial Sinhala (2-3 sentences)",
  "organic_remedy": "organic/traditional treatment suggestion (2-3 steps)",
  "chemical_remedy": "chemical treatment if needed, include product names available in Sri Lanka",
  "severity": "Mild/Moderate/Severe or None if healthy"
}

Important rules:
- If the image is not a crop/plant, set disease to "Not a crop image"
- Always respond in valid JSON only
- Use simple language farmers can understand
- For sinhala_remedy use everyday Sinhala words''',
                    },
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:image/jpeg;base64,$base64Image',
                      },
                    },
                  ],
                },
              ],
              'max_tokens': 1000,
              'temperature': 0.1, // ✅ Low temp = more consistent JSON
            }),
          )
          .timeout(
            const Duration(seconds: 30), // ✅ Timeout after 30s
            onTimeout: () {
              throw Exception('Request timed out. Please try again.');
            },
          );

      debugPrint('📡 Groq API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;

        debugPrint('📝 Raw response: $text');

        // ✅ Clean the response text
        final cleanText = _cleanJsonText(text);

        debugPrint('🧹 Cleaned text: $cleanText');

        // ✅ Parse JSON
        final result = jsonDecode(cleanText) as Map<String, dynamic>;

        // ✅ Validate required fields
        return _validateResult(result);
      } else if (response.statusCode == 429) {
        // Rate limit
        debugPrint('❌ Rate limit hit');
        throw Exception(
          'Too many requests. Please wait a moment and try again.',
        );
      } else if (response.statusCode == 401) {
        // Invalid API key
        debugPrint('❌ Invalid API key');
        throw Exception('Invalid API key. Check your .env file.');
      } else {
        debugPrint('❌ API Error: ${response.body}');
        throw Exception('Analysis failed. Please try again.');
      }
    } on FormatException catch (e) {
      // JSON parse error
      debugPrint('❌ JSON parse error: $e');
      return _errorResult('Could not parse AI response. Please try again.');
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow; // Let the UI handle it
    }
  }

  // ✅ Clean JSON text from API response
  static String _cleanJsonText(String text) {
    String cleaned = text.trim();

    // Remove markdown code blocks
    cleaned = cleaned.replaceAll('```json', '');
    cleaned = cleaned.replaceAll('```JSON', '');
    cleaned = cleaned.replaceAll('```', '');

    // Find JSON object boundaries
    final startIndex = cleaned.indexOf('{');
    final endIndex = cleaned.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      cleaned = cleaned.substring(startIndex, endIndex + 1);
    }

    return cleaned.trim();
  }

  // ✅ Validate and fill missing fields
  static Map<String, dynamic> _validateResult(Map<String, dynamic> result) {
    return {
      'disease': result['disease'] ?? 'Unknown',
      'confidence': result['confidence'] ?? 'Low',
      'crop': result['crop'] ?? 'Unknown',
      'description': result['description'] ?? 'No description available.',
      'sinhala_remedy':
          result['sinhala_remedy'] ?? 'කරුණාකර කෘෂිකර්ම නිලධාරියෙකු හමුවන්න.',
      'organic_remedy':
          result['organic_remedy'] ??
          'Consult your local agricultural officer.',
      'chemical_remedy':
          result['chemical_remedy'] ??
          'Consult your local agricultural officer.',
      'severity': result['severity'] ?? 'None',
    };
  }

  // ✅ Default error result (app won't crash)
  static Map<String, dynamic> _errorResult(String message) {
    return {
      'disease': 'Analysis Failed',
      'confidence': 'Low',
      'crop': 'Unknown',
      'description': message,
      'sinhala_remedy': 'කරුණාකර නැවත උත්සාහ කරන්න.',
      'organic_remedy': 'Please try again.',
      'chemical_remedy': 'Please try again.',
      'severity': 'None',
    };
  }
}
