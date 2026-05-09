import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_endpoints.dart';
import '../core/storage/local_storage.dart';

class DriverOrderController {
  static Future<List<dynamic>> getMyOrders() async {
    final token = await LocalStorage.getToken();
    final response = await http.get(
      Uri.parse(ApiEndpoints.driverOrders),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal mengambil data pesanan');
    }
  }

  static Future<bool> updateOrderStatus({
    required int orderId,
    required int statusId,
    String? proofImagePath,
  }) async {
    final token = await LocalStorage.getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiEndpoints.driverUpdateStatus(orderId)),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.fields['status_id'] = statusId.toString();

    if (proofImagePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('proof_image', proofImagePath),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return true;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Gagal memperbarui status');
    }
  }
}
