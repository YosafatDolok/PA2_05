import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';
import '../storage/local_storage.dart';

class LocationService {
  static Timer? _timer;
  static bool get isTracking => _timer != null;

  static Future<void> startTracking() async {
    // 1. Check Permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. Start Periodic Ping (Every 60 seconds)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final token = await LocalStorage.getToken();
        await http.post(
          Uri.parse(ApiEndpoints.driverLocation),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: {
            'latitude': position.latitude.toString(),
            'longitude': position.longitude.toString(),
          },
        );
        print('GPS PING: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('GPS Error: $e');
      }
    });
  }

  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
    print('GPS TRACKING STOPPED');
  }
}
