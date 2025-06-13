import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/floating_bottom_navbar.dart';
import 'distribusi.dart';
import 'pengajuan.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'home_general.dart';
import '../Screen Bersama/detail_laporan.dart';

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
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = true;

  final List<String> _filterOptions = [
    'Semua',
    'Berhasil',
    'Tertunda',
    'Dikirim',
    'Gagal',
  ];

  @override
  void initState() {
    super.initState();
    _loadReports();
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

          data['category'] = category;
          data['display_date'] = latestDate;

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

  // Apply filter to reports
  void _applyFilter() {
    if (_selectedFilter == 'Semua') {
      _filteredReports = List.from(_allReports);
    } else {
      _filteredReports =
          _allReports
              .where((report) => report['category'] == _selectedFilter)
              .toList();
    }
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

  // Get status color based on category
  Color _getStatusColor(String category) {
    switch (category) {
      case 'Berhasil':
        return Colors.green;
      case 'Dikirim':
        return Colors.blue;
      case 'Tertunda':
        return Colors.orange;
      case 'Gagal':
        return Colors.red;
      default:
        return const Color(0xFF626F47);
    }
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

  // Format date for display (11 Juni 2025)
  String _formatDisplayDate(String dateString) {
    try {
      DateTime date = _parseIndonesianDate(dateString);
      List<String> months = [
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
      return '${date.day} ${months[date.month]} ${date.year}';
    } catch (e) {
      return dateString.split(' ')[0]; // Return date part only
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

            // Filter Tabs
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

  Widget _buildReportItem(Map<String, dynamic> report) {
    String title =
        report['judul_laporan']?.toString() ?? 'Laporan Tidak Diketahui';
    String date = _formatDisplayDate(report['display_date'] ?? '');
    String category = report['category'] ?? 'Tertunda';
    String progress = report['progress']?.toString() ?? 'Menunggu Persetujuan';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFECE8C8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
      ),
      child: Row(
        children: [
          // Document Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F3D1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8F8962), width: 1),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF626F47),
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Report Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF626F47).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Lihat Detail Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF626F47),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to detail page
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => DetailLaporanPage(laporanData: report),
                          //   ),
                          // );

                          // Temporary: Show snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Detail laporan: $title'),
                              backgroundColor: const Color(0xFF626F47),
                            ),
                          );
                        },
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            color: Color(0xFFF9F3D1),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(category),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        progress,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
