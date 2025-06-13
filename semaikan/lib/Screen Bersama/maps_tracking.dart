import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:semaikan/screen 2 user/distribusi.dart';

class MapsTrackingPage extends StatefulWidget {
  final String userUid;
  final String documentId;
  final String judulLaporan;

  const MapsTrackingPage({
    super.key,
    required this.userUid,
    required this.documentId,
    required this.judulLaporan,
  });

  @override
  State<MapsTrackingPage> createState() => _MapsTrackingPageState();
}

class _MapsTrackingPageState extends State<MapsTrackingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();

  bool _isLoading = true;
  String _errorMessage = '';

  // Data tracking
  String _progress = '';
  String _tanggalDistribusi = '';
  String _sourceLocationName = '';
  String _sourceRegionName = '';
  String _namaPenerima = '';
  LatLng? _sourceLocation;
  LatLng? _destinationLocation;
  LatLng? _truckLocation;
  List<LatLng> _routePoints = [];
  List<LatLng> _completedRoutePoints = [];
  List<LatLng> _remainingRoutePoints = [];
  List<TrackingStep> _trackingSteps = [];
  double _totalDistance = 0.0;
  double _completedDistance = 0.0;

  // Static caching untuk route data
  static final Map<String, List<LatLng>> _routeCache = {};
  static final Map<String, double> _distanceCache = {};
  static DateTime _lastApiCall = DateTime(2000);
  static const Duration _apiCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  // Load data tracking dari Firestore
  Future<void> _loadTrackingData() async {
    try {
      DocumentSnapshot pengajuanDoc =
          await _firestore
              .collection('Account_Storage')
              .doc(widget.userUid)
              .collection('Data_Pengajuan')
              .doc(widget.documentId)
              .get();

      if (!pengajuanDoc.exists) {
        setState(() {
          _errorMessage = 'Data pengajuan tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> pengajuanData =
          pengajuanDoc.data() as Map<String, dynamic>;

      _progress = pengajuanData['progress']?.toString() ?? '';
      _namaPenerima = pengajuanData['nama_penerima']?.toString() ?? '';

      String? destinationDMS;
      if (pengajuanData['lokasi_distribusi'] is Map) {
        destinationDMS =
            pengajuanData['lokasi_distribusi']['koordinat']?.toString();
      }

      if (destinationDMS == null || destinationDMS.isEmpty) {
        setState(() {
          _errorMessage = 'Koordinat destinasi tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      _destinationLocation = _parseDMSCoordinate(destinationDMS);

      if (_destinationLocation == null) {
        setState(() {
          _errorMessage = 'Format koordinat destinasi tidak valid';
          _isLoading = false;
        });
        return;
      }

      DocumentSnapshot sumberDoc =
          await _firestore
              .collection('System_Data')
              .doc('distribusi_sumber')
              .get();

      if (!sumberDoc.exists) {
        setState(() {
          _errorMessage = 'Data sumber distribusi tidak ditemukan';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> sumberData =
          sumberDoc.data() as Map<String, dynamic>;

      var nearestSourceResult = _findNearestSource(
        sumberData,
        _destinationLocation!,
      );
      _sourceLocation = nearestSourceResult['location'];
      _sourceLocationName = nearestSourceResult['name'];
      _sourceRegionName = nearestSourceResult['region'];

      if (_sourceLocation == null) {
        setState(() {
          _errorMessage = 'Tidak dapat menentukan titik sumber';
          _isLoading = false;
        });
        return;
      }

      // Generate route menggunakan OpenRouteService dan GraphHopper
      await _generateRoutePointsWithAdvancedAPI();

      _generateTrackingSteps(pengajuanData);

      setState(() {
        _isLoading = false;
      });

      _fitMapToRoute();
    } catch (e) {
      print('Error loading tracking data: $e');
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Parse koordinat DMS ke LatLng
  LatLng? _parseDMSCoordinate(String dmsString) {
    try {
      List<String> parts = dmsString.split(' ');
      if (parts.length != 2) return null;

      String latPart = parts[0];
      String lngPart = parts[1];

      double lat = _parseDMSPart(latPart);
      if (latPart.contains('S')) lat = -lat;

      double lng = _parseDMSPart(lngPart);
      if (lngPart.contains('W')) lng = -lng;

      return LatLng(lat, lng);
    } catch (e) {
      print('Error parsing DMS: $e');
      return null;
    }
  }

  double _parseDMSPart(String dmsPart) {
    String cleaned = dmsPart.replaceAll(RegExp(r'[NSEW]'), '');
    List<String> parts = cleaned.split('°');
    double degrees = double.parse(parts[0]);

    String minuteSecond = parts[1];
    List<String> minSec = minuteSecond.split("'");
    double minutes = double.parse(minSec[0]);

    String secondPart = minSec[1].replaceAll('"', '');
    double seconds = double.parse(secondPart);

    return degrees + (minutes / 60) + (seconds / 3600);
  }

  Map<String, dynamic> _findNearestSource(
    Map<String, dynamic> sumberData,
    LatLng destination,
  ) {
    double minDistance = double.infinity;
    LatLng? nearestSource;
    String nearestSourceName = '';
    String nearestRegionName = '';

    sumberData.forEach((key, value) {
      if (value is String && value.contains(',')) {
        LatLng? sourcePoint = _parseDecimalCoordinate(value);
        if (sourcePoint != null) {
          double distance = Geolocator.distanceBetween(
            destination.latitude,
            destination.longitude,
            sourcePoint.latitude,
            sourcePoint.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            nearestSource = sourcePoint;
            nearestSourceName = key.replaceAll('_', ' ');
            nearestRegionName = key;
          }
        }
      }
    });

    return {
      'location': nearestSource,
      'name': nearestSourceName,
      'region': nearestRegionName,
    };
  }

  LatLng? _parseDecimalCoordinate(String coordString) {
    try {
      List<String> parts = coordString.split(',');
      if (parts.length != 2) return null;

      double lat = double.parse(parts[0].trim());
      double lng = double.parse(parts[1].trim());

      return LatLng(lat, lng);
    } catch (e) {
      print('Error parsing decimal coordinate: $e');
      return null;
    }
  }

  // Generate cache key untuk route
  String _generateRouteKey(LatLng start, LatLng end) {
    // Round koordinat untuk mengurangi cache variations
    double startLat = (start.latitude * 1000).round() / 1000;
    double startLng = (start.longitude * 1000).round() / 1000;
    double endLat = (end.latitude * 1000).round() / 1000;
    double endLng = (end.longitude * 1000).round() / 1000;

    return '${startLat}_${startLng}_${endLat}_${endLng}';
  }

  // Check apakah masih dalam cooldown period
  bool _isInCooldown() {
    DateTime now = DateTime.now();
    return now.difference(_lastApiCall) < _apiCooldown;
  }

  // Wait sampai cooldown selesai
  Future<void> _waitForCooldown() async {
    if (_isInCooldown()) {
      DateTime now = DateTime.now();
      Duration remaining = _apiCooldown - now.difference(_lastApiCall);
      print('⏳ API Cooldown: waiting ${remaining.inSeconds} seconds...');
      await Future.delayed(remaining);
    }
    _lastApiCall = DateTime.now();
  }

  // Improved routing dengan caching dan rate limiting
  Future<List<LatLng>> _getAdvancedRouting(LatLng start, LatLng end) async {
    String cacheKey = _generateRouteKey(start, end);

    // Check cache terlebih dahulu
    if (_routeCache.containsKey(cacheKey)) {
      print('✅ Using cached route for $cacheKey');
      if (_distanceCache.containsKey(cacheKey)) {
        _totalDistance = _distanceCache[cacheKey]!;
      }
      return _routeCache[cacheKey]!;
    }

    // Wait untuk cooldown jika perlu
    await _waitForCooldown();

    // Try OpenRouteService first dengan rate limiting protection
    List<LatLng> route = await _getOpenRouteServiceRouting(start, end);
    if (route.isNotEmpty) {
      print(
        '✅ OpenRouteService routing successful with ${route.length} points',
      );
      _routeCache[cacheKey] = route;
      _distanceCache[cacheKey] = _totalDistance;
      return route;
    }

    // Wait lagi sebelum mencoba GraphHopper
    await Future.delayed(const Duration(milliseconds: 500));

    // Fallback to GraphHopper dengan protection
    route = await _getGraphHopperRouting(start, end);
    if (route.isNotEmpty) {
      print('✅ GraphHopper routing successful with ${route.length} points');
      _routeCache[cacheKey] = route;
      _distanceCache[cacheKey] = _totalDistance;
      return route;
    }

    // Last fallback to improved waypoint generation
    print('⚠️  Using fallback routing - API services unavailable');
    route = _generateImprovedWaypoints(start, end);
    _routeCache[cacheKey] = route;
    return route;
  }

  // OpenRouteService routing dengan enhanced error handling
  Future<List<LatLng>> _getOpenRouteServiceRouting(
    LatLng start,
    LatLng end,
  ) async {
    try {
      String apiKey =
          '5b3ce3597851110001cf62483b0dbdf50a1b48f9abb51182162da39c';

      final url = Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey',
      );

      final requestBody = {
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude],
        ],
        'format': 'geojson',
        'geometry_simplify': false,
        'instructions': false,
        'radiuses': [-1, -1],
        'preference': 'recommended',
        'units': 'm',
      };

      print('📡 Calling OpenRouteService API');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'SemaiKan-App/1.0',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 8)); // Reduced timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['features'] != null && (data['features'] as List).isNotEmpty) {
          final feature = data['features'][0];
          final coordinates = feature['geometry']['coordinates'] as List;

          if (feature['properties'] != null &&
              feature['properties']['segments'] != null) {
            final segments = feature['properties']['segments'] as List;
            if (segments.isNotEmpty && segments[0]['distance'] != null) {
              _totalDistance = (segments[0]['distance'] as num).toDouble();
            }
          }

          List<LatLng> routePoints =
              coordinates.map((coord) {
                return LatLng(coord[1].toDouble(), coord[0].toDouble());
              }).toList();

          return _interpolateRoute(routePoints);
        }
      } else if (response.statusCode == 429) {
        print(
          '⚠️  OpenRouteService Rate Limit (429) - switching to fallback immediately',
        );
        return []; // Return empty untuk trigger fallback
      } else {
        print('❌ OpenRouteService API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ OpenRouteService routing failed: $e');
    }
    return [];
  }

  // GraphHopper routing dengan enhanced error handling
  Future<List<LatLng>> _getGraphHopperRouting(LatLng start, LatLng end) async {
    try {
      String apiKey = '77bac71c-ab2e-417f-9ad3-35cf366b9f15';

      String url =
          'https://graphhopper.com/api/1/route?'
          'point=${start.latitude},${start.longitude}&'
          'point=${end.latitude},${end.longitude}&'
          'vehicle=car&'
          'locale=id&'
          'calc_points=true&'
          'debug=false&'
          'elevation=false&'
          'points_encoded=false&'
          'type=json&'
          'instructions=false&'
          'optimize=true&'
          'key=$apiKey';

      print('📡 Calling GraphHopper API');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'SemaiKan-App/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8)); // Reduced timeout

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['paths'] != null && (data['paths'] as List).isNotEmpty) {
          final path = data['paths'][0];

          if (path['distance'] != null) {
            _totalDistance = (path['distance'] as num).toDouble();
          }

          final points = path['points']['coordinates'] as List;

          List<LatLng> routePoints =
              points.map((coord) {
                return LatLng(coord[1].toDouble(), coord[0].toDouble());
              }).toList();

          return _interpolateRoute(routePoints);
        }
      } else if (response.statusCode == 429) {
        print('⚠️  GraphHopper Rate Limit (429) - using fallback');
        return []; // Return empty untuk trigger fallback
      } else {
        print('❌ GraphHopper API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ GraphHopper routing failed: $e');
    }
    return [];
  }

  // Interpolate route for smoother visualization
  List<LatLng> _interpolateRoute(List<LatLng> originalPoints) {
    if (originalPoints.length < 2) return originalPoints;

    List<LatLng> interpolatedPoints = [];

    for (int i = 0; i < originalPoints.length - 1; i++) {
      LatLng start = originalPoints[i];
      LatLng end = originalPoints[i + 1];

      interpolatedPoints.add(start);

      double distance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );

      if (distance > 1000) {
        int numIntermediate = (distance / 1000).ceil();
        for (int j = 1; j < numIntermediate; j++) {
          double t = j / numIntermediate;
          double lat = start.latitude + (end.latitude - start.latitude) * t;
          double lng = start.longitude + (end.longitude - start.longitude) * t;
          interpolatedPoints.add(LatLng(lat, lng));
        }
      }
    }

    interpolatedPoints.add(originalPoints.last);
    return interpolatedPoints;
  }

  // Static method untuk clear cache jika diperlukan
  static void clearRouteCache() {
    _routeCache.clear();
    _distanceCache.clear();
    print('🗑️  Route cache cleared');
  }

  // Static method untuk get cache info
  static String getCacheInfo() {
    return 'Cache: ${_routeCache.length} routes, Last API call: ${_lastApiCall}';
  }

  // Enhanced fallback waypoint generation dengan estimasi distance yang lebih baik
  List<LatLng> _generateImprovedWaypoints(LatLng start, LatLng end) {
    List<LatLng> waypoints = [];

    double distance = Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );

    // Set _totalDistance untuk fallback
    _totalDistance = distance;

    int numPoints = math.max(20, (distance / 1000 * 5).round());

    for (int i = 0; i <= numPoints; i++) {
      double t = i / numPoints;
      double smoothT = t * t * (3.0 - 2.0 * t);

      double lat = start.latitude + (end.latitude - start.latitude) * smoothT;
      double lng =
          start.longitude + (end.longitude - start.longitude) * smoothT;

      if (i > 0 && i < numPoints) {
        double roadVariation =
            0.002 * math.sin(t * math.pi * 4) * math.cos(t * math.pi * 2);

        double terrainFactor = 1.0;
        if (distance > 50000) terrainFactor = 1.5;

        lat += roadVariation * terrainFactor;
        lng += roadVariation * terrainFactor * 0.8;
      }

      waypoints.add(LatLng(lat, lng));
    }

    print(
      '📍 Generated ${waypoints.length} fallback waypoints (${(_totalDistance / 1000).toStringAsFixed(1)} km)',
    );
    return waypoints;
  }

  // Generate route points dengan advanced API dan caching
  Future<void> _generateRoutePointsWithAdvancedAPI() async {
    if (_sourceLocation != null && _destinationLocation != null) {
      print('🗺️  Generating route: ${getCacheInfo()}');

      _routePoints = await _getAdvancedRouting(
        _sourceLocation!,
        _destinationLocation!,
      );

      print(
        '✅ Route generated: ${_routePoints.length} points, ${(_totalDistance / 1000).toStringAsFixed(1)} km',
      );

      // Update logic untuk semua progress states
      switch (_progress.toLowerCase()) {
        case 'dikirim':
          double progressPercentage = _calculateProgressPercentage();
          int completedIndex =
              (_routePoints.length * progressPercentage).floor();

          _completedRoutePoints = _routePoints.sublist(0, completedIndex + 1);
          _remainingRoutePoints = _routePoints.sublist(completedIndex);

          if (completedIndex < _routePoints.length) {
            _truckLocation = _routePoints[completedIndex];
            _completedDistance = _totalDistance * progressPercentage;
          }
          break;

        case 'selesai':
          _completedRoutePoints = _routePoints;
          _remainingRoutePoints = [];
          _truckLocation = null;
          _completedDistance = _totalDistance;
          break;

        case 'gagal':
          // Untuk status gagal, tampilkan route sebagian dengan marker error
          double failedProgressPercentage = 0.7; // Assume failed at 70%
          int failedIndex =
              (_routePoints.length * failedProgressPercentage).floor();

          _completedRoutePoints = _routePoints.sublist(0, failedIndex + 1);
          _remainingRoutePoints = _routePoints.sublist(failedIndex);
          _truckLocation =
              _routePoints[failedIndex]; // Show truck at failed position
          _completedDistance = _totalDistance * failedProgressPercentage;
          break;

        default:
          // Untuk 'menunggu persetujuan', 'disetujui', 'menunggu dikirim'
          _completedRoutePoints = [];
          _remainingRoutePoints = _routePoints;
          _truckLocation = null;
          _completedDistance = 0.0;
          break;
      }
    }
  }

  double _calculateProgressPercentage() {
    DateTime now = DateTime.now();
    int hour = now.hour;

    if (hour >= 6 && hour < 18) {
      return ((hour - 6) / 12.0).clamp(0.0, 1.0);
    }
    return 0.5;
  }

  // Parse format tanggal Indonesia: "11/06/2025 21:34 WIB"
  DateTime _parseIndonesianDate(String dateString) {
    try {
      // Format: "11/06/2025 21:34 WIB"
      // Remove "WIB" dan trim
      String cleaned = dateString.replaceAll(' WIB', '').trim();

      // Split tanggal dan waktu
      List<String> dateTimeParts = cleaned.split(' ');
      if (dateTimeParts.length != 2) {
        throw FormatException('Invalid date format: $dateString');
      }

      String datePart = dateTimeParts[0]; // "11/06/2025"
      String timePart = dateTimeParts[1]; // "21:34"

      // Parse tanggal (dd/MM/yyyy)
      List<String> dateParts = datePart.split('/');
      if (dateParts.length != 3) {
        throw FormatException('Invalid date part: $datePart');
      }

      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

      // Parse waktu (HH:mm)
      List<String> timeParts = timePart.split(':');
      if (timeParts.length != 2) {
        throw FormatException('Invalid time part: $timePart');
      }

      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      // Buat DateTime object
      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('Error parsing Indonesian date "$dateString": $e');
      // Return current time sebagai fallback
      return DateTime.now();
    }
  }

  void _generateTrackingSteps(Map<String, dynamic> pengajuanData) {
    _trackingSteps.clear();

    DateTime now = DateTime.now();
    Map<String, DateTime> waktuProgress = {};

    // Parse waktu_progress dengan format Indonesian date
    if (pengajuanData['waktu_progress'] is Map) {
      var waktuProgressData =
          pengajuanData['waktu_progress'] as Map<String, dynamic>;

      print('=== DEBUG WAKTU PROGRESS ===');
      waktuProgressData.forEach((key, value) {
        try {
          DateTime timestamp;
          if (value is Timestamp) {
            timestamp = value.toDate();
          } else if (value is String) {
            // Handle Indonesian date format: "11/06/2025 21:34 WIB"
            timestamp = _parseIndonesianDate(value);
          } else {
            timestamp = now;
          }
          waktuProgress[key.toLowerCase()] = timestamp;
          print(
            '$key: ${_formatDetailDate(timestamp)} (${timestamp.toString()})',
          );
        } catch (e) {
          print('Error parsing timestamp for $key: $e');
          waktuProgress[key.toLowerCase()] = now;
        }
      });
      print('=== END DEBUG ===');
    }

    // Generate steps berdasarkan progress dengan timestamp yang tepat
    List<TrackingStepData> stepDataList = [];

    switch (_progress.toLowerCase()) {
      case 'menunggu persetujuan':
        stepDataList = [
          TrackingStepData(
            description: 'Laporan Pengajuan $_namaPenerima Dibuat',
            timestamp: waktuProgress['waktu_pengajuan'] ?? now,
            isCompleted: true,
            isActive: true,
          ),
        ];
        _tanggalDistribusi = _formatDateIndonesian(
          (waktuProgress['waktu_pengajuan'] ?? now).add(
            const Duration(days: 7),
          ),
        );
        break;

      case 'disetujui':
      case 'menunggu dikirim':
        // Untuk menunggu dikirim, gunakan timestamp disetujui yang sama
        DateTime disetujuiTime = waktuProgress['disetujui'] ?? now;
        DateTime pengajuanTime =
            waktuProgress['waktu_pengajuan'] ??
            disetujuiTime.subtract(const Duration(days: 1));

        stepDataList = [
          TrackingStepData(
            description: 'Menunggu Bantuan Dikirimkan',
            timestamp: disetujuiTime, // Sama dengan disetujui
            isCompleted: true,
            isActive: _progress.toLowerCase() == 'menunggu dikirim',
          ),
          TrackingStepData(
            description: 'Petugas Menyetujui Laporan',
            timestamp: disetujuiTime,
            isCompleted: true,
            isActive: _progress.toLowerCase() == 'disetujui',
          ),
          TrackingStepData(
            description: 'Laporan Pengajuan $_namaPenerima Dibuat',
            timestamp: pengajuanTime,
            isCompleted: true,
            isActive: false,
          ),
        ];
        _tanggalDistribusi = _formatDateIndonesian(
          disetujuiTime.add(const Duration(days: 5)),
        );
        break;

      case 'dikirim':
        DateTime dikirimTime = waktuProgress['dikirim'] ?? now;
        DateTime disetujuiTime2 =
            waktuProgress['disetujui'] ??
            dikirimTime.subtract(const Duration(days: 1));
        DateTime pengajuanTime2 =
            waktuProgress['waktu_pengajuan'] ??
            disetujuiTime2.subtract(const Duration(days: 1));

        stepDataList = [
          TrackingStepData(
            description: 'Bantuan Sedang Dikirimkan',
            timestamp: dikirimTime,
            isCompleted: true,
            isActive: true,
          ),
          TrackingStepData(
            description: 'Menunggu Bantuan Dikirimkan',
            timestamp: disetujuiTime2, // Sama dengan disetujui
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Petugas Menyetujui Laporan',
            timestamp: disetujuiTime2,
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Laporan Pengajuan $_namaPenerima Dibuat',
            timestamp: pengajuanTime2,
            isCompleted: true,
            isActive: false,
          ),
        ];
        _tanggalDistribusi = _formatDateIndonesian(
          dikirimTime.add(const Duration(days: 2)),
        );
        break;

      case 'selesai':
        DateTime selesaiTime = waktuProgress['selesai'] ?? now;
        DateTime dikirimTime2 =
            waktuProgress['dikirim'] ??
            selesaiTime.subtract(const Duration(days: 1));
        DateTime disetujuiTime3 =
            waktuProgress['disetujui'] ??
            dikirimTime2.subtract(const Duration(days: 1));
        DateTime pengajuanTime3 =
            waktuProgress['waktu_pengajuan'] ??
            disetujuiTime3.subtract(const Duration(days: 1));

        stepDataList = [
          TrackingStepData(
            description: 'Bantuan Berhasil Dikirimkan dan Selesai',
            timestamp: selesaiTime,
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Bantuan Sedang Dikirimkan',
            timestamp: dikirimTime2,
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Menunggu Bantuan Dikirimkan',
            timestamp: disetujuiTime3, // Sama dengan disetujui
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Petugas Menyetujui Laporan',
            timestamp: disetujuiTime3,
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Laporan Pengajuan $_namaPenerima Dibuat',
            timestamp: pengajuanTime3,
            isCompleted: true,
            isActive: false,
          ),
        ];
        _tanggalDistribusi = _formatDateIndonesian(selesaiTime);
        break;

      case 'gagal':
        DateTime gagalTime = waktuProgress['gagal'] ?? now;
        DateTime dikirimTime3 =
            waktuProgress['dikirim'] ??
            gagalTime.subtract(const Duration(days: 1));
        DateTime disetujuiTime4 =
            waktuProgress['disetujui'] ??
            dikirimTime3.subtract(const Duration(days: 1));
        DateTime pengajuanTime4 =
            waktuProgress['waktu_pengajuan'] ??
            disetujuiTime4.subtract(const Duration(days: 1));

        stepDataList = [
          TrackingStepData(
            description: 'Bantuan Gagal Dikirimkan Dikarenakan Kendala',
            timestamp: gagalTime,
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Bantuan Sedang Dikirimkan',
            timestamp: dikirimTime3,
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Menunggu Bantuan Dikirimkan',
            timestamp: disetujuiTime4, // Sama dengan disetujui
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Petugas Menyetujui Laporan',
            timestamp: disetujuiTime4,
            isCompleted: true,
            isActive: false,
          ),
          TrackingStepData(
            description: 'Laporan Pengajuan $_namaPenerima Dibuat',
            timestamp: pengajuanTime4,
            isCompleted: true,
            isActive: false,
          ),
        ];
        _tanggalDistribusi = _formatDateIndonesian(gagalTime);
        break;
    }

    // Convert to TrackingStep objects dengan timestamp yang tepat
    for (var stepData in stepDataList) {
      _trackingSteps.add(
        TrackingStep(
          title: '',
          description: stepData.description,
          date: _formatDetailDate(stepData.timestamp),
          isCompleted: stepData.isCompleted,
          isActive: stepData.isActive,
        ),
      );
    }
  }

  String _formatDateIndonesian(DateTime date) {
    List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDetailDate(DateTime date) {
    String day = date.day.toString().padLeft(2, '0');
    List<String> months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '$day ${months[date.month]}';
  }

  void _fitMapToRoute() {
    if (_sourceLocation != null && _destinationLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_routePoints.isNotEmpty) {
          double minLat = _routePoints.map((p) => p.latitude).reduce(math.min);
          double maxLat = _routePoints.map((p) => p.latitude).reduce(math.max);
          double minLng = _routePoints.map((p) => p.longitude).reduce(math.min);
          double maxLng = _routePoints.map((p) => p.longitude).reduce(math.max);

          double latPadding = (maxLat - minLat) * 0.1;
          double lngPadding = (maxLng - minLng) * 0.1;

          LatLngBounds bounds = LatLngBounds(
            LatLng(minLat - latPadding, minLng - lngPadding),
            LatLng(maxLat + latPadding, maxLng + lngPadding),
          );

          _mapController.fitCamera(CameraFit.bounds(bounds: bounds));
        }
      });
    }
  }

  Widget _buildCustomMarker({
    required IconData icon,
    required Color backgroundColor,
    required String label,
    bool isLarge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: backgroundColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: backgroundColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: isLarge ? 32 : 28,
          height: isLarge ? 32 : 28,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: isLarge ? 18 : 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Kembali ke halaman distribusi dan reload data
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DistribusiPageIH()),
        );
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F3D1),
        body:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8F8962)),
                )
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : _buildTrackingContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF626F47),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF626F47).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Kembali ke halaman distribusi dan reload data
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DistribusiPageIH(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8F8962),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali ke Distribusi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent() {
    return Stack(
      children: [
        // Full screen map
        _buildMap(),
        // Header overlay
        _buildHeaderOverlay(),
        // Floating timeline at bottom
        _buildFloatingTimeline(),
      ],
    );
  }

  Widget _buildHeaderOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFF9F3D1).withOpacity(0.9),
              const Color(0xFFF9F3D1).withOpacity(0.7),
              const Color(0xFFF9F3D1).withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                // Kembali ke halaman distribusi dan reload data
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DistribusiPageIH(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF626F47),
                  size: 20,
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'Lacak Lokasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48), // Balance for back button
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    if (_sourceLocation == null || _destinationLocation == null) {
      return const Center(
        child: Text(
          'Tidak dapat memuat peta',
          style: TextStyle(color: Color(0xFF626F47)),
        ),
      );
    }

    List<Widget> mapLayers = [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.semaikan',
      ),
    ];

    // Enhanced polylines dengan warna berdasarkan status
    List<Polyline> polylines = [];

    switch (_progress.toLowerCase()) {
      case 'dikirim':
        // Completed route - biru
        if (_completedRoutePoints.isNotEmpty) {
          polylines.addAll([
            Polyline(
              points: _completedRoutePoints,
              strokeWidth: 10.0,
              color: const Color(0xFF2196F3).withOpacity(0.3),
            ),
            Polyline(
              points: _completedRoutePoints,
              strokeWidth: 6.0,
              color: const Color(0xFF2196F3),
            ),
            Polyline(
              points: _completedRoutePoints,
              strokeWidth: 3.0,
              color: const Color(0xFF64B5F6),
            ),
          ]);
        }

        // Remaining route - orange
        if (_remainingRoutePoints.isNotEmpty) {
          polylines.addAll([
            Polyline(
              points: _remainingRoutePoints,
              strokeWidth: 12.0,
              color: Colors.black.withOpacity(0.3),
            ),
            Polyline(
              points: _remainingRoutePoints,
              strokeWidth: 8.0,
              color: const Color(0xFFFF9800),
            ),
            Polyline(
              points: _remainingRoutePoints,
              strokeWidth: 4.0,
              color: const Color(0xFFFFB74D),
            ),
          ]);
        }
        break;

      case 'selesai':
        // Completed route - hijau
        polylines.addAll([
          Polyline(
            points: _routePoints,
            strokeWidth: 10.0,
            color: const Color(0xFF4CAF50).withOpacity(0.3),
          ),
          Polyline(
            points: _routePoints,
            strokeWidth: 6.0,
            color: const Color(0xFF4CAF50),
          ),
          Polyline(
            points: _routePoints,
            strokeWidth: 3.0,
            color: const Color(0xFF81C784),
          ),
        ]);
        break;

      case 'gagal':
        // Failed route - merah
        if (_completedRoutePoints.isNotEmpty) {
          polylines.addAll([
            Polyline(
              points: _completedRoutePoints,
              strokeWidth: 10.0,
              color: const Color(0xFFF44336).withOpacity(0.3),
            ),
            Polyline(
              points: _completedRoutePoints,
              strokeWidth: 6.0,
              color: const Color(0xFFF44336),
            ),
          ]);
        }

        if (_remainingRoutePoints.isNotEmpty) {
          polylines.addAll([
            Polyline(
              points: _remainingRoutePoints,
              strokeWidth: 8.0,
              color: const Color(0xFF757575),
            ),
            Polyline(
              points: _remainingRoutePoints,
              strokeWidth: 4.0,
              color: const Color(0xFF9E9E9E),
            ),
          ]);
        }
        break;

      default:
        // Pending route - abu-abu
        polylines.addAll([
          Polyline(
            points: _routePoints,
            strokeWidth: 12.0,
            color: Colors.black.withOpacity(0.2),
          ),
          Polyline(
            points: _routePoints,
            strokeWidth: 8.0,
            color: const Color(0xFF757575),
          ),
          Polyline(
            points: _routePoints,
            strokeWidth: 4.0,
            color: const Color(0xFF9E9E9E),
          ),
        ]);
        break;
    }

    mapLayers.add(PolylineLayer(polylines: polylines));

    // Enhanced markers
    List<Marker> markers = [
      Marker(
        point: _sourceLocation!,
        width: 140,
        height: 80,
        child: _buildCustomMarker(
          icon: Icons.warehouse,
          backgroundColor: const Color(0xFF4CAF50),
          label: '$_sourceLocationName\nRegion Kec. $_sourceRegionName',
        ),
      ),
      Marker(
        point: _destinationLocation!,
        width: 120,
        height: 80,
        child: _buildCustomMarker(
          icon: Icons.location_on,
          backgroundColor: const Color(0xFFFF5722),
          label: 'Destinasi',
        ),
      ),
    ];

    // Enhanced truck marker berdasarkan status
    if (_truckLocation != null) {
      Color truckColor;
      IconData truckIcon;

      switch (_progress.toLowerCase()) {
        case 'dikirim':
          truckColor = const Color(0xFF2196F3);
          truckIcon = Icons.local_shipping;
          break;
        case 'gagal':
          truckColor = const Color(0xFFF44336);
          truckIcon = Icons.warning;
          break;
        default:
          truckColor = const Color(0xFF757575);
          truckIcon = Icons.local_shipping;
          break;
      }

      markers.add(
        Marker(
          point: _truckLocation!,
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: truckColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: truckColor.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: truckColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(truckIcon, color: Colors.white, size: 14),
              ),
            ],
          ),
        ),
      );
    }

    mapLayers.add(MarkerLayer(markers: markers));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _destinationLocation!,
        initialZoom: 12.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: mapLayers,
    );
  }

  Widget _buildFloatingTimeline() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF626F47).withOpacity(0.95),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Distribusi tiba pada $_tanggalDistribusi',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            _buildProgressBar(),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: _trackingSteps.length,
                itemBuilder: (context, index) {
                  // Reverse order untuk menampilkan yang terbaru di atas
                  int reversedIndex = _trackingSteps.length - 1 - index;
                  return _buildTimelineStep(
                    _trackingSteps[reversedIndex],
                    index,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    int currentStep = 0;
    int totalSteps = 3;

    switch (_progress.toLowerCase()) {
      case 'menunggu persetujuan':
        currentStep = 0;
        break;
      case 'disetujui':
      case 'menunggu dikirim':
      case 'dikirim':
        currentStep = 1;
        break;
      case 'selesai':
      case 'gagal':
        currentStep = 2;
        break;
    }

    Color activeColor =
        _progress.toLowerCase() == 'gagal'
            ? const Color(0xFFF44336)
            : const Color(0xFF4CAF50);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              for (int i = 0; i < totalSteps; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            i <= currentStep
                                ? activeColor
                                : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  margin: EdgeInsets.symmetric(
                    horizontal: i == 0 || i == totalSteps - 1 ? 0 : 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        i <= currentStep
                            ? activeColor
                            : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengajuan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Proses',
                style: TextStyle(
                  color:
                      currentStep >= 1
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _progress.toLowerCase() == 'gagal' ? 'Gagal' : 'Selesai',
                style: TextStyle(
                  color:
                      currentStep >= 2
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(TrackingStep step, int displayIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date section
          SizedBox(
            width: 50,
            child: Text(
              step.date,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Dot indicator
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color:
                      step.isCompleted
                          ? (_progress.toLowerCase() == 'gagal' && step.isActive
                              ? const Color(0xFFF44336)
                              : const Color(0xFF4CAF50))
                          : step.isActive
                          ? const Color(0xFF2196F3)
                          : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              if (displayIndex < _trackingSteps.length - 1)
                Container(
                  width: 2,
                  height: 25,
                  margin: const EdgeInsets.only(top: 4),
                  color:
                      step.isCompleted
                          ? const Color(0xFF4CAF50).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.3),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Description section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                step.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrackingStep {
  final String title;
  final String description;
  final String date;
  final bool isCompleted;
  final bool isActive;

  TrackingStep({
    required this.title,
    required this.description,
    required this.date,
    required this.isCompleted,
    required this.isActive,
  });
}

class TrackingStepData {
  final String description;
  final DateTime timestamp; // Langsung DateTime, bukan timestampKey
  final bool isCompleted;
  final bool isActive;

  TrackingStepData({
    required this.description,
    required this.timestamp,
    required this.isCompleted,
    required this.isActive,
  });
}
