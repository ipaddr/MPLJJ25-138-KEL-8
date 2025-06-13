import 'package:flutter/material.dart';
import 'package:semaikan/Screen%20Bersama/maps.dart';
import 'package:semaikan/Screen%20Bersama/tracking_distribusi.dart'; // Import halaman tracking
import 'home.dart';
import 'laporan.dart';

class DistribusiPage extends StatefulWidget {
  const DistribusiPage({super.key});

  @override
  State<DistribusiPage> createState() => _DistribusiPageState();
}

class _DistribusiPageState extends State<DistribusiPage> {
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
                'status': 'Dalam Perjalanan',
                'statusColor': Colors.blue,
              }),
              const SizedBox(height: 16),
              _buildLaporanItem({
                'id': 'DIS002',
                'title': 'Laporan Pesantren Nusa Bangsa',
                'date': '18 April 2025',
                'status': 'Selesai',
                'statusColor': Colors.green,
              }),
              const SizedBox(height: 16),
              _buildLaporanItem({
                'id': 'DIS003',
                'title': 'Laporan Ny. Siti Aisyah',
                'date': '01 April 2025',
                'status': 'Selesai',
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
          icon: Icons.check_circle_outline,
          title: '1,125',
          subtitle: 'Distribusi sudah berhasil dilaksanakan.',
          color: const Color(0xFF626F47),
          label: 'Berhasil',
        ),

        // Kartu Gagal
        _buildStatusCard(
          icon: Icons.cancel_outlined,
          title: '89',
          subtitle: 'Distribusi mengalami kegagalan.',
          color: Colors.red,
          label: 'Gagal',
        ),

        // Kartu Tertunda
        _buildStatusCard(
          icon: Icons.access_time,
          title: '125',
          subtitle: 'Distribusi sedang dalam masa proses.',
          color: const Color(0xFF626F47),
          label: 'Tertunda',
        ),

        // Kartu Jumlah Penerima
        _buildStatusCard(
          icon: Icons.people_outline,
          title: '2034',
          subtitle: 'tempat telah menerima distribusi makanan.',
          color: const Color(0xFF626F47),
          label: '',
        ),
      ],
    );
  }

  // Widget untuk setiap kartu status
  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xFFF9F3D1), size: 18),
              ),
              const SizedBox(width: 5),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Color(0xFF626F47)),
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                    fontSize: 16,
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
                  decoration: BoxDecoration(
                    color: (data['statusColor'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: data['statusColor'] as Color,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    data['status'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: data['statusColor'] as Color,
                    ),
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
          // Menu Home
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (index == 1) {
          // Menu Distribusi
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DistribusiPage()),
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
