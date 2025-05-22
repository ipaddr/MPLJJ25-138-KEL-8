import 'package:flutter/material.dart';
import 'package:semaikan/maps.dart';
import 'package:semaikan/tracking_distribusi.dart'; // Import halaman tracking
import '../pesantren/home_p.dart';
import '../pesantren/laporan_p.dart';
import '../pengajuan.dart';

class DistribusiPageP extends StatefulWidget {
  const DistribusiPageP({super.key});

  @override
  State<DistribusiPageP> createState() => _DistribusiPagePState();
}

class _DistribusiPagePState extends State<DistribusiPageP> {
  int _currentIndex = 1; // Index 1 untuk halaman distribusi di bottom nav

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
          'Distribusi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Distribusi Cards
              _buildStatusCards(),

              const SizedBox(height: 24),

              // Proses Distribusi
              const Text(
                'Proses Distribusi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF626F47),
                ),
              ),

              const SizedBox(height: 16),

              // Laporan distribusi list dengan data tracking
              _buildLaporanItem({
                'id': 'DIS001',
                'title': 'Laporan SMAN 1 Kota Padang',
                'date': '22 April 2025',
                'statusColor': Colors.blue,
              }),
              const SizedBox(height: 16),
              _buildLaporanItem({
                'id': 'DIS002',
                'title': 'Laporan Pesantren Nusa Bangsa',
                'date': '18 April 2025',
                'statusColor': Colors.green,
              }),
              const SizedBox(height: 16),
              _buildLaporanItem({
                'id': 'DIS003',
                'title': 'Laporan Ny. Siti Aisyah',
                'date': '01 April 2025',
                'statusColor': Colors.green,
              }),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Widget untuk menampilkan 4 kartu status distribusi
  Widget _buildStatusCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.8,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        // Kartu Berhasil
        _buildStatusCard(
          imagePath: 'assets/img4.png',
          title: 'Diterima',
          subtitle: 'Distribusi sudah berhasil dilaksanakan.',
          label: '1.125 ',
        ),

        // Kartu Gagal
        _buildStatusCard(
          imagePath: 'assets/img7.png',
          title: 'Gagal',
          subtitle: 'Distribusi mengalami kegagalan.',
          label: '89',
        ),

        // Kartu Tertunda
        _buildStatusCard(
          imagePath: 'assets/img5.png',
          title: 'Tertunda',
          subtitle: 'Distribusi sedang dalam masa proses.',
          label: '125',
        ),

        // Kartu Jumlah Penerima
        _buildStatusCard(
          imagePath: 'assets/img6.png',
          title: 'Berhasil',
          subtitle: 'tempat telah menerima distribusi makanan.',
          label: '2034',
        ),
      ],
    );
  }

  // Widget untuk setiap kartu status
  Widget _buildStatusCard({
    required String imagePath,
    required String title,
    required String subtitle,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFECE8C8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(imagePath, width: 20, height: 20),
                ),
              ),
              const SizedBox(width: 5),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 10, color: Color(0xFF626F47)),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                TextSpan(text: subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk setiap item laporan dengan tracking
  Widget _buildLaporanItem(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3D1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
      ),
      child: Row(
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

          // Informasi laporan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['date'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF626F47),
                  ),
                ),
                const SizedBox(height: 8),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ],
            ),
          ),

          // Tombol LACAK dengan navigasi ke tracking
          GestureDetector(
            onTap: () {
              // Navigasi ke halaman tracking
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TrackingDistribusiPage(distribusiData: data),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFD8D1A8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.location_on, size: 16, color: Color(0xFF626F47)),
                  SizedBox(width: 4),
                  Text(
                    'LACAK',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF626F47),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
        if (index == 0) {
          // Menu Home
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePageP()),
          );
        } else if (index == 1) {
          // Menu Distribusi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DistribusiPageP()),
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
            MaterialPageRoute(builder: (context) => const LaporanPageP()),
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
