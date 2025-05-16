import 'package:flutter/material.dart';
import 'package:semaikan/petugas%20distribusi/home.dart';
import 'package:semaikan/petugas%20distribusi/distribusi.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  int _currentIndex = 3; // Index 3 untuk halaman laporan di bottom nav
  String _selectedFilter = 'Semua'; // Filter terpilih, default 'Semua'

  // Daftar filter yang tersedia
  final List<String> _filters = ['Semua', 'Berhasil', 'Tertunda', 'Gagal'];

  // Daftar data laporan (contoh data statis)
  final List<Map<String, dynamic>> _allReports = [
    {
      'title': 'Laporan SMAN 1 Kota Padang',
      'date': '22 April 2025',
      'status': 'Berhasil',
    },
    {
      'title': 'Laporan Pesantren Nusa Bangsa',
      'date': '18 April 2025',
      'status': 'Tertunda',
    },
    {
      'title': 'Laporan Ny. Siti Aisyah',
      'date': '01 April 2025',
      'status': 'Berhasil',
    },
    {
      'title': 'Laporan Balita Siti Aminah',
      'date': '23 Maret 2025',
      'status': 'Gagal',
    },
    {
      'title': 'Laporan Pesantren Hati Ibu',
      'date': '01 Maret 2025',
      'status': 'Berhasil',
    },
    {
      'title': 'Laporan Pesantren Hati Ibu',
      'date': '01 Maret 2025',
      'status': 'Tertunda',
    },
  ];

  // Laporan yang difilter berdasarkan status terpilih
  List<Map<String, dynamic>> get _filteredReports {
    if (_selectedFilter == 'Semua') {
      return _allReports;
    } else {
      return _allReports
          .where((report) => report['status'] == _selectedFilter)
          .toList();
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
          'Laporan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildFilterChips(),
          ),

          // Daftar laporan
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredReports.length,
              itemBuilder: (context, index) {
                final report = _filteredReports[index];
                return _buildReportItem(
                  title: report['title'],
                  date: report['date'],
                  status: report['status'],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Widget filter chip
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            _filters.map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
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
                ),
              );
            }).toList(),
      ),
    );
  }

  // Widget untuk item laporan
  Widget _buildReportItem({
    required String title,
    required String date,
    required String status,
  }) {
    // Menentukan warna tombol status
    Color statusButtonColor = const Color(0xFF626F47);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD8D1A8), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon dokumen
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

          const SizedBox(width: 12),

          // Informasi laporan dan tombol
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul laporan
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),

                // Tanggal
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                  ),
                ),

                // Tombol aksi
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Tombol Lihat Detail
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF626F47),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF9F3D1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tombol Status Pengajuan
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF626F47),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pengajuan $status',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFF9F3D1),
                          fontWeight: FontWeight.bold,
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

  // Widget Bottom Navigation Bar
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

  // Widget Navigation Item
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });

        // Navigasi berdasarkan menu yang dipilih
        if (index == 0) {
          // Menu Distribusi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }

        if (index == 1) {
          // Menu Distribusi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DistribusiPage()),
          );
        }

        if (index == 3) {
          // Menu Distribusi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LaporanPage()),
          );
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
