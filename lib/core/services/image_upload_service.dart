import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ImageUploadService {
  static const String _imgbbApiKey =
      'YOUR_IMGBB_API_KEY'; // Replace with your ImgBB API key
  static const String _imgbbApiUrl = 'https://api.imgbb.com/1/upload';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      // Read file as bytes
      final bytes = await imageFile.readAsBytes();

      // Convert to base64
      final base64Image = base64Encode(bytes);

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(_imgbbApiUrl))
        ..fields['key'] = _imgbbApiKey
        ..fields['image'] = base64Image;

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = json.decode(responseData);

      if (response.statusCode == 200) {
        // Return the direct image URL
        return jsonData['data']['url'];
      } else {
        print('Failed to upload image: ${jsonData['error']}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
