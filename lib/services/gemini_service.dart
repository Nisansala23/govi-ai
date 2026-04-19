import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<Map<String, dynamic>> analyzeCropImageBytes(
    Uint8List imageBytes,
  ) async {
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
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
                'text':
                    '''You are an expert agricultural AI assistant specializing in Sri Lankan crops.
Analyze this crop leaf image and respond ONLY in this exact JSON format with no extra text:
{
  "disease": "disease name or Healthy",
  "confidence": "High/Medium/Low",
  "crop": "detected crop type",
  "description": "brief description of the disease in simple English",
  "sinhala_remedy": "treatment advice in simple Sinhala",
  "organic_remedy": "organic treatment suggestion",
  "chemical_remedy": "chemical treatment if needed",
  "severity": "Mild/Moderate/Severe or None if healthy"
}''',
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'];
      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(cleanText);
    } else {
      throw Exception('Failed to analyze image: ${response.body}');
    }
  }
}
