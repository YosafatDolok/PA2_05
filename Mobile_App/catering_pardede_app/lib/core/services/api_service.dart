import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    final response = await http.get(Uri.parse(url), headers: headers);
    return _handleResponse(response);
  }

  static Future<dynamic> post(String url,
      {Map<String, String>? headers, Object? body}) async {
    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error: ${response.statusCode} → ${response.body}');
    }
  }
}
