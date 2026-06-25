import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/theme/app_colors.dart';
import '/core/utils/helpers.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(2.437190, 99.157618); // Default to Balige
  bool _isLoading = true;
  bool _isSearching = false;
  String _address = "Pilih lokasi pada peta";
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _stopLoading();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _stopLoading();
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        _mapController.move(_currentCenter, 15.0);
        _reverseGeocode(_currentCenter);
      }
    } catch (e) {
      _stopLoading();
    }
  }

  void _stopLoading() {
    if (mounted) setState(() => _isLoading = false);
  }

  void _onMapMoved(MapCamera position, bool hasGesture) {
    if (hasGesture) {
      _currentCenter = position.center;
      
      // Debounce: Wait 600ms after the map stops moving before searching
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () {
        _reverseGeocode(_currentCenter);
      });
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    if (mounted) setState(() => _isSearching = true);
    
    try {
      // Use a more detailed User-Agent as required by Nominatim policy
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {
        'User-Agent': 'CateringPardedeApp/1.0 (com.catering.pardede.app)'
      });
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _address = data['display_name'] ?? "Alamat tidak ditemukan";
            _isSearching = false;
          });
        }
      } else {
        if (mounted) setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = "Gagal mengambil alamat";
          _isSearching = false;
        });
      }
    }
  }

  bool _isInLakeTobaArea(LatLng point) {
    double latDiff = point.latitude - 2.58;
    double lonDiff = point.longitude - 98.82;
    // Bounding radius 70km from Samosir Island center (0.63^2 = 0.40)
    return (latDiff * latDiff + lonDiff * lonDiff) <= 0.40;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Lokasi Acara", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final LatLng? selectedLocation = await showSearch<LatLng?>(
                context: context,
                delegate: LocationSearchDelegate(),
              );
              if (selectedLocation != null) {
                _mapController.move(selectedLocation, 16.0);
                _reverseGeocode(selectedLocation);
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15.0,
              onPositionChanged: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.catering.pardede.app',
              ),
            ],
          ),
          // Fixed Center Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(Icons.location_on, size: 45, color: AppColors.primary),
            ),
          ),
          // Top Warning Banner
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.amber.shade600),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Batasan: Pengiriman hanya melayani wilayah radius 70 km dari Pulau Samosir.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Info Card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (_isSearching)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      else
                        const Icon(Icons.place, color: Colors.grey, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isSearching ? "Mencari alamat..." : _address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSearching ? null : () {
                        if (!_isInLakeTobaArea(_currentCenter)) {
                          Helpers.showSnackBar(context, "Maaf, wilayah pengiriman terbatas radius 70 km dari Pulau Samosir.");
                          return;
                        }
                        Navigator.pop(context, {
                          'address': _address,
                          'latitude': _currentCenter.latitude,
                          'longitude': _currentCenter.longitude,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("KONFIRMASI LOKASI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      ),
    );
  }
}

class LocationSearchDelegate extends SearchDelegate<LatLng?> {
  @override
  String get searchFieldLabel => 'Cari lokasi...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text("Ketik nama jalan, gedung, atau area"));
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<dynamic>>(
      future: _searchNominatim(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        final results = snapshot.data;
        if (results == null || results.isEmpty) {
          return const Center(child: Text("Lokasi tidak ditemukan"));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final place = results[index];
            final displayName = place['display_name'] ?? '';
            final lat = double.tryParse(place['lat'].toString());
            final lon = double.tryParse(place['lon'].toString());

            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.grey),
              title: Text(displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                if (lat != null && lon != null) {
                  close(context, LatLng(lat, lon));
                }
              },
            );
          },
        );
      },
    );
  }

  Future<List<dynamic>> _searchNominatim(String query) async {
    if (query.isEmpty) return [];
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=id');
      final response = await http.get(url, headers: {
        'User-Agent': 'CateringPardedeApp/1.0 (com.catering.pardede.app)'
      });
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint("Search error: $e");
    }
    return [];
  }
}
