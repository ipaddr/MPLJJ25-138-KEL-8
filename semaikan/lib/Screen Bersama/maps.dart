import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/floating_bottom_navbar.dart';
import '../widgets/petugas_navbar.dart';
import 'package:semaikan/screen 2 user/distribusi.dart';
import 'package:semaikan/screen 2 user/pengajuan.dart';
import 'package:semaikan/screen 2 user/laporan.dart';
import 'package:semaikan/screen 2 user/home_general.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/home.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/distribusi.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/laporan.dart';

class MapsPage extends StatefulWidget {
  final String? accountCategory; // Parameter untuk account category

  const MapsPage({super.key, this.accountCategory});

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Marker> _markers = [];
  bool _isLoading = true;
  int _currentIndex = 2; // Default ke index 2 untuk petugas
  String _accountCategory =
      'petugas_distribusi'; // Default ke petugas untuk avoid flash

  // Default center koordinat (Padang, Sumatera Barat)
  LatLng _center = const LatLng(-0.9492, 100.3543);

  @override
  void initState() {
    super.initState();
    _initializeAccountCategory();
    _loadDistributionMarkers();
  }

  // Method untuk initialize account category dengan fallback
  Future<void> _initializeAccountCategory() async {
    // Jika ada parameter, gunakan parameter
    if (widget.accountCategory != null && widget.accountCategory!.isNotEmpty) {
      setState(() {
        _accountCategory = widget.accountCategory!;
      });
      print('MapsPage - Account Category from parameter: "$_accountCategory"');
      print('MapsPage - Parameter length: ${widget.accountCategory!.length}');
    } else {
      print('MapsPage - No parameter or empty, getting from Firestore');
      // Jika tidak ada parameter, ambil dari Firestore
      await _getAccountCategoryFromFirestore();
    }

    // Trim dan debug string comparison
    _accountCategory = _accountCategory.trim();
    print('MapsPage - Final accountCategory: "$_accountCategory"');
    print(
      'MapsPage - Comparison result: ${_accountCategory == "petugas_distribusi"}',
    );

    // Set currentIndex berdasarkan account category
    if (_accountCategory == 'petugas_distribusi') {
      setState(() {
        _currentIndex = 2; // Maps index untuk petugas (4 tombol)
      });
      print('MapsPage - Using PetugasNavbar, currentIndex: $_currentIndex');
    } else {
      setState(() {
        _currentIndex = 3; // Maps index untuk user biasa (5 tombol)
      });
      print(
        'MapsPage - Using FloatingBottomNavBar, currentIndex: $_currentIndex',
      );
    }
  }

