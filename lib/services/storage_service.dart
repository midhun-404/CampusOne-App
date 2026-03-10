import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  final String _cloudName = 'dpnlkinit';
  final String _uploadPreset = 'campusone';

  Future<String?> _uploadToCloudinary(File file, String folder) async {
    try {
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final result = json.decode(String.fromCharCodes(responseData));
        return result['secure_url']; // This is the Cloudinary URL
      } else {
        print('Cloudinary upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  Future<String?> uploadProfileImage(String uid, File file) async {
    // We add the uid to the folder to organize, though unsigned uploads generate random names
    return await _uploadToCloudinary(file, 'campusone/profiles');
  }

  Future<String?> uploadCanteenItemImage(String itemId, File file) async {
    return await _uploadToCloudinary(file, 'campusone/canteen_items');
  }
}
