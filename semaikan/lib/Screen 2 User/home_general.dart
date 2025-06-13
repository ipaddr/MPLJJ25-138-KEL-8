import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'package:semaikan/Screen%20Bersama/profile.dart';
import 'dart:convert';
import 'distribusi.dart';
import 'laporan.dart';
import 'notifikasi.dart';
import 'pengajuan.dart';
import '../widgets/floating_bottom_navbar.dart';

class HomeGeneral extends StatefulWidget {
  const HomeGeneral({super.key});

  @override
  State<HomeGeneral> createState() => _HomeGeneralState();
}

class _HomeGeneralState extends State<HomeGeneral> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = "Pengguna";
  String _accountCategory = "";
  String _profilePicture = "";
  List<Map<String, dynamic>> _userData = [];
  List<Map<String, dynamic>> _pengajuanData = []; // Data pengajuan untuk badge
  bool _isLoading = true;
  int _currentIndex = 0;

  // Counters untuk status badges
  int _pengajuanCount = 0;
  int _prosesCount = 0;
  int _dikirimCount = 0;

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadPengajuanData(); // Load data pengajuan untuk badges
  }

  // Parse format tanggal Indonesia: "11/06/2025 21:34 WIB"
  DateTime _parseIndonesianDate(String dateString) {
    try {
      String cleaned = dateString.replaceAll(' WIB', '').trim();
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

      return DateTime(year, month, day, hour, minute);
    } catch (e) {
      print('Error parsing Indonesian date "$dateString": $e');
      return DateTime.now();
    }
  }

  // Mengambil data pengajuan dari Firestore untuk badge counts
  Future<void> _loadPengajuanData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot pengajuanSnapshot =
            await _firestore
                .collection('Account_Storage')
                .doc(user.uid)
                .collection('Data_Pengajuan')
                .orderBy('waktu_progress.waktu_pengajuan', descending: true)
                .get();

        // Filter data hanya 1 minggu terakhir
        DateTime now = DateTime.now();
        DateTime oneWeekAgo = now.subtract(const Duration(days: 7));

        List<Map<String, dynamic>> filteredData = [];

        for (var doc in pengajuanSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['document_id'] = doc.id;

          // Cek tanggal pengajuan
          if (data['waktu_progress'] is Map &&
              data['waktu_progress']['waktu_pengajuan'] != null) {
            try {
              DateTime pengajuanDate;
              var waktuPengajuan = data['waktu_progress']['waktu_pengajuan'];

              if (waktuPengajuan is Timestamp) {
                pengajuanDate = waktuPengajuan.toDate();
              } else if (waktuPengajuan is String) {
                pengajuanDate = _parseIndonesianDate(waktuPengajuan);
              } else {
                pengajuanDate = DateTime.now();
              }

              // Hanya tambahkan jika dalam 1 minggu terakhir
              if (pengajuanDate.isAfter(oneWeekAgo)) {
                filteredData.add(data);
              }
            } catch (e) {
              print('Error parsing date for document ${doc.id}: $e');
            }
          }
        }

        setState(() {
          _pengajuanData = filteredData;
          _calculateStatusCounts();
        });
      }
    } catch (e) {
      print('Error loading pengajuan data: $e');
      setState(() {
        _pengajuanData = [];
        _calculateStatusCounts();
      });
    }
  }

  // Menghitung jumlah status untuk badges
  void _calculateStatusCounts() {
    _pengajuanCount = 0;
    _prosesCount = 0;
    _dikirimCount = 0;

    for (var data in _pengajuanData) {
      String progress = data['progress']?.toString().toLowerCase() ?? '';

      switch (progress) {
        case 'menunggu persetujuan':
          _pengajuanCount++;
          break;
        case 'disetujui':
        case 'menunggu dikirim':
        case 'dikirim':
          _prosesCount++;
          break;
        case 'selesai':
        case 'gagal':
          _dikirimCount++;
          break;
      }
    }
  }

  // Mendapatkan data pengguna dari Firestore
  Future<void> _getUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Ambil data dari Account_Storage
        DocumentSnapshot userDoc =
            await _firestore.collection('Account_Storage').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            _accountCategory = userData['account_category']?.toString() ?? '';
            _profilePicture = userData['profile_picture']?.toString() ?? '';
            // Set nama berdasarkan kategori akun
            if (_accountCategory == 'ibu_hamil_balita') {
              _userName =
                  userData['nama_lengkap']?.toString() ??
                  user.email?.split('@')[0] ??
                  'Ibu Hamil';
            } else if (_accountCategory == 'sekolah_pesantren') {
              _userName =
                  userData['nama_sekolah']?.toString() ??
                  user.email?.split('@')[0] ??
                  'Sekolah';
            }
          });

          // Ambil data dari subcollection data_user
          await _getUserSubcollectionData(user.uid);
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mendapatkan data dari subcollection data_user
  Future<void> _getUserSubcollectionData(String userId) async {
    try {
      QuerySnapshot dataSnapshot =
          await _firestore
              .collection('Account_Storage')
              .doc(userId)
              .collection('data_user')
              .orderBy('timestamp', descending: true)
              .get();

      setState(() {
        _userData =
            dataSnapshot.docs.map((doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              data['id'] = doc.id;
              return data;
            }).toList();
      });
    } catch (e) {
      print('Error getting user subcollection data: $e');
      setState(() {
        _userData = [];
      });
    }
  }

  // Mendapatkan greeting message
  String _getGreetingMessage() {
    return 'Laporan Pengajuan Distribusi yang kamu ajukan telah dikonfirmasi, jangan lewatkan tanggalnya!';
  }

  // Mendapatkan status items dengan badge counts
  List<Map<String, dynamic>> _getStatusItems() {
    return [
      {
        'image': 'pengajuan.png',
        'label': 'Pengajuan',
        'color': const Color(0xFF626F47),
        'count': _pengajuanCount,
      },
      {
        'image': 'progress.png',
        'label': 'Proses',
        'color': const Color(0xFF626F47),
        'count': _prosesCount,
      },
      {
        'image': 'dikirim.png',
        'label': 'Dikirim',
        'color': const Color(0xFF626F47),
        'count': _dikirimCount,
      },
    ];
  }

  // Navigation logic
  void _navigateToStatusPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DistribusiPageIH()),
    );
  }

  void _navigateToDataManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotifikasiPageIP()),
    );
  }

  // Handle bottom navigation - Clean and simple
  void _handleBottomNavigation(int index) {
    if (_currentIndex == index) {
      return; // Hindari navigasi ke halaman yang sama
    }

    setState(() {
      _currentIndex = index;
    });

    // Navigasi berdasarkan index
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DistribusiPageIH()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DaftarPengajuanPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MapsPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LaporanPageIH()),
        );
        break;
    }
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
            (_profilePicture.isEmpty || _profilePicture == null)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8F8962)),
                )
                : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildStatusCard(),
                        const SizedBox(height: 20),
                        _buildDataCard(),
                      ],
                    ),
                  ),
                ),
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigation,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: _buildProfilePicture(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _getGreetingMessage(),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF626F47),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    List<Map<String, dynamic>> statusItems = _getStatusItems();

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
                onPressed: _navigateToStatusPage,
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
            children:
                statusItems
                    .map(
                      (item) => _buildStatusItem(
                        item['image']?.toString(),
                        item['label']?.toString() ?? 'Unknown',
                        item['color'] ?? const Color(0xFF626F47),
                        item['count'] ?? 0,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
    String? imagePath,
    String? label,
    Color? color,
    int count,
  ) {
    final String safeLabel = label ?? 'Unknown';
    final Color safeColor = color ?? const Color(0xFF626F47);

    return Column(
      children: [
        Stack(
          children: [
            // Icon utama
            Image.asset(
              imagePath ?? 'pengajuan.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            // Badge notification
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          safeLabel,
          style: TextStyle(
            fontSize: 12,
            color: safeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard() {
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
                onPressed: _navigateToDataManagement,
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
          _userData.isEmpty
              ? _buildDefaultNotificationItems()
              : _buildDataList(),
        ],
      ),
    );
  }

  Widget _buildDefaultNotificationItems() {
    return Column(
      children: [
        _buildNotificationItem(
          'Informasi Penting..',
          'Bantuan akan didistribusikan pada 6 Mei 2025...',
        ),
        const Divider(color: Color(0xFF8F8962), height: 1),
        _buildNotificationItem(
          'Informasi Penting!',
          'Program distribusi makanan untuk balita akan dimulai besok',
        ),
        const Divider(color: Color(0xFF8F8962), height: 1),
        _buildNotificationItem(
          'Laporan Pengajuan Diterima.',
          'Laporan pengajuan pada tanggal 18 April 2025 telah diterima.',
        ),
      ],
    );
  }

  Widget _buildNotificationItem(String title, String description) {
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
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                Text(
                  description,
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

  Widget _buildDataList() {
    return Column(
      children: _userData.take(3).map((data) => _buildDataItem(data)).toList(),
    );
  }

  Widget _buildDataItem(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFECE8C8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF626F47),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.health_and_safety,
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
                    data['title']?.toString() ?? 'Informasi Penting..',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF626F47),
                    ),
                  ),
                  Text(
                    data['description']?.toString() ??
                        'Bantuan akan didistribusikan pada 6 Mei 2025...',
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
      ),
    );
  }
}