  // Method untuk mengambil account category dari Firestore
  Future<void> _getAccountCategoryFromFirestore() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        print(
          'MapsPage - Getting account category from Firestore for UID: ${user.uid}',
        );
        final userDoc =
            await _firestore.collection('Account_Storage').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          final category = data['account_category']?.toString() ?? '';
          setState(() {
            _accountCategory = category;
          });
          print(
            'MapsPage - Account Category from Firestore: "$_accountCategory"',
          );
          print('MapsPage - Firestore data keys: ${data.keys.toList()}');
        } else {
          print('MapsPage - User document not found or empty');
        }
      } else {
        print('MapsPage - No current user');
      }
    } catch (e) {
      print('MapsPage - Error getting account category: $e');
    }
  }

  // Fungsi untuk mengkonversi nama field menjadi format yang diinginkan
  String _formatRegionalName(String fieldName) {
    // Replace underscore dengan spasi dan kapitalisasi
    String formatted = fieldName.replaceAll('_', ' ');
    // Kapitalisasi setiap kata
    formatted = formatted
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                  : word,
        )
        .join(' ');

    return 'Regional Kec. $formatted';
  }

  // Fungsi untuk parsing koordinat DMS
  LatLng _parseCoordinates(String coordinates) {
    try {
      // Split koordinat berdasarkan koma
      List<String> parts = coordinates.split(',');
      if (parts.length == 2) {
        double latitude = double.parse(parts[0].trim());
        double longitude = double.parse(parts[1].trim());
        return LatLng(latitude, longitude);
      }
    } catch (e) {
      print('Error parsing coordinates: $coordinates - $e');
    }
    // Return default coordinates jika parsing gagal
    return const LatLng(-0.9492, 100.3543);
  }

  // Fungsi untuk memuat data marker dari Firestore
  Future<void> _loadDistributionMarkers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Ambil data dari Firestore
      DocumentSnapshot doc =
          await _firestore
              .collection('System_Data')
              .doc('distribusi_sumber')
              .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<Marker> markers = [];
        List<LatLng> coordinates = [];

        // Iterasi semua field dalam dokumen
        data.forEach((fieldName, coordinateValue) {
          if (coordinateValue != null &&
              coordinateValue.toString().isNotEmpty) {
            try {
              LatLng coordinate = _parseCoordinates(coordinateValue.toString());
              coordinates.add(coordinate);

              // Buat marker untuk setiap lokasi
              Marker marker = Marker(
                point: coordinate,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap:
                      () => _showMarkerInfo(
                        context,
                        fieldName,
                        coordinateValue.toString(),
                      ),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF626F47),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              _formatRegionalName(fieldName),
                              style: const TextStyle(
                                color: Color(0xFFF9F3D1),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F3D1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF626F47),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.warehouse,
                            color: Color(0xFF626F47),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              markers.add(marker);
            } catch (e) {
              print('Error creating marker for $fieldName: $e');
            }
          }
        });

        // Hitung center berdasarkan semua koordinat
        if (coordinates.isNotEmpty) {
          double avgLat =
              coordinates.map((c) => c.latitude).reduce((a, b) => a + b) /
              coordinates.length;
          double avgLng =
              coordinates.map((c) => c.longitude).reduce((a, b) => a + b) /
              coordinates.length;
          _center = LatLng(avgLat, avgLng);
        }

        setState(() {
          _markers = markers;
          _isLoading = false;
        });
      } else {
        print('Document distribusi_sumber not found');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading distribution markers: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk menampilkan informasi marker
  void _showMarkerInfo(
    BuildContext context,
    String fieldName,
    String coordinates,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF9F3D1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF626F47),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warehouse,
                  color: Color(0xFFF9F3D1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatRegionalName(fieldName),
                  style: const TextStyle(
                    color: Color(0xFF626F47),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Koordinat Lokasi:',
                style: TextStyle(
                  color: Color(0xFF626F47),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECE8C8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  coordinates,
                  style: const TextStyle(
                    color: Color(0xFF626F47),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF626F47),
                foregroundColor: const Color(0xFFF9F3D1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  // Handle bottom navigation berdasarkan account category
  void _handleBottomNavigation(int index) {
    if (_currentIndex == index) {
      return; // Hindari navigasi ke halaman yang sama
    }

    setState(() {
      _currentIndex = index;
    });

    // Navigasi berdasarkan account category dan index
    if (_accountCategory == 'petugas_distribusi') {
      // Navigasi untuk petugas distribusi - menggunakan Screen Khusus Petugas
      switch (index) {
        case 0:
          // Home Page Petugas
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ), // dari Screen Khusus Petugas
          );
          break;
        case 1:
          // Distribusi Page Petugas
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DistribusiPage(),
            ), // dari Screen Khusus Petugas
          );
          break;
        case 2:
          // Already on Maps
          break;
        case 3:
          // Laporan Page Petugas
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LaporanPage(),
            ), // dari Screen Khusus Petugas
          );
          break;
      }
    } else {
      // Navigasi untuk user biasa - menggunakan screen 2 user
      switch (index) {
        case 0:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomeGeneral(),
            ), // dari screen 2 user
          );
          break;
        case 1:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DistribusiPageIH(),
            ), // dari screen 2 user
          );
          break;
        case 2:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DaftarPengajuanPage(),
            ), // dari screen 2 user
          );
          break;
        case 3:
          // Already on Maps
          break;
        case 4:
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LaporanPageIH(),
            ), // dari screen 2 user
          );
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECE8C8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF626F47),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Lokasi Distribusi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF626F47),
                    ),
                  ),
                ],
              ),
            ),

            // Map Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8F8962), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child:
                      _isLoading
                          ? Container(
                            color: const Color(0xFFF9F3D1),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFF626F47),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Memuat lokasi distribusi...',
                                    style: TextStyle(
                                      color: Color(0xFF626F47),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : FlutterMap(
                            options: MapOptions(
                              initialCenter: _center,
                              initialZoom: 10.0,
                              minZoom: 8.0,
                              maxZoom: 18.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.semaikan',
                                maxZoom: 18,
                              ),
                              MarkerLayer(markers: _markers),
                            ],
                          ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECE8C8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF8F8962), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF626F47),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Color(0xFFF9F3D1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Lokasi: ${_markers.length}',
                          style: const TextStyle(
                            color: Color(0xFF626F47),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Ketuk marker untuk melihat detail lokasi',
                          style: TextStyle(
                            color: Color(0xFF626F47),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
      // Navbar berdasarkan account category
      bottomNavigationBar: Builder(
        builder: (context) {
          print(
            'MapsPage - Building navbar with accountCategory: "$_accountCategory"',
          );
          print('MapsPage - Current index: $_currentIndex');

          if (_accountCategory == 'petugas_distribusi') {
            print('MapsPage - Rendering PetugasNavbar');
            return PetugasNavbar(
              currentIndex: _currentIndex,
              onTap: _handleBottomNavigation,
            );
          } else {
            print('MapsPage - Rendering FloatingBottomNavBar');
            return FloatingBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _handleBottomNavigation,
            );
          }
        },
      ),
    );
  }
}
