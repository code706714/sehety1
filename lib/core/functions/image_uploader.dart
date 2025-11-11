import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<String?> uploadImageToCloudinary(File imageFile) async {
  const cloudName = 'dzawnrqvq';
  const presetName = 'sa7ety';
  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  final request = http.MultipartRequest('POST', url)
    ..fields['upload_preset'] = presetName
    ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  try {
    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString(); // هنا الفارق الحقيقي
    print('📡 Status Code: ${streamedResponse.statusCode}');
    print('📜 Response Body: $responseBody');

    if (streamedResponse.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['secure_url'];
    } else {
      // نطبع الخطأ الحقيقي من Cloudinary
      print('❌ Upload error: ${streamedResponse.statusCode}');
      print('Response: $responseBody');
      return null;
    }
  } catch (e) {
    print('⚠️ Exception while uploading: $e');
    return null;
  }
}

