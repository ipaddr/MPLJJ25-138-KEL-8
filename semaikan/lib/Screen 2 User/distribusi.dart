import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'home_general.dart';
import 'laporan.dart';
import 'pengajuan.dart';
import 'package:semaikan/Screen%20Bersama/maps_tracking.dart';
import '../widgets/floating_bottom_navbar.dart';

class DistribusiPageIH extends StatefulWidget {
  const DistribusiPageIH({super.key});

  @override
  State<DistribusiPageIH> createState() => _DistribusiPageIHState();
}

class _DistribusiPageIHState extends State<DistribusiPageIH> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _pengajuanData = [];
  bool _isLoading = true;
  int _currentIndex = 1; // Index untuk halaman distribusi
  String _namaLengkapUser = ''; // Nama lengkap pengguna

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPengajuanData();
  }

  // Mengambil nama lengkap pengguna dari Firestore
  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('Account_Storage').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _namaLengkapUser =
                userData['nama_lengkap']?.toString() ?? 'Pengguna';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _namaLengkapUser = 'Pengguna';
      });
    }
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

  // Mengambil data pengajuan dari Firestore (1 minggu terakhir dan bukan Selesai/Gagal)
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

        // Filter data hanya 1 minggu terakhir (kurang dari 8 hari) dan bukan status Selesai/Gagal
        DateTime now = DateTime.now();
        DateTime oneWeekAgo = now.subtract(const Duration(days: 7));

        print('=== DEBUG FILTER TANGGAL & STATUS ===');
        print('Current time: $now');
        print('One week ago: $oneWeekAgo');

        List<Map<String, dynamic>> filteredData = [];

        for (var doc in pengajuanSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['document_id'] = doc.id;

          // Cek progress terlebih dahulu - skip jika Selesai atau Gagal
          String progress = data['progress']?.toString().toLowerCase() ?? '';
          if (progress == 'selesai' || progress == 'gagal') {
            print('❌ Skipped document ${doc.id} (status: $progress)');
            continue; // Skip dokumen dengan status Selesai atau Gagal
          }

          // Cek tanggal pengajuan
          if (data['waktu_progress'] is Map &&
              data['waktu_progress']['waktu_pengajuan'] != null) {
            try {
              DateTime pengajuanDate;

              // Handle different date formats
              var waktuPengajuan = data['waktu_progress']['waktu_pengajuan'];
              if (waktuPengajuan is Timestamp) {
                pengajuanDate = waktuPengajuan.toDate();
              } else if (waktuPengajuan is String) {
                // Handle Indonesian date format: "11/06/2025 21:34 WIB"
                pengajuanDate = _parseIndonesianDate(waktuPengajuan);
              } else {
                // Fallback
                pengajuanDate = DateTime.now();
              }

              print(
                'Document ${doc.id}: ${pengajuanDate.toString()} (status: $progress)',
              );

              // Hanya tambahkan jika dalam 1 minggu terakhir
              if (pengajuanDate.isAfter(oneWeekAgo)) {
                filteredData.add(data);
                print(
                  '✅ Added document ${doc.id} (within 1 week, status: $progress)',
                );
              } else {
                print(
                  '❌ Skipped document ${doc.id} (older than 1 week, status: $progress)',
                );
              }
            } catch (e) {
              print('Error parsing date for document ${doc.id}: $e');
              // Untuk keamanan, jangan tampilkan data yang error parsing
              // Ini membantu memastikan hanya data valid yang ditampilkan
              print('❌ Skipped document ${doc.id} (date parsing error)');
            }
          } else {
            print('❌ Skipped document ${doc.id} (no waktu_pengajuan field)');
            // Jika tidak ada tanggal, jangan tampilkan untuk keamanan
            // Karena kita tidak bisa memverifikasi apakah dalam 1 minggu
          }
        }

        print('Total documents processed: ${pengajuanSnapshot.docs.length}');
        print(
          'Documents within 1 week and not Selesai/Gagal: ${filteredData.length}',
        );
        print('=== END DEBUG ===');

        setState(() {
          _pengajuanData = filteredData;
        });
      }
    } catch (e) {
      print('Error loading pengajuan data: $e');
      setState(() {
        _pengajuanData = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Format tanggal dari string atau Timestamp
  String _formatDate(dynamic dateValue) {
    if (dateValue == null) {
      return 'Tanggal tidak tersedia';
    }

    try {
      DateTime dateTime;

      if (dateValue is Timestamp) {
        dateTime = dateValue.toDate();
      } else if (dateValue is String) {
        // Handle Indonesian date format
        if (dateValue.contains('WIB')) {
          dateTime = _parseIndonesianDate(dateValue);
        } else if (dateValue.contains('April') ||
            dateValue.contains('Mei') ||
            dateValue.contains('Juni') ||
            dateValue.contains('Juli') ||
            dateValue.contains('Agustus') ||
            dateValue.contains('September') ||
            dateValue.contains('Oktober') ||
            dateValue.contains('November') ||
            dateValue.contains('Desember') ||
            dateValue.contains('Januari') ||
            dateValue.contains('Februari') ||
            dateValue.contains('Maret')) {
          // Already in Indonesian format
          return dateValue;
        } else {
          // Try standard DateTime parsing
          dateTime = DateTime.parse(dateValue);
        }
      } else {
        return 'Format tanggal tidak valid';
      }

      // Format to Indonesian
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

      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Tanggal tidak valid';
    }
  }

  // Check apakah bisa tracking berdasarkan progress dan waktu_progress
  bool _canTrackLocation(
    String? progress,
    Map<String, dynamic>? waktuProgress,
  ) {
    if (progress == null) return false;

    String progressLower = progress.toLowerCase();

    // Hanya untuk status "Dikirim" saja (karena Selesai dan Gagal sudah difilter)
    return progressLower == 'dikirim';
  }

  // Handle bottom navigation
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeGeneral()),
        );
        break;
      case 1:
        // Already on distribusi page
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

  // Handle tombol cek lokasi (tracking)
  void _handleCekLokasiButton(String documentId, String judulLaporan) {
    final User? user = _auth.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MapsTrackingPage(
                userUid: user.uid,
                documentId: documentId,
                judulLaporan: judulLaporan,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8F8962),
                        ),
                      )
                      : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavigation,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeGeneral()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF626F47),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Distribusi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting dengan nama pengguna
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E2B8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF8F8962), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8F8962),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat datang,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF626F47),
                        ),
                      ),
                      Text(
                        _namaLengkapUser,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF626F47),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Proses Distribusi (Aktif)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _pengajuanData.isEmpty
                    ? _buildEmptyState()
                    : _buildPengajuanList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Color(0xFF8F8962).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada pengajuan yang sedang aktif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF626F47).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pengajuan yang sedang dalam proses distribusi akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF626F47).withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E2B8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8F8962), width: 1),
            ),
            child: Text(
              'Halo, $_namaLengkapUser!',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF626F47),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPengajuanList() {
    return ListView.builder(
      itemCount: _pengajuanData.length,
      itemBuilder: (context, index) {
        final data = _pengajuanData[index];
        return _buildPengajuanCard(data);
      },
    );
  }

  Widget _buildPengajuanCard(Map<String, dynamic> data) {
    // Ekstrak data dari dokumen
    String judulLaporan =
        data['judul_laporan']?.toString() ?? 'Laporan Tidak Berjudul';
    String tanggal = '';

    // Ambil tanggal dari waktu_progress.waktu_pengajuan
    if (data['waktu_progress'] is Map &&
        data['waktu_progress']['waktu_pengajuan'] != null) {
      tanggal = _formatDate(data['waktu_progress']['waktu_pengajuan']);
    } else {
      tanggal = 'Tanggal tidak tersedia';
    }

    String documentId = data['document_id']?.toString() ?? '';
    String progress = data['progress']?.toString() ?? '';
    Map<String, dynamic>? waktuProgress =
        data['waktu_progress'] is Map
            ? data['waktu_progress'] as Map<String, dynamic>
            : null;

    // Check apakah bisa tracking
    bool canTrack = _canTrackLocation(progress, waktuProgress);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF8F8962).withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header dengan icon dan judul
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFFE8E2B8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF8F8962),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Pengajuan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF626F47).withOpacity(0.7),
                      ),
                    ),
                    Text(
                      judulLaporan,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
          const SizedBox(height: 16),

          // Informasi detail
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F3D1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Color(0xFF626F47),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Pengaju: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF626F47),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _namaLengkapUser,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF626F47),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF626F47),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tanggal: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF626F47),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tanggal,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF626F47),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Status dan tombol
          Row(
            children: [
              // Status badge
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(progress).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(progress),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusDisplayText(progress),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(progress),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Tombol Cek Lokasi (hanya untuk status "Dikirim")
              if (canTrack) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _handleCekLokasiButton(documentId, judulLaporan),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F8962),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8F8962).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'CEK LOKASI',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Helper untuk mendapatkan text display status yang sesuai
  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu persetujuan':
        return 'Menunggu Petugas Konfirmasi Laporan';
      case 'disetujui':
        return 'Petugas Menyetujui Laporan';
      case 'menunggu dikirim':
        return 'Menunggu Bantuan Dikirimkan';
      case 'dikirim':
        return 'Bantuan Sedang Dikirimkan';
      case 'selesai':
        return 'Bantuan Berhasil Dikirimkan dan Selesai';
      case 'gagal':
        return 'Bantuan Gagal Dikirimkan Dikarenakan Kendala';
      default:
        return status.isEmpty ? 'Status Tidak Diketahui' : status;
    }
  }

  // Helper untuk mendapatkan warna status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu persetujuan':
        return Colors.orange;
      case 'disetujui':
        return Colors.green;
      case 'menunggu dikirim':
        return Colors.blue;
      case 'dikirim':
        return const Color(0xFF2196F3); // Biru untuk sedang dikirim
      case 'selesai':
        return Colors.green;
      case 'gagal':
        return Colors.red;
      default:
        return const Color(0xFF8F8962);
    }
  }
}
