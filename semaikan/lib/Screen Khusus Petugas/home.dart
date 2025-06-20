import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'laporan.dart';
import 'package:semaikan/Screen%20Bersama/profile.dart';
import 'package:semaikan/Screen%20Khusus%20Petugas/distribusi.dart';
import 'diagram_petugas.dart';
import 'notifikasi.dart';
import 'buat_pengumuman.dart'; // Import halaman buat pengumuman
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

  // Data untuk notifikasi
  List<Map<String, dynamic>> _recentNotifications = [];

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
      _loadRecentNotifications(),
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
      // Load status berhasil dari System_Data
      final systemDoc =
          await _firestore
              .collection('System_Data')
              .doc('status_distribusi')
              .get();

      int berhasil = 0;
      if (systemDoc.exists && systemDoc.data() != null) {
        berhasil = systemDoc.data()!['total_penerima'] ?? 0;
      }

      // Load status tertunda dan gagal dari Data_Pengajuan
      final querySnapshot = await _firestore.collection('Data_Pengajuan').get();

      int tertunda = 0;
      int gagal = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final progress = data['progress'] ?? '';

        if (progress == 'Menunggu Persetujuan' || progress == 'Dikirim') {
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

  Future<void> _loadRecentNotifications() async {
    try {
      final querySnapshot = await _firestore.collection('Data_Pengajuan').get();

      List<Map<String, dynamic>> notifications = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final progress = data['progress'] ?? '';

        if (progress == 'Menunggu Persetujuan') {
          final namaLengkap = data['nama_lengkap'] ?? 'Tidak diketahui';
          final waktuProgress = data['waktu_progress'] as Map<String, dynamic>?;
          final waktuPengajuan = waktuProgress?['waktu_pengajuan'] ?? '';

          if (waktuPengajuan.isNotEmpty) {
            final notificationDate = _parseWaktuPengajuan(waktuPengajuan);

            if (notificationDate != null) {
              notifications.add({
                'id': doc.id,
                'nama_lengkap': namaLengkap,
                'waktu_pengajuan': waktuPengajuan,
                'formatted_date': _formatTanggal(waktuPengajuan),
                'notification_date': notificationDate,
                'title': 'Pengajuan Distribusi Perlu Kon...',
                'subtitle':
                    'Laporan pengajuan pada tanggal ${_formatTanggal(waktuPengajuan)}...',
              });
            }
          }
        }
      }

      // Urutkan berdasarkan waktu terbaru dan ambil 3 teratas
      notifications.sort((a, b) {
        final dateA = a['notification_date'] as DateTime;
        final dateB = b['notification_date'] as DateTime;
        return dateB.compareTo(dateA);
      });

      setState(() {
        _recentNotifications = notifications.take(3).toList();
      });
    } catch (e) {
      print('Error loading recent notifications: $e');
    }
  }

  DateTime? _parseWaktuPengajuan(String waktuPengajuan) {
    try {
      // Format: "13/06/2025 20:45 WIB"
      final parts = waktuPengajuan.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0]; // "13/06/2025"
        final timePart = parts[1]; // "20:45"

        final dateComponents = datePart.split('/');
        final timeComponents = timePart.split(':');

        if (dateComponents.length == 3 && timeComponents.length == 2) {
          final day = int.parse(dateComponents[0]);
          final month = int.parse(dateComponents[1]);
          final year = int.parse(dateComponents[2]);
          final hour = int.parse(timeComponents[0]);
          final minute = int.parse(timeComponents[1]);

          return DateTime(year, month, day, hour, minute);
        }
      }
    } catch (e) {
      print('Error parsing waktu pengajuan: $e');
    }
    return null;
  }

  String _formatTanggal(String waktuPengajuan) {
    try {
      final dateTime = _parseWaktuPengajuan(waktuPengajuan);
      if (dateTime != null) {
        final months = [
          '',
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

        return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year}';
      }
    } catch (e) {
      print('Error formatting tanggal: $e');
    }
    return waktuPengajuan;
  }

  void _handleNavigation(int index) {
    // Jangan navigate jika sedang loading
    if (_isLoading) return;

    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DistribusiPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapsPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LaporanPage()),
      );
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

                        // Tombol Buat Pengumuman (hanya untuk petugas)
                        if (_accountCategory == 'petugas_distribusi')
                          _buildBuatPengumumanButton(),

                        if (_accountCategory == 'petugas_distribusi')
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
      // ✅ Navbar tetap ditampilkan bahkan saat loading
      bottomNavigationBar:
          _accountCategory == 'petugas_distribusi'
              ? PetugasNavbar(
                currentIndex: _currentIndex,
                onTap:
                    _handleNavigation, // Gunakan fungsi terpisah untuk handle navigation
              )
              : FloatingBottomNavBar(
                currentIndex: _currentIndex,
                onTap:
                    _handleNavigation, // Gunakan fungsi terpisah untuk handle navigation
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
                  'Hai Petugas Distribusi,',
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

  Widget _buildBuatPengumumanButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF626F47), Color(0xFF8F8962)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BuatPengumumanPage()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F3D1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign,
                color: Color(0xFF626F47),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buat Pengumuman',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF9F3D1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Kirim pengumuman ke seluruh pengguna',
                    style: TextStyle(fontSize: 14, color: Color(0xFFF9F3D1)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFF9F3D1),
              size: 20,
            ),
          ],
        ),
      ),
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
                'Notifikasi',
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
                  ).then((_) {
                    // Refresh notifications when returning
                    _loadRecentNotifications();
                  });
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

          // Display real notifications or empty state
          if (_recentNotifications.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Tidak ada notifikasi terbaru',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8F8962),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...List.generate(_recentNotifications.length, (index) {
              final notification = _recentNotifications[index];
              return Column(
                children: [
                  _buildNotificationItem(notification),
                  if (index < _recentNotifications.length - 1)
                    const Divider(color: Color(0xFF8F8962), height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic>? notification) {
    if (notification == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          'Data notifikasi tidak tersedia',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF8F8962),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'Notifikasi',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                Text(
                  notification['subtitle'] ?? 'Tidak ada deskripsi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF626F47),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
