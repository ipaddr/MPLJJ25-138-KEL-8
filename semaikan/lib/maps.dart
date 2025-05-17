import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapsPage extends StatefulWidget {
  const MapsPage({super.key});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  late GoogleMapController _mapController;
  int _currentIndex = 2; // Index 2 untuk halaman maps di bottom nav

  // Filter yang aktif
  String _activeFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Berhasil', 'Tertunda', 'Gagal'];

  Set<Marker> _markers = {};
  bool _isLoading = true;

  // Data lokasi distribusi
  final List<Map<String, dynamic>> _lokasiDistribusi = [
    {
      'id': 'LOC001',
      'nama': 'SMAN 1 Kota Padang',
      'alamat': 'Jl. Belakang Olo No. 1, Padang',
      'koordinat': const LatLng(-0.9471, 100.4172),
      'jenis': 'Sekolah',
      'status': 'Berhasil',
      'tanggal': '22 April 2025',
      'jumlahPenerima': 250,
      'jenisMakanan': 'Makanan Bergizi',
      'koordinator': 'Bpk. Ahmad',
    },
    {
      'id': 'LOC002',
      'nama': 'Pesantren Nusa Bangsa',
      'alamat': 'Jl. Raya Bogor KM 30, Bogor',
      'koordinat': const LatLng(-6.5915, 106.8317),
      'jenis': 'Pesantren',
      'status': 'Berhasil',
      'tanggal': '18 April 2025',
      'jumlahPenerima': 300,
      'jenisMakanan': 'Menu Halal',
      'koordinator': 'Ustadz Rahman',
    },
    {
      'id': 'LOC003',
      'nama': 'Puskesmas Koto Tangah',
      'alamat': 'Jl. Koto Tangah, Padang',
      'koordinat': const LatLng(-0.9178, 100.3530),
      'jenis': 'Ibu Hamil',
      'status': 'Berhasil',
      'tanggal': '01 April 2025',
      'jumlahPenerima': 50,
      'jenisMakanan': 'Makanan Khusus Ibu Hamil',
      'koordinator': 'Dr. Sari',
    },
    {
      'id': 'LOC004',
      'nama': 'SMAN 2 Jakarta',
      'alamat': 'Jl. Gajah Mada, Jakarta Pusat',
      'koordinat': const LatLng(-6.1744, 106.8294),
      'jenis': 'Sekolah',
      'status': 'Tertunda',
      'tanggal': '25 April 2025',
      'jumlahPenerima': 200,
      'jenisMakanan': 'Makanan Bergizi',
      'koordinator': 'Ibu Siti',
    },
    {
      'id': 'LOC005',
      'nama': 'Posyandu Melati',
      'alamat': 'Jl. Melati, Bandung',
      'koordinat': const LatLng(-6.9175, 107.6191),
      'jenis': 'Balita',
      'status': 'Gagal',
      'tanggal': '23 Maret 2025',
      'jumlahPenerima': 40,
      'jenisMakanan': 'MPASI',
      'koordinator': 'Ibu Ani',
    },
    {
      'id': 'LOC006',
      'nama': 'SMAN 1 Surabaya',
      'alamat': 'Jl. Wijaya Kusuma, Surabaya',
      'koordinat': const LatLng(-7.2575, 112.7521),
      'jenis': 'Sekolah',
      'status': 'Berhasil',
      'tanggal': '15 April 2025',
      'jumlahPenerima': 300,
      'jenisMakanan': 'Makanan Bergizi',
      'koordinator': 'Bpk. Budi',
    },
    {
      'id': 'LOC007',
      'nama': 'Pesantren Darunnajah',
      'alamat': 'Jl. Ulujami, Jakarta Selatan',
      'koordinat': const LatLng(-6.2615, 106.7850),
      'jenis': 'Pesantren',
      'status': 'Berhasil',
      'tanggal': '10 April 2025',
      'jumlahPenerima': 400,
      'jenisMakanan': 'Menu Halal',
      'koordinator': 'Kyai Abdullah',
    },
    {
      'id': 'LOC008',
      'nama': 'SMAN 1 Medan',
      'alamat': 'Jl. Bunga Lau, Medan',
      'koordinat': const LatLng(3.5952, 98.6722),
      'jenis': 'Sekolah',
      'status': 'Tertunda',
      'tanggal': '28 April 2025',
      'jumlahPenerima': 220,
      'jenisMakanan': 'Makanan Bergizi',
      'koordinator': 'Ibu Maya',
    },
  ];

  // Statistik berdasarkan data
  Map<String, int> get _statistik {
    int berhasil =
        _lokasiDistribusi.where((loc) => loc['status'] == 'Berhasil').length;
    int tertunda =
        _lokasiDistribusi.where((loc) => loc['status'] == 'Tertunda').length;
    int gagal =
        _lokasiDistribusi.where((loc) => loc['status'] == 'Gagal').length;
    int totalPenerima = _lokasiDistribusi.fold(
      0,
      (sum, loc) => sum + (loc['jumlahPenerima'] as int),
    );

    return {
      'berhasil': berhasil,
      'tertunda': tertunda,
      'gagal': gagal,
      'total': _lokasiDistribusi.length,
      'totalPenerima': totalPenerima,
    };
  }

  // Data yang difilter
  List<Map<String, dynamic>> get _dataFiltered {
    if (_activeFilter == 'Semua') {
      return _lokasiDistribusi;
    }
    return _lokasiDistribusi
        .where((loc) => loc['status'] == _activeFilter)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _setupMarkers();
  }

  Future<void> _setupMarkers() async {
    setState(() {
      _isLoading = true;
    });

    Set<Marker> markers = {};

    for (var lokasi in _dataFiltered) {
      BitmapDescriptor markerIcon;

      // Tentukan warna marker berdasarkan status dan jenis
      switch (lokasi['status']) {
        case 'Berhasil':
          markerIcon = await _getCustomMarker(lokasi['jenis'], Colors.green);
          break;
        case 'Tertunda':
          markerIcon = await _getCustomMarker(lokasi['jenis'], Colors.orange);
          break;
        case 'Gagal':
          markerIcon = await _getCustomMarker(lokasi['jenis'], Colors.red);
          break;
        default:
          markerIcon = BitmapDescriptor.defaultMarker;
      }

      markers.add(
        Marker(
          markerId: MarkerId(lokasi['id']),
          position: lokasi['koordinat'],
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: lokasi['nama'],
            snippet:
                '${lokasi['status']} - ${lokasi['jumlahPenerima']} penerima',
            onTap: () => _showDetailBottomSheet(lokasi),
          ),
          onTap: () => _showDetailBottomSheet(lokasi),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _isLoading = false;
    });
  }

  Future<BitmapDescriptor> _getCustomMarker(String jenis, Color color) async {
    // Untuk demo, menggunakan marker default dengan hue yang berbeda
    switch (jenis) {
      case 'Sekolah':
        return BitmapDescriptor.defaultMarkerWithHue(
          color == Colors.green
              ? BitmapDescriptor.hueGreen
              : color == Colors.orange
              ? BitmapDescriptor.hueOrange
              : BitmapDescriptor.hueRed,
        );
      case 'Pesantren':
        return BitmapDescriptor.defaultMarkerWithHue(
          color == Colors.green
              ? BitmapDescriptor.hueBlue
              : color == Colors.orange
              ? BitmapDescriptor.hueYellow
              : BitmapDescriptor.hueRed,
        );
      case 'Ibu Hamil':
      case 'Balita':
        return BitmapDescriptor.defaultMarkerWithHue(
          color == Colors.green
              ? BitmapDescriptor.hueViolet
              : color == Colors.orange
              ? BitmapDescriptor.hueRose
              : BitmapDescriptor.hueRed,
        );
      default:
        return BitmapDescriptor.defaultMarker;
    }
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Peta Distribusi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF626F47)),
            onPressed: _setupMarkers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistik Card
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Total Lokasi',
                      _statistik['total'].toString(),
                      Icons.location_on,
                    ),
                    _buildStatItem(
                      'Berhasil',
                      _statistik['berhasil'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Tertunda',
                      _statistik['tertunda'].toString(),
                      Icons.schedule,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Gagal',
                      _statistik['gagal'].toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total ${_statistik['totalPenerima']} penerima telah terlayani',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isActive = _activeFilter == filter;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isActive,
                    onSelected: (selected) {
                      setState(() {
                        _activeFilter = filter;
                      });
                      _setupMarkers();
                    },
                    selectedColor: const Color(0xFF626F47),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF626F47),
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: const Color(0xFFECE8C8),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Map
          Expanded(
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
                child:
                    _isLoading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF626F47),
                          ),
                        )
                        : GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(
                              -2.5489,
                              118.0149,
                            ), // Indonesia center
                            zoom: 5,
                          ),
                          markers: _markers,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          mapType: MapType.normal,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Tombol untuk melihat semua lokasi
          FloatingActionButton.small(
            onPressed: _zoomToFitAllMarkers,
            backgroundColor: const Color(0xFF626F47),
            heroTag: "zoom_all",
            child: const Icon(Icons.zoom_out_map, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Tombol untuk melihat daftar lokasi
          FloatingActionButton.small(
            onPressed: _showLocationsList,
            backgroundColor: const Color(0xFF626F47),
            heroTag: "list_locations",
            child: const Icon(Icons.list, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Column(
      children: [
        Icon(icon, color: color ?? const Color(0xFF626F47), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF626F47),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF626F47)),
        ),
      ],
    );
  }

  void _zoomToFitAllMarkers() {
    if (_markers.isEmpty) return;

    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;

    for (Marker marker in _markers) {
      minLat =
          marker.position.latitude < minLat ? marker.position.latitude : minLat;
      maxLat =
          marker.position.latitude > maxLat ? marker.position.latitude : maxLat;
      minLng =
          marker.position.longitude < minLng
              ? marker.position.longitude
              : minLng;
      maxLng =
          marker.position.longitude > maxLng
              ? marker.position.longitude
              : maxLng;
    }

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0,
      ),
    );
  }

  void _showLocationsList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.3,
            builder:
                (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F3D1),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Daftar Lokasi Distribusi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF626F47),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _dataFiltered.length,
                          itemBuilder: (context, index) {
                            final lokasi = _dataFiltered[index];
                            return _buildLocationListItem(lokasi);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildLocationListItem(Map<String, dynamic> lokasi) {
    Color statusColor =
        lokasi['status'] == 'Berhasil'
            ? Colors.green
            : lokasi['status'] == 'Tertunda'
            ? Colors.orange
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF626F47).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_getIconByJenis(lokasi['jenis']), color: statusColor),
        ),
        title: Text(
          lokasi['nama'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${lokasi['jumlahPenerima']} penerima • ${lokasi['tanggal']}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF626F47)),
            ),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                lokasi['status'],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF626F47),
        ),
        onTap: () {
          Navigator.pop(context);
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(lokasi['koordinat'], 15),
          );
          _showDetailBottomSheet(lokasi);
        },
      ),
    );
  }

  void _showDetailBottomSheet(Map<String, dynamic> lokasi) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F3D1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECE8C8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconByJenis(lokasi['jenis']),
                        color: const Color(0xFF626F47),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lokasi['nama'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF626F47),
                            ),
                          ),
                          Text(
                            lokasi['alamat'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF626F47),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Status', lokasi['status']),
                _buildDetailRow('Tanggal', lokasi['tanggal']),
                _buildDetailRow(
                  'Jumlah Penerima',
                  '${lokasi['jumlahPenerima']} orang',
                ),
                _buildDetailRow('Jenis Makanan', lokasi['jenisMakanan']),
                _buildDetailRow('Koordinator', lokasi['koordinator']),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF626F47),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Color(0xFF626F47))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF626F47)),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconByJenis(String jenis) {
    switch (jenis) {
      case 'Sekolah':
        return Icons.school;
      case 'Pesantren':
        return Icons.mosque;
      case 'Ibu Hamil':
        return Icons.pregnant_woman;
      case 'Balita':
        return Icons.child_care;
      default:
        return Icons.location_on;
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF8F8962),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.menu_book, 'Distribusi', 1),
          _buildNavItem(Icons.map, 'Maps', 2),
          _buildNavItem(Icons.assignment, 'Laporan', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });

        if (index != _currentIndex) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/distribusi');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/laporan');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF626F47) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: const Color(0xFFF9F3D1), size: 24),
      ),
    );
  }
}
