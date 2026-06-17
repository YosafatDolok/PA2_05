import 'package:http/http.dart' as http;
import 'dart:convert';
import '/core/storage/local_storage.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final token = await LocalStorage.getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> get(String url, {Map<String, String>? queryParameters}) async {
    Uri uri = Uri.parse(url);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParameters);
    }
    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    return _handleResponse(response, url);
  }

  static Future<dynamic> post(String url, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response, url);
  }

  static Future<dynamic> patch(String url, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    return _handleResponse(response, url);
  }

  static Future<dynamic> delete(String url, {Map<String, dynamic>? body}) async {
    final response = await http.delete(
      Uri.parse(url),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );

    return _handleResponse(response, url);
  }

  static Future<dynamic> postMultipart(String url, Map<String, String> fields, {String? filePath, String fileField = 'profile_picture'}) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(await _headers());
    
    // Tambahkan bidang teks
    request.fields.addAll(fields);
    
    // Tambahkan gambar jika disediakan
    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _handleResponse(response, url);
  }

  static dynamic _handleResponse(http.Response response, String url) {
    final data = jsonDecode(response.body);

    // Tangani error 401 secara cerdas
    if (response.statusCode == 401) {
      // Jika BUKAN upaya login atau registrasi, hapus token dan kedaluwarsa sesi
      if (!url.contains('/login') && !url.contains('/register')) {
        LocalStorage.clearToken();
        throw Exception('Session expired');
      }
      // Jika MERUPAKAN upaya login/registrasi, biarkan pesan kesalahan kredensial diteruskan
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Request failed');
    }
  }
}