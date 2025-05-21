import 'package:flutter/material.dart';
import 'package:semaikan/maps.dart';
import '../detail_laporan.dart'; // Import halaman detail laporan
import '../ibu hamil/home_ih.dart';
import '../ibu hamil/distribusi_ih.dart';
import '../pengajuan.dart';

class LaporanPageIH extends StatefulWidget {
  const LaporanPageIH({super.key});

  @override
  State<LaporanPageIH> createState() => _LaporanPageIHState();
}

class _LaporanPageIHState extends State<LaporanPageIH> {
  int _currentIndex = 3; // Index 3 untuk halaman laporan di bottom nav
  String _selectedFilter = 'Semua'; // Filter terpilih, default 'Semua'

  // Daftar filter yang tersedia
  final List<String> _filters = ['Semua', 'Berhasil', 'Tertunda', 'Gagal'];

  // Daftar data laporan (contoh data statis dengan detail lengkap)
  final List<Map<String, dynamic>> _allReports = [
    {
      'id': 'LP001',
      'title': 'Laporan Posyandu Mawar',
      'date': '29 April 2025',
      'status': 'Berhasil',
      'type': 'Sekolah',
      'jumlahMakanan': 250,
      'jenisMakanan': 'Makanan Bergizi Lengkap',
      'lokasi': 'SMAN 1 Kota Padang',
      'waktuDistribusi': '08:00 - 12:00',
      'jumlahPenerima': 150,
      'kategori': 'Siswa Sekolah',
      'kondisiPenerima': 'Sehat dan aktif',
      'koordinator': 'Bpk. Ahmad Susanto',
      'noTelepon': '081234567890',
      'keterangan':
          'Distribusi makanan bergizi untuk siswa SMAN 1 Kota Padang berjalan lancar. Semua siswa mendapatkan porsi yang sama dan terlihat antusias menerima makanan. Tidak ada kendala berarti selama proses distribusi. Tim distribusi bekerja dengan baik dan koordinasi dengan pihak sekolah sangat baik.',
    },
    {
      'id': 'LP002',
      'title': 'Laporan Posyandu Melati',
      'date': '22 April 2025',
      'status': 'Tertunda',
      'type': 'Pesantren',
      'jumlahMakanan': 300,
      'jenisMakanan': 'Menu Halal Bergizi',
      'lokasi': 'Pesantren Nusa Bangsa',
      'waktuDistribusi': '12:00 - 15:00',
      'jumlahPenerima': 200,
      'kategori': 'Santri',
      'kondisiPenerima': 'Sehat',
      'koordinator': 'Ustadz Rahman',
      'noTelepon': '081987654321',
      'keterangan':
          'Distribusi makanan untuk santri Pesantren Nusa Bangsa. Proses distribusi berjalan sesuai jadwal sholat. Makanan disajikan dalam wadah bersih dan higienis. Santri menerima dengan tertib dan berdoa sebelum makan.',
    },
    {
      'id': 'LP003',
      'title': 'Laporan Posyandu Tulip',
      'date': '16 April 2025',
      'status': 'Berhasil',
      'type': 'Ibu Hamil',
      'jumlahMakanan': 50,
      'jenisMakanan': 'Makanan Khusus Ibu Hamil',
      'lokasi': 'Puskesmas Koto Tangah',
      'waktuDistribusi': '09:00 - 11:00',
      'jumlahPenerima': 25,
      'kategori': 'Ibu Hamil',
      'kondisiPenerima': 'Sehat dengan kehamilan normal',
      'koordinator': 'Dr. Sari',
      'noTelepon': '081567890123',
      'keterangan':
          'Distribusi makanan khusus untuk ibu hamil telah dilaksanakan dengan baik. Menu disesuaikan dengan kebutuhan gizi ibu hamil. Setiap ibu hamil mendapat konsultasi gizi singkat dari petugas kesehatan.',
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
                return _buildReportItem(report);
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

  // Widget untuk item laporan (diperbarui dengan navigasi ke detail)
  Widget _buildReportItem(Map<String, dynamic> report) {
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
                  report['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),

                // Tanggal
                const SizedBox(height: 4),
                Text(
                  report['date'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                  ),
                ),

                // Tombol aksi
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Tombol Lihat Detail (dengan navigasi ke halaman detail)
                    GestureDetector(
                      onTap: () {
                        // Navigasi ke halaman detail laporan
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    DetailLaporanPage(laporanData: report),
                          ),
                        );
                      },
                      child: Container(
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
                        'Pengajuan ${report['status']}',
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
          _buildNavItem(Icons.add, 'Pengajuan', 2),
          _buildNavItem(Icons.map, 'Maps', 3),
          _buildNavItem(Icons.assignment, 'Laporan', 4),
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
        // Navigasi berdasarkan menu yang dipilih
        if (index == 0) {
          // Menu Home
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePageIH()),
          );
        } else if (index == 1) {
          // Menu Laporan
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DistribusiPageIH()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PengajuanPage()),
          );
        } else if (index == 2) {
          // Menu Laporan
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapsPage()),
          );
        } else if (index == 3) {
          // Menu Laporan
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LaporanPageIH()),
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
