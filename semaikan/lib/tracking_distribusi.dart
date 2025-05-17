import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class TrackingDistribusiPage extends StatefulWidget {
  final Map<String, dynamic> distribusiData;

  const TrackingDistribusiPage({super.key, required this.distribusiData});

  @override
  State<TrackingDistribusiPage> createState() => _TrackingDistribusiPageState();
}

class _TrackingDistribusiPageState extends State<TrackingDistribusiPage> {
  late GoogleMapController _mapController;

  // Koordinat untuk demo (Indonesia)
  static const LatLng _pusatDistribusi = LatLng(-6.2088, 106.8456); // Jakarta
  static const LatLng _lokasiTujuan = LatLng(-0.9471, 100.4172); // Padang
  static const LatLng _lokasiSaatIni = LatLng(-1.6101, 103.6131); // Jambi

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  // Status tracking timeline
  final List<Map<String, dynamic>> _trackingTimeline = [
    {
      'status': 'Makanan Disiapkan',
      'description': 'Persiapan makanan bergizi di dapur pusat',
      'time': '22 April 2025, 06:00',
      'location': 'Jakarta',
      'isCompleted': true,
      'icon': Icons.restaurant,
    },
    {
      'status': 'Dikemas dan Dimuat',
      'description': 'Makanan dikemas dan dimuat ke kendaraan distribusi',
      'time': '22 April 2025, 08:00',
      'location': 'Jakarta',
      'isCompleted': true,
      'icon': Icons.inventory,
    },
    {
      'status': 'Perjalanan Dimulai',
      'description': 'Kendaraan distribusi berangkat menuju lokasi tujuan',
      'time': '22 April 2025, 09:00',
      'location': 'Jakarta - Padang',
      'isCompleted': true,
      'icon': Icons.local_shipping,
    },
    {
      'status': 'Transit di Jambi',
      'description': 'Istirahat dan pengecekan kondisi makanan',
      'time': '22 April 2025, 14:00',
      'location': 'Jambi',
      'isCompleted': true,
      'isCurrent': true,
      'icon': Icons.location_on,
    },
    {
      'status': 'Dalam Perjalanan',
      'description': 'Melanjutkan perjalanan menuju SMAN 1 Kota Padang',
      'time': 'Estimasi: 22 April 2025, 18:00',
      'location': 'Jambi - Padang',
      'isCompleted': false,
      'icon': Icons.directions,
    },
    {
      'status': 'Tiba di Lokasi',
      'description': 'Tiba di SMAN 1 Kota Padang dan persiapan distribusi',
      'time': 'Estimasi: 22 April 2025, 20:00',
      'location': 'SMAN 1 Kota Padang',
      'isCompleted': false,
      'icon': Icons.school,
    },
    {
      'status': 'Distribusi Selesai',
      'description': 'Makanan berhasil didistribusikan kepada siswa',
      'time': 'Estimasi: 23 April 2025, 08:00',
      'location': 'SMAN 1 Kota Padang',
      'isCompleted': false,
      'icon': Icons.done_all,
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupMap();
  }

  void _setupMap() {
    // Setup markers
    _markers = {
      Marker(
        markerId: const MarkerId('pusat_distribusi'),
        position: _pusatDistribusi,
        infoWindow: const InfoWindow(
          title: 'Pusat Distribusi',
          snippet: 'Dapur Pusat Jakarta',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('lokasi_saat_ini'),
        position: _lokasiSaatIni,
        infoWindow: const InfoWindow(
          title: 'Lokasi Saat Ini',
          snippet: 'Transit di Jambi',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: const MarkerId('tujuan'),
        position: _lokasiTujuan,
        infoWindow: const InfoWindow(
          title: 'Tujuan',
          snippet: 'SMAN 1 Kota Padang',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };

    // Setup polylines (rute)
    _polylines = {
      // Rute yang sudah dilalui (hijau)
      Polyline(
        polylineId: const PolylineId('rute_dilalui'),
        points: [_pusatDistribusi, _lokasiSaatIni],
        color: Colors.green,
        width: 4,
        patterns: [], // Solid line
      ),
      // Rute yang akan dilalui (abu-abu putus-putus)
      Polyline(
        polylineId: const PolylineId('rute_akan_dilalui'),
        points: [_lokasiSaatIni, _lokasiTujuan],
        color: Colors.grey,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Dashed line
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F3D1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF626F47)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lacak Distribusi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF626F47).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.distribusiData['title'] ?? 'Distribusi Makanan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.local_shipping,
                      color: Color(0xFF626F47),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID Pengiriman: ${widget.distribusiData['id'] ?? 'DIS001'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF626F47),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Color(0xFF626F47),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Estimasi Tiba: 22 April 2025, 20:00',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF626F47),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF626F47).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(
                      -2.5,
                      102.5,
                    ), // Tengah Sumatera untuk overview
                    zoom: 6,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),

          // Timeline
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF626F47).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Perjalanan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF626F47),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _trackingTimeline.length,
                      itemBuilder: (context, index) {
                        return _buildTimelineItem(
                          _trackingTimeline[index],
                          index,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol untuk center ke lokasi saat ini
          FloatingActionButton.small(
            onPressed: () {
              _mapController.animateCamera(
                CameraUpdate.newLatLngZoom(_lokasiSaatIni, 10),
              );
            },
            backgroundColor: const Color(0xFF626F47),
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(width: 8),
          // Tombol untuk lihat overview rute
          FloatingActionButton.small(
            onPressed: () {
              _mapController.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: const LatLng(-7, 100),
                    northeast: const LatLng(-0.5, 107),
                  ),
                  100.0,
                ),
              );
            },
            backgroundColor: const Color(0xFF626F47),
            child: const Icon(Icons.zoom_out_map, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, int index) {
    final bool isCompleted = item['isCompleted'] ?? false;
    final bool isCurrent = item['isCurrent'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isCurrent
                          ? Colors.blue
                          : isCompleted
                          ? Colors.green
                          : Colors.grey.withOpacity(0.3),
                  border: Border.all(
                    color:
                        isCurrent
                            ? Colors.blue
                            : isCompleted
                            ? Colors.green
                            : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Icon(
                  item['icon'],
                  size: 16,
                  color: isCurrent || isCompleted ? Colors.white : Colors.grey,
                ),
              ),
              if (index < _trackingTimeline.length - 1)
                Container(
                  width: 2,
                  height: 40,
                  color:
                      isCompleted ? Colors.green : Colors.grey.withOpacity(0.3),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['status'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:
                        isCurrent
                            ? Colors.blue
                            : isCompleted
                            ? const Color(0xFF626F47)
                            : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isCompleted || isCurrent
                            ? const Color(0xFF626F47)
                            : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color:
                          isCompleted || isCurrent
                              ? const Color(0xFF626F47)
                              : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['time'],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isCompleted || isCurrent
                                ? const Color(0xFF626F47)
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 12,
                      color:
                          isCompleted || isCurrent
                              ? const Color(0xFF626F47)
                              : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['location'],
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isCompleted || isCurrent
                                ? const Color(0xFF626F47)
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
