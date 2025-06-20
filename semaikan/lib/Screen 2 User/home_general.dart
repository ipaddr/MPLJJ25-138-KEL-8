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
  String _profilePicture = "";
  List<Map<String, dynamic>> _pengajuanData = []; // Data pengajuan untuk badge
  List<Map<String, dynamic>> _recentNotifications = []; // Notifikasi terbaru
  bool _isLoading = true;
  int _currentIndex = 0;

  // Counters untuk status badges
  int _pengajuanCount = 0;
  int _prosesCount = 0;
  int _dikirimCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _getUserData(),
      _loadPengajuanData(),
      _loadRecentNotifications(),
    ]);
    setState(() {
      _isLoading = false;
    });
  }

  // Load notifikasi terbaru (3 teratas)
  Future<void> _loadRecentNotifications() async {
    try {
      List<Map<String, dynamic>> notifications = [];

      // Load pengumuman dari petugas
      await _loadPengumumanNotifications(notifications);

      // Load notifikasi laporan pengguna
      await _loadLaporanNotifications(notifications);

      // Sort berdasarkan tanggal terbaru dan ambil 3 teratas
      notifications.sort((a, b) {
        final dateA = a['sort_date'] as DateTime;
        final dateB = b['sort_date'] as DateTime;
        return dateB.compareTo(dateA);
      });

      setState(() {
        _recentNotifications = notifications.take(5).toList();
      });
    } catch (e) {
      print('Error loading recent notifications: $e');
      setState(() {
        _recentNotifications = [];
      });
    }
  }

  Future<void> _loadPengumumanNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    try {
      final doc =
          await _firestore
              .collection('System_Data')
              .doc('notifikasi_user')
              .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final pengumuman = value['pengumuman']?.toString() ?? '';
            final tanggalDibuat = value['tanggal_dibuat']?.toString() ?? '';

            if (pengumuman.isNotEmpty && tanggalDibuat.isNotEmpty) {
              final parsedDate = _parseWaktuString(tanggalDibuat);
              if (parsedDate != null) {
                // Cek apakah notifikasi masih dalam 1 bulan
                final now = DateTime.now();
                final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

                if (parsedDate.isAfter(oneMonthAgo)) {
                  notifications.add({
                    'type': 'pengumuman',
                    'title': 'Informasi Penting!',
                    'content': pengumuman,
                    'date_string': tanggalDibuat,
                    'sort_date': parsedDate,
                    'formatted_date': _formatTanggalIndonesia(tanggalDibuat),
                  });
                }
              }
            }
          }
        });
      }
    } catch (e) {
      print('Error loading pengumuman notifications: $e');
    }
  }

  Future<void> _loadLaporanNotifications(
    List<Map<String, dynamic>> notifications,
  ) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final querySnapshot =
            await _firestore
                .collection('Account_Storage')
                .doc(user.uid)
                .collection('Data_Pengajuan')
                .get();

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final progress = data['progress']?.toString() ?? '';
          final waktuProgress = data['waktu_progress'] as Map<String, dynamic>?;

          if (waktuProgress != null) {
            // Cek progress yang ingin ditampilkan
            if ([
              'Disetujui',
              'Dikirim',
              'Selesai',
              'Gagal',
              'Ditolak',
            ].contains(progress)) {
              String? dateString;
              String title = '';
              String content = '';

              // Ambil tanggal berdasarkan progress
              switch (progress) {
                case 'Disetujui':
                  dateString = waktuProgress['Disetujui']?.toString();
                  title = 'Laporan Pengajuan Disetujui.';
                  break;
                case 'Dikirim':
                  dateString = waktuProgress['Dikirim']?.toString();
                  title = 'Laporan Pengajuan Dikirim.';
                  break;
                case 'Selesai':
                  dateString = waktuProgress['Selesai']?.toString();
                  title = 'Laporan Pengajuan Selesai.';
                  break;
                case 'Gagal':
                  dateString = waktuProgress['Gagal']?.toString();
                  title = 'Laporan Pengajuan Gagal.';
                  break;
                case 'Ditolak':
                  dateString = waktuProgress['Ditolak']?.toString();
                  title = 'Laporan Pengajuan Ditolak.';
                  break;
              }

              if (dateString != null && dateString.isNotEmpty) {
                final parsedDate = _parseWaktuString(dateString);
                if (parsedDate != null) {
                  // Cek apakah notifikasi masih dalam 1 bulan
                  final now = DateTime.now();
                  final oneMonthAgo = DateTime(
                    now.year,
                    now.month - 1,
                    now.day,
                  );

                  if (parsedDate.isAfter(oneMonthAgo)) {
                    final formattedDate = _formatTanggalIndonesia(dateString);

                    // Buat content berdasarkan progress
                    switch (progress) {
                      case 'Disetujui':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah disetujui.';
                        break;
                      case 'Dikirim':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah dikirim.';
                        break;
                      case 'Selesai':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah selesai.';
                        break;
                      case 'Gagal':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate mengalami kegagalan.';
                        break;
                      case 'Ditolak':
                        content =
                            'Laporan pengajuan pada tanggal $formattedDate telah ditolak.';
                        break;
                    }

                    notifications.add({
                      'type': 'laporan',
                      'title': title,
                      'content': content,
                      'date_string': dateString,
                      'sort_date': parsedDate,
                      'formatted_date': formattedDate,
                      'progress': progress,
                    });
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error loading laporan notifications: $e');
    }
  }

  DateTime? _parseWaktuString(String waktuString) {
    try {
      // Format: "15/06/2025 14:30 WIB"
      final parts = waktuString.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0]; // "15/06/2025"
        final timePart = parts[1]; // "14:30"

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
      print('Error parsing waktu string: $e');
    }
    return null;
  }

  String _formatTanggalIndonesia(String waktuString) {
    try {
      final dateTime = _parseWaktuString(waktuString);
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
      print('Error formatting tanggal Indonesia: $e');
    }
    return waktuString;
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
          _prosesCount++;
          break;
        case 'dikirim':
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
            _profilePicture = userData['profile_picture']?.toString() ?? '';
            _userName =
                userData['nama_lengkap']?.toString() ??
                user.email?.split('@')[0] ??
                'User';
          });

          // Ambil data dari subcollection data_user
          await _getUserSubcollectionData(user.uid);
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
    }
  }

  // Mendapatkan data dari subcollection data_user
  Future<void> _getUserSubcollectionData(String userId) async {
    try {
      setState(() {});
    } catch (e) {
      print('Error getting user subcollection data: $e');
      setState(() {});
    }
  }

  // Mendapatkan greeting message
  String _getGreetingMessage() {
    return 'Selamat datang di Semaikan! Aplikasi distribusi makanan yang membantu Anda mengajukan bantuan pangan dan memantau status distribusi secara real-time.';
  }

  // Mendapatkan status items dengan badge counts
  List<Map<String, dynamic>> _getStatusItems() {
    return [
      {
        'image': 'assets/pengajuan.png', // ✅ Tambahkan 'assets/'
        'label': 'Pengajuan',
        'color': const Color(0xFF626F47),
        'count': _pengajuanCount,
      },
      {
        'image': 'assets/progress.png', // ✅ Tambahkan 'assets/'
        'label': 'Proses',
        'color': const Color(0xFF626F47),
        'count': _prosesCount,
      },
      {
        'image': 'assets/dikirim.png', // ✅ Tambahkan 'assets/'
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
    ).then((_) {
      // Refresh notifications when returning
      _loadRecentNotifications();
    });
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
            (_profilePicture.isEmpty)
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

  // SOLUSI 2: Sama untuk _buildStatusCard()
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
              // ✅ Wrap dengan Expanded
              const Expanded(
                child: Text(
                  'Status Distribusi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // ✅ Button yang lebih compact
              ElevatedButton(
                onPressed: _navigateToStatusPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8D1A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Semua',
                      style: TextStyle(fontSize: 11, color: Color(0xFF626F47)),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
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
              // ✅ Wrap dengan Expanded untuk memberi ruang fleksibel
              const Expanded(
                child: Text(
                  'Riwayat Pemberitahuan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
              ),
              const SizedBox(width: 8), // Beri jarak minimum
              // ✅ Button yang lebih compact
              ElevatedButton(
                onPressed: _navigateToDataManagement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8D1A8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero, // Hilangkan minimum size
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Semua',
                      style: TextStyle(fontSize: 11, color: Color(0xFF626F47)),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward,
                      size: 12,
                      color: Color(0xFF626F47),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _recentNotifications.isEmpty
              ? _buildDefaultNotificationItems()
              : _buildRealNotificationList(),
        ],
      ),
    );
  }

  Widget _buildRealNotificationList() {
    return Column(
      children: [
        ...List.generate(_recentNotifications.length, (index) {
          final notification = _recentNotifications[index];
          return Column(
            children: [
              _buildRealNotificationItem(notification),
              if (index < _recentNotifications.length - 1)
                const Divider(color: Color(0xFF8F8962), height: 1),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRealNotificationItem(Map<String, dynamic> notification) {
    final type = notification['type'] as String;
    final title = notification['title'] as String;
    final content = notification['content'] as String;

    // Icon berdasarkan tipe notifikasi
    IconData iconData;
    Color iconColor;

    if (type == 'pengumuman') {
      iconData = Icons.campaign;
      iconColor = const Color(0xFF626F47);
    } else {
      // Icon berdasarkan progress laporan
      final progress = notification['progress'] as String?;
      switch (progress) {
        case 'Disetujui':
          iconData = Icons.check_circle_outline;
          iconColor = Colors.blue;
          break;
        case 'Dikirim':
          iconData = Icons.local_shipping;
          iconColor = Colors.purple;
          break;
        case 'Selesai':
          iconData = Icons.task_alt;
          iconColor = Colors.green;
          break;
        case 'Gagal':
          iconData = Icons.error_outline;
          iconColor = Colors.red;
          break;
        case 'Ditolak':
          iconData = Icons.block;
          iconColor = Colors.red[800]!;
          break;
        default:
          iconData = Icons.description_outlined;
          iconColor = const Color(0xFF626F47);
      }
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
            child: Icon(iconData, color: iconColor, size: 24),
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
                  content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF626F47),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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
}
