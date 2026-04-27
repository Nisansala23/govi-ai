import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static final String _apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  static final String _apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  static Future<String?> uploadImage(Uint8List imageBytes) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Generate signature
      final signatureString =
          'folder=profile_images&timestamp=$timestamp$_apiSecret';
      final signature = sha1.convert(utf8.encode(signatureString)).toString();

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature
        ..fields['folder'] = 'profile_images'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'profile.jpg',
          ),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['secure_url'] as String;
      }
      return null;
    } catch (e) {
      print('Cloudinary upload error: $e');
      return null;
    }
  }
}
