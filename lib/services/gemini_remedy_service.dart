import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiRemedyService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<Map<String, dynamic>> getRemedy({
    required String crop,
    required String disease,
  }) async {
    final prompt = '''
You are an agricultural expert for Sri Lanka farmers.

Give detailed treatment recommendations for:

Crop: $crop  
Disease: $disease  

Return ONLY JSON in this format:
{
  "sinhala": "simple Sinhala explanation",
  "organic": "organic treatment steps",
  "chemical": "chemical treatment if needed",
  "dosage": "dosage instructions",
  "shop": "Sri Lankan local agro shops suggestion"
}
''';

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
            'content': prompt,
          }
        ],
        'max_tokens': 800,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'];

      final clean = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(clean);
    } else {
      throw Exception('Failed to load remedy: ${response.body}');
    }
  }
}