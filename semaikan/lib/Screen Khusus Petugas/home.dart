import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'laporan.dart';
import 'package:semaikan/Screen%20Bersama/profile.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/distribusi.dart';
import 'diagram_petugas.dart';
import 'notifikasi.dart';
import 'package:semaikan/widgets/floating_bottom_navbar.dart';
import 'package:semaikan/widgets/petugas_navbar.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = "Loading...";
  String _profilePicture = '';
  String _accountCategory =
      'petugas_distribusi'; // ✅ Default ke petugas untuk avoid flash
  int _currentIndex = 0;

  // Data untuk statistik
  Map<String, dynamic> _distributionData = {};
  int _totalBerhasil = 0;
  int _totalTertunda = 0;
  int _totalGagal = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _getUserName(),
      _loadDistributionData(),
      _loadStatusData(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getUserName() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await _firestore.collection('Account_Storage').doc(user.uid).get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          setState(() {
            _userName = data['nama_lengkap'] ?? 'User';
            _profilePicture = data['profile_picture']?.toString() ?? '';
            _accountCategory = data['account_category']?.toString() ?? '';
          });
        } else {
          // Fallback ke display name atau email
          setState(() {
            _userName =
                user.displayName?.split(' ')[0] ??
                user.email?.split('@')[0] ??
                'User';
          });
        }
      }
    } catch (e) {
      print('Error getting user name: $e');
      setState(() {
        _userName = 'User';
      });
    }
  }

  Future<void> _loadDistributionData() async {
    try {
      final doc =
          await _firestore
              .collection('System_Data')
              .doc('status_distribusi')
              .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _distributionData = doc.data()!;
        });
      }
    } catch (e) {
      print('Error loading distribution data: $e');
    }
  }

  Future<void> _loadStatusData() async {
    try {
      // Load status data dari Data_Pengajuan
      final querySnapshot = await _firestore.collection('Data_Pengajuan').get();

      int berhasil = 0;
      int tertunda = 0;
      int gagal = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final progress = data['progress'] ?? '';

        if (progress == ' selesai  ') {
          // ✅ Mengambil yang progress "selesai" dengan spasi
          berhasil++;
        } else if (progress == 'Menunggu Persetujuan' ||
            progress == 'Dikirim') {
          tertunda++;
        } else if (progress == 'Gagal') {
          gagal++;
        }
      }

      setState(() {
        _totalBerhasil = berhasil;
        _totalTertunda = tertunda;
        _totalGagal = gagal;
      });
    } catch (e) {
      print('Error loading status data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header dengan Nama User dan Profil
                        _buildHeader(),

                        const SizedBox(height: 20),

                        // Grafik Distribusi
                        DiagramPetugas(distributionData: _distributionData),

                        const SizedBox(height: 20),

                        // Status Distribusi Card
                        _buildStatusCard(),

                        const SizedBox(height: 20),

                        // Riwayat Pemberitahuan Card
                        _buildNotificationHistoryCard(),
                      ],
                    ),
                  ),
                ),
      ),
      bottomNavigationBar:
          _isLoading
              ? null // ✅ Tidak tampilkan navbar saat loading
              : _accountCategory == 'petugas_distribusi'
              ? PetugasNavbar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });

                  if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DistribusiPage(),
                      ),
                    );
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapsPage()),
                    );
                  } else if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaporanPage(),
                      ),
                    );
                  }
                },
              )
              : FloatingBottomNavBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });

                  if (index == 1) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DistribusiPage(),
                      ),
                    );
                  } else if (index == 2) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapsPage()),
                    );
                  } else if (index == 3) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LaporanPage(),
                      ),
                    );
                  }
                },
              ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 40,
              width: 70,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Image.asset(
                'assets/splashscreen.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.eco,
                    color: Color(0xFF626F47),
                    size: 40,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hai,',
                  style: TextStyle(fontSize: 14, color: Color(0xFF626F47)),
                ),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
              ],
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => ProfilePage(
                      accountCategory: _accountCategory,
                    ), // ✅ Kirim account category
              ),
            );
          },
          child: _buildProfilePicture(),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3D1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Distribusi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF626F47),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DistribusiPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8D1A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12, color: Color(0xFF626F47)),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xFF626F47),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(
                'berhasil.png',
                'Berhasil',
                _totalBerhasil.toString(),
              ),
              _buildStatusItem(
                'tertunda.png',
                'Tertunda',
                _totalTertunda.toString(),
              ),
              _buildStatusItem('gagal.png', 'Gagal', _totalGagal.toString()),
            ],
          ),
        ],
      ),
    );
  }

  // Build profile picture widget
  Widget _buildProfilePicture() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8F8962), width: 2),
      ),
      child: ClipOval(
        child:
            (_profilePicture.isEmpty || _profilePicture == '')
                ? Image.asset(
                  'assets/profile.jpg',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 40,
                      height: 40,
                      color: const Color(0xFF626F47),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFFF9F3D1),
                        size: 24,
                      ),
                    );
                  },
                )
                : (() {
                  try {
                    return Image.memory(
                      base64Decode(_profilePicture),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          color: const Color(0xFF626F47),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFFF9F3D1),
                            size: 24,
                          ),
                        );
                      },
                    );
                  } catch (e) {
                    print('Error decoding base64: $e');
                    return Container(
                      width: 40,
                      height: 40,
                      color: const Color(0xFF626F47),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFFF9F3D1),
                        size: 24,
                      ),
                    );
                  }
                })(),
      ),
    );
  }

  Widget _buildStatusItem(String imagePath, String label, String count) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DistribusiPage()),
        );
      },
      child: Column(
        children: [
          // Langsung pakai gambar tanpa circle container
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(
              imagePath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback ke icon default jika gambar tidak ditemukan
                IconData fallbackIcon;
                Color iconColor;
                if (label == 'Berhasil') {
                  fallbackIcon = Icons.check_circle_outline;
                  iconColor = const Color(0xFF4CAF50);
                } else if (label == 'Tertunda') {
                  fallbackIcon = Icons.access_time;
                  iconColor = const Color(0xFFFF9800);
                } else {
                  fallbackIcon = Icons.cancel_outlined;
                  iconColor = const Color(0xFFF44336);
                }
                return Icon(fallbackIcon, color: iconColor, size: 40);
              },
            ),
          ),
          const SizedBox(height: 5),
          Text(
            count,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Color(0xFF626F47)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3D1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Pemberitahuan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF626F47),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotifikasiPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8D1A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(fontSize: 12, color: Color(0xFF626F47)),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xFF626F47),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNotificationItem(),
          const Divider(color: Color(0xFF8F8962), height: 1),
          _buildNotificationItem(),
          const Divider(color: Color(0xFF8F8962), height: 1),
          _buildNotificationItem(),
        ],
      ),
    );
  }

  Widget _buildNotificationItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFECE8C8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF626F47),
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan Distribusi Perlu Kon...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                Text(
                  'Laporan pengajuan pada tanggal 4 April...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF626F47)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
