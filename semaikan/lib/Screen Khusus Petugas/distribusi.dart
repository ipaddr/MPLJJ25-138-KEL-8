import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'package:semaikan/Screen%20Bersama/maps_tracking.dart';
import 'laporan.dart';
import 'home.dart';
import 'package:semaikan/widgets/petugas_navbar.dart';

class DistribusiPage extends StatefulWidget {
  const DistribusiPage({super.key});

  @override
  State<DistribusiPage> createState() => _DistribusiPageState();
}

class _DistribusiPageState extends State<DistribusiPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _distribusiData = [];
  bool _isLoading = true;
  int _currentIndex = 1;
  String _accountCategory = 'petugas_distribusi';

  @override
  void initState() {
    super.initState();
    _initializeAccountCategory();
    _loadDistribusiData();
  }

  Future<void> _initializeAccountCategory() async {
    await _loadUserData();
    _accountCategory = _accountCategory.trim();
    print('DistribusiPage - Final accountCategory: "$_accountCategory"');
    print(
      'DistribusiPage - Comparison result: ${_accountCategory == "petugas_distribusi"}',
    );

    if (_accountCategory == 'petugas_distribusi') {
      setState(() {
        _currentIndex = 1;
      });
      print(
        'DistribusiPage - Using PetugasNavbar, currentIndex: $_currentIndex',
      );
    } else {
      setState(() {
        _currentIndex = 1;
      });
      print(
        'DistribusiPage - Using FloatingBottomNavBar, currentIndex: $_currentIndex',
      );
    }
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        print(
          'DistribusiPage - Getting account category from Firestore for UID: ${user.uid}',
        );
        DocumentSnapshot userDoc =
            await _firestore.collection('Account_Storage').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _accountCategory = userData['account_category']?.toString() ?? '';
          });
          print(
            'DistribusiPage - Account Category from Firestore: "$_accountCategory"',
          );
          print(
            'DistribusiPage - Firestore data keys: ${userData.keys.toList()}',
          );
        } else {
          print('DistribusiPage - User document not found or empty');
        }
      } else {
        print('DistribusiPage - No current user');
      }
    } catch (e) {
      print('DistribusiPage - Error loading user data: $e');
      setState(() {
        _accountCategory = '';
      });
    }
  }

  DateTime _parseIndonesianDate(String dateString) {
    try {
      String cleaned = dateString.replaceAll(' WIB', '').trim();
      List<String> dateTimeParts = cleaned.split(' ');
      if (dateTimeParts.length != 2) {
        throw FormatException('Invalid date format: $dateString');
      }

      String datePart = dateTimeParts[0];
      String timePart = dateTimeParts[1];

      List<String> dateParts = datePart.split('/');
      if (dateParts.length != 3) {
        throw FormatException('Invalid date part: $datePart');
      }

      int day = int.parse(dateParts[0]);
      int month = int.parse(dateParts[1]);
      int year = int.parse(dateParts[2]);

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

  bool _canTrackLocation(String? progress) {
    if (progress == null) return false;
    String progressLower = progress.toLowerCase();
    return progressLower == 'dikirim';
  }

  void _handleCekLokasiButton(
    String userUid,
    String documentId,
    String judulLaporan,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapsTrackingPage(
              userUid: userUid,
              documentId: documentId,
              judulLaporan: judulLaporan,
            ),
      ),
    );
  }

  Future<void> _loadDistribusiData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      QuerySnapshot distribusiSnapshot =
          await _firestore.collection('Data_Pengajuan').get();

      List<Map<String, dynamic>> processedData = [];

      for (var doc in distribusiSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['document_id'] = doc.id;

        String progress = data['progress']?.toString().toLowerCase() ?? '';

        if (progress == 'disetujui' ||
            progress == 'menunggu dikirim' ||
            progress == 'dikirim') {
          processedData.add(data);
        }
      }

      processedData.sort((a, b) {
        try {
          String aDate = a['waktu_progress']?['waktu_pengajuan'] ?? '';
          String bDate = b['waktu_progress']?['waktu_pengajuan'] ?? '';

          DateTime aDateTime = _parseIndonesianDate(aDate);
          DateTime bDateTime = _parseIndonesianDate(bDate);

          return bDateTime.compareTo(aDateTime);
        } catch (e) {
          return 0;
        }
      });

      setState(() {
        _distribusiData = processedData;
      });
    } catch (e) {
      print('Error loading distribusi data: $e');
      setState(() {
        _distribusiData = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) {
      return 'Tanggal tidak tersedia';
    }

    try {
      DateTime dateTime;

      if (dateValue is Timestamp) {
        dateTime = dateValue.toDate();
      } else if (dateValue is String) {
        if (dateValue.contains('WIB')) {
          dateTime = _parseIndonesianDate(dateValue);
        } else {
          dateTime = DateTime.parse(dateValue);
        }
      } else {
        return 'Format tanggal tidak valid';
      }

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
                          color: Color(0xFF626F47),
                        ),
                      )
                      : _buildContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PetugasNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MapsPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LaporanPage()),
            );
          }
        },
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
              Navigator.pop(context);
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
          const Text(
            'Proses Distribusi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF626F47),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child:
                _distribusiData.isEmpty
                    ? _buildEmptyState()
                    : _buildDistribusiList(),
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
            Icons.local_shipping_outlined,
            size: 64,
            color: Color(0xFF8F8962).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada distribusi dalam proses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF626F47).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Distribusi yang sedang berlangsung akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF626F47).withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDistribusiList() {
    return ListView.builder(
      itemCount: _distribusiData.length,
      itemBuilder: (context, index) {
        final data = _distribusiData[index];
        return _buildDistribusiCard(data);
      },
    );
  }

  Widget _buildDistribusiCard(Map<String, dynamic> data) {
    String judulLaporan =
        data['judul_laporan']?.toString() ?? 'Laporan Tidak Berjudul';
    String namaLengkap = data['nama_pemohon']?.toString() ?? 'Tidak diketahui';
    String tanggal = '';

    if (data['waktu_progress'] is Map &&
        data['waktu_progress']['waktu_pengajuan'] != null) {
      tanggal = _formatDate(data['waktu_progress']['waktu_pengajuan']);
    } else {
      tanggal = 'Tanggal tidak tersedia';
    }

    String documentId = data['document_id']?.toString() ?? '';
    String progress = data['progress']?.toString() ?? '';
    String jenisBantuan = data['jenis_bantuan']?.toString() ?? '';
    String userUid = data['user_id']?.toString() ?? '';

    bool canTrack = _canTrackLocation(progress);

    List<Widget> cardChildren = [
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
              Icons.local_shipping_outlined,
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
                  'Distribusi Bantuan',
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
                  'Pemohon: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF626F47),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    namaLengkap,
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
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getStatusColor(progress).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _getStatusColor(progress), width: 1),
        ),
        child: Text(
          _getStatusDisplayText(progress),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getStatusColor(progress),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ];

    if (jenisBantuan.isNotEmpty) {
      cardChildren.insert(
        cardChildren.length - 2,
        Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.inventory_outlined,
                  size: 16,
                  color: Color(0xFF626F47),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Jenis: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF626F47),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Expanded(
                  child: Text(
                    jenisBantuan,
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
      );
    }

    if (canTrack && userUid.isNotEmpty) {
      cardChildren.add(const SizedBox(height: 12));
      cardChildren.add(
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap:
                () => _handleCekLokasiButton(userUid, documentId, judulLaporan),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'LACAK PENGIRIMAN DISTRIBUSI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
        children: cardChildren,
      ),
    );
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return 'Disetujui - Menunggu Distribusi';
      case 'menunggu dikirim':
        return 'Menunggu Dikirimkan';
      case 'dikirim':
        return 'Sedang Dikirimkan';
      case 'selesai':
        return 'Distribusi Selesai';
      case 'gagal':
        return 'Distribusi Gagal';
      default:
        return status.isEmpty ? 'Status Tidak Diketahui' : status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Colors.green;
      case 'menunggu dikirim':
        return Colors.blue;
      case 'dikirim':
        return const Color(0xFF2196F3);
      case 'selesai':
        return Colors.green;
      case 'gagal':
        return Colors.red;
      default:
        return const Color(0xFF8F8962);
    }
  }
}
