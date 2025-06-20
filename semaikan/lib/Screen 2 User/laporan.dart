import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/floating_bottom_navbar.dart';
import 'distribusi.dart';
import 'pengajuan.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'package:semaikan/Screen%20Bersama/detail_laporan.dart';
import 'home_general.dart';

class LaporanPageIH extends StatefulWidget {
  const LaporanPageIH({super.key});

  @override
  State<LaporanPageIH> createState() => _LaporanPageIHState();
}

class _LaporanPageIHState extends State<LaporanPageIH> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 4; // Index untuk Laporan di bottom navigation
  String _selectedFilter = 'Semua';
  String _selectedProgressFilter = 'Semua'; // Filter progress terpilih
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = true;

  // Controller untuk pencarian
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _filterOptions = [
    'Semua',
    'Berhasil',
    'Tertunda',
    'Dikirim',
    'Gagal',
  ];

  // Daftar filter progress yang tersedia (untuk modal button)
  final List<String> _progressFilters = [
    'Semua',
    'Menunggu Persetujuan',
    'Disetujui',
    'Dikirim',
    'Selesai',
    'Gagal',
    'Ditolak',
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load reports from Firestore
  Future<void> _loadReports() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot reportSnapshot =
            await _firestore
                .collection('Account_Storage')
                .doc(user.uid)
                .collection('Data_Pengajuan')
                .get();

        List<Map<String, dynamic>> reports = [];

        for (var doc in reportSnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['document_id'] = doc.id;

          // Process the report data
          String category = _getCategoryFromProgress(data['progress']);
          String latestDate = _getLatestDate(data['waktu_progress']);

          // Tambahan dari kode pertama: ambil data lengkap
          final judulLaporan =
              data['judul_laporan']?.toString() ?? 'Laporan Tidak Diketahui';
          final namaLengkap =
              data['nama_lengkap']?.toString() ?? 'Nama Tidak Diketahui';
          final emailPemohon =
              data['email_pemohon']?.toString() ?? 'Email Tidak Diketahui';
          final idPengajuan = data['id_pengajuan']?.toString() ?? doc.id;
          final progress = data['progress']?.toString() ?? 'Tidak Diketahui';
          final kategori = data['kategori']?.toString() ?? 'Tidak Diketahui';

          // Ambil address dari nested map lokasi_distribusi
          String address = 'Alamat Tidak Diketahui';
          if (data['lokasi_distribusi'] != null &&
              data['lokasi_distribusi'] is Map) {
            final lokasiDistribusi =
                data['lokasi_distribusi'] as Map<String, dynamic>;
            address =
                lokasiDistribusi['address']?.toString() ??
                'Alamat Tidak Diketahui';
          }

          // Format tanggal menggunakan logic dari kode pertama
          String tanggal = 'Tanggal Tidak Diketahui';
          if (data['waktu_progress'] != null && data['waktu_progress'] is Map) {
            final waktuProgress =
                data['waktu_progress'] as Map<String, dynamic>;
            tanggal = _getLatestDateFromWaktuProgress(waktuProgress);
          }

          data['category'] = category;
          data['display_date'] = latestDate;
          data['judul_laporan'] = judulLaporan;
          data['nama_lengkap'] = namaLengkap;
          data['email_pemohon'] = emailPemohon;
          data['id_pengajuan'] = idPengajuan;
          data['progress'] = progress;
          data['kategori'] = kategori;
          data['address'] = address;
          data['tanggal'] = tanggal;
          data['data_lengkap'] = data; // Simpan data lengkap untuk detail

          reports.add(data);
        }

        // Sort reports by latest date (descending)
        reports.sort((a, b) {
          try {
            DateTime dateA = _parseIndonesianDate(a['display_date']);
            DateTime dateB = _parseIndonesianDate(b['display_date']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          _allReports = reports;
          _applyFilter();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Parse Indonesian date format
  DateTime _parseIndonesianDate(String dateString) {
    try {
      String cleaned = dateString.replaceAll(' WIB', '').trim();
      List<String> dateTimeParts = cleaned.split(' ');
      if (dateTimeParts.length != 2) {
        throw FormatException('Invalid date format: $dateString');
      }

      String datePart = dateTimeParts[0]; // "11/06/2025"
      String timePart = dateTimeParts[1]; // "21:34"

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

  // Get category based on progress value
  String _getCategoryFromProgress(dynamic progress) {
    if (progress == null) return 'Tertunda';

    String progressStr = progress.toString().toLowerCase();

    switch (progressStr) {
      case 'menunggu persetujuan':
        return 'Tertunda';
      case 'disetujui':
      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Berhasil';
      case 'gagal':
        return 'Gagal';
      default:
        return 'Tertunda';
    }
  }

  // Get latest date from waktu_progress map
  String _getLatestDate(dynamic waktuProgress) {
    if (waktuProgress == null || waktuProgress is! Map) {
      return DateTime.now().toString().substring(0, 19);
    }

    Map<String, dynamic> waktuMap = Map<String, dynamic>.from(waktuProgress);

    // If there's "gagal" field, use it regardless of order
    if (waktuMap.containsKey('gagal') && waktuMap['gagal'] != null) {
      return waktuMap['gagal'].toString();
    }

    // Check in priority order: selesai -> dikirim -> disetujui -> waktu_pengajuan
    List<String> priorityOrder = [
      'selesai',
      'dikirim',
      'disetujui',
      'waktu_pengajuan',
    ];

    for (String key in priorityOrder) {
      if (waktuMap.containsKey(key) && waktuMap[key] != null) {
        return waktuMap[key].toString();
      }
    }

    return DateTime.now().toString().substring(0, 19);
  }

  // Apply filter to reports (tanpa filter kategori)
  void _applyFilter() {
    List<Map<String, dynamic>> filtered = _allReports;

    // Filter berdasarkan progress (dari modal button)
    if (_selectedProgressFilter != 'Semua') {
      filtered =
          filtered
              .where((report) => report['progress'] == _selectedProgressFilter)
              .toList();
    }

    // Filter berdasarkan pencarian
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((report) {
            final judulLaporan =
                report['judul_laporan'].toString().toLowerCase();
            final namaLengkap = report['nama_lengkap'].toString().toLowerCase();
            final emailPemohon =
                report['email_pemohon'].toString().toLowerCase();
            final address = report['address'].toString().toLowerCase();
            final tanggal = report['tanggal'].toString().toLowerCase();

            return judulLaporan.contains(query) ||
                namaLengkap.contains(query) ||
                emailPemohon.contains(query) ||
                address.contains(query) ||
                tanggal.contains(query);
          }).toList();
    }

    // Filter berdasarkan kategori lama (untuk filter tabs di luar - dari base code)
    if (_selectedFilter != 'Semua') {
      filtered =
          filtered
              .where((report) => report['category'] == _selectedFilter)
              .toList();
    }

    _filteredReports = filtered;
  }

  // Handle filter selection
  void _onFilterSelected(String filter) {
    setState(() {
      _selectedFilter = filter;
      _applyFilter();
    });
  }

  // Handle bottom navigation
  void _handleBottomNavigation(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeGeneral()),
        );
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
        // Already on laporan
        break;
    }
  }

  // Get status color based on progress (updated to match first code)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return const Color(0xFF4CAF50); // Hijau
      case 'Disetujui':
        return const Color(0xFF2196F3); // Biru
      case 'Dikirim':
        return const Color(0xFF9C27B0); // Ungu
      case 'Menunggu Persetujuan':
        return const Color(0xFFFF9800); // Orange
      case 'Gagal':
        return const Color(0xFFF44336); // Merah
      case 'Ditolak':
        return const Color(0xFF795548); // Coklat
      default:
        return const Color(0xFF9E9E9E); // Abu-abu
    }
  }

  // Navigate to detail laporan
  void _navigateToDetailLaporan(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => DetailLaporanPage(laporanData: report['data_lengkap']),
      ),
    );
  }

  // Build individual filter tab
  Widget _buildFilterTab(String option) {
    bool isSelected = _selectedFilter == option;

    return GestureDetector(
      onTap: () => _onFilterSelected(option),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF626F47) : const Color(0xFFECE8C8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFF8F8962), width: 1),
        ),
        child: Text(
          option,
          style: TextStyle(
            color:
                isSelected ? const Color(0xFFF9F3D1) : const Color(0xFF626F47),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Widget search bar (dari kode pertama)
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8F8962)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilter();
          });
        },
        decoration: const InputDecoration(
          hintText:
              'Cari berdasarkan nama, email, alamat, judul, atau tanggal...',
          hintStyle: TextStyle(color: Color(0xFF8F8962)),
          prefixIcon: Icon(Icons.search, color: Color(0xFF626F47)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(color: Color(0xFF626F47)),
      ),
    );
  }

  // Widget filter button (hanya progress filter, tanpa kategori)
  Widget _buildFilterButton() {
    bool hasActiveFilter = _selectedProgressFilter != 'Semua';

    return GestureDetector(
      onTap: _showFilterModal,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: hasActiveFilter ? const Color(0xFF626F47) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8F8962)),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.filter_alt_outlined,
                color: hasActiveFilter ? Colors.white : const Color(0xFF626F47),
                size: 24,
              ),
            ),
            if (hasActiveFilter)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menampilkan modal filter (hanya progress filter)
  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9F3D1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8F8962),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF626F47),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedProgressFilter = 'Semua';
                            });
                            setState(() {
                              _selectedProgressFilter = 'Semua';
                              _applyFilter();
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF626F47),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Progress
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pilih Status Progress:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF626F47),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _progressFilters.map((filter) {
                                final isSelected =
                                    _selectedProgressFilter == filter;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedProgressFilter = filter;
                                    });
                                    setState(() {
                                      _selectedProgressFilter = filter;
                                      _applyFilter();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFF626F47)
                                              : const Color(0xFFECE8C8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF626F47),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      filter,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            isSelected
                                                ? const Color(0xFFF9F3D1)
                                                : const Color(0xFF626F47),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // Apply Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF626F47),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Terapkan Filter',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFF9F3D1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper methods dari kode pertama
  String _getLatestDateFromWaktuProgress(Map<String, dynamic> waktuProgress) {
    try {
      DateTime? latestDate;
      String latestDateString = '';

      waktuProgress.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          final parsedDate = _parseWaktuPengajuan(value.toString());
          if (parsedDate != null) {
            if (latestDate == null || parsedDate.isAfter(latestDate!)) {
              latestDate = parsedDate;
              latestDateString = value.toString();
            }
          }
        }
      });

      if (latestDate != null) {
        return _formatTanggalIndonesia(latestDateString);
      }
    } catch (e) {
      print('Error getting latest date from waktu_progress: $e');
    }
    return 'Tanggal Tidak Diketahui';
  }

  DateTime? _parseWaktuPengajuan(String waktuPengajuan) {
    try {
      final parts = waktuPengajuan.split(' ');
      if (parts.length >= 2) {
        final datePart = parts[0];
        final timePart = parts[1];

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

  String _formatTanggalIndonesia(String waktuPengajuan) {
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
      print('Error formatting tanggal Indonesia: $e');
    }
    return waktuPengajuan;
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeGeneral(),
                        ),
                      );
                    },
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
                    'Laporan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF626F47),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar dan Filter Button (dari kode pertama)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  const SizedBox(width: 12),
                  _buildFilterButton(),
                ],
              ),
            ),

            // Filter Tabs (tetap mempertahankan layout original)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Check if screen is small (less than 500px width to accommodate all 5 tabs)
                  bool isSmallScreen = constraints.maxWidth < 500;

                  if (isSmallScreen) {
                    // Two rows layout for small screens
                    return Column(
                      children: [
                        // First row: Semua, Berhasil, Tertunda
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              _filterOptions.take(3).map((option) {
                                return Flexible(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: _buildFilterTab(option),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 8),
                        // Second row: Dikirim, Gagal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: _buildFilterTab(
                                _filterOptions[3],
                              ), // Dikirim
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: _buildFilterTab(
                                _filterOptions[4],
                              ), // Gagal
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Single row layout for larger screens
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            _filterOptions.map((option) {
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                child: _buildFilterTab(option),
                              );
                            }).toList(),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 20),

            // Reports List
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF626F47),
                        ),
                      )
                      : _filteredReports.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 64,
                              color: const Color(0xFF626F47).withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada laporan untuk kategori ${_selectedFilter.toLowerCase()}',
                              style: TextStyle(
                                color: const Color(0xFF626F47).withOpacity(0.7),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredReports.length,
                        itemBuilder: (context, index) {
                          Map<String, dynamic> report = _filteredReports[index];
                          return _buildReportItem(report);
                        },
                      ),
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

  // Updated report item widget to match first code's white design
  Widget _buildReportItem(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Changed to white background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8D1A8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul laporan
          Text(
            report['judul_laporan'] ?? 'Laporan Tidak Diketahui',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF626F47),
            ),
          ),

          const SizedBox(height: 8),

          // Nama lengkap
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Color(0xFF8F8962)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report['nama_pemohon'] ?? 'Nama Tidak Diketahui',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Address
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF8F8962)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report['address'] ?? 'Alamat Tidak Diketahui',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Email pemohon
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: Color(0xFF8F8962)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report['email_pemohon'] ?? 'Email Tidak Diketahui',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Tanggal laporan
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Color(0xFF8F8962),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  report['tanggal'] ?? 'Tanggal Tidak Diketahui',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ID Pengajuan dan Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${report['id_pengajuan'] ?? 'Tidak Diketahui'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8F8962),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                    report['progress'] ?? 'Tidak Diketahui',
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report['progress'] ?? 'Tidak Diketahui',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tombol Detail Laporan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _navigateToDetailLaporan(report);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF626F47),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Detail Laporan',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFF9F3D1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
