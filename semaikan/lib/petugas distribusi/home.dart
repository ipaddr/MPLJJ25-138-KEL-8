import 'package:flutter/material.dart';
import 'package:semaikan/maps.dart';
import 'package:semaikan/profile.dart';
import '../petugas distribusi/distribusi.dart';
import '../petugas distribusi/laporan.dart';
import '../petugas distribusi/notifikasi.dart'; // Import halaman Notifikasi
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = "Rawim"; // Default name
  int _currentIndex = 0; // Untuk bottom navigation

  @override
  void initState() {
    super.initState();
    // Mendapatkan nama pengguna dari Firebase Auth
    _getUserName();
  }

  // Mendapatkan nama pengguna dari Firebase
  Future<void> _getUserName() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      // Jika ada data display name, gunakan itu
      // Jika tidak, gunakan email atau default
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        setState(() {
          _userName =
              user.displayName!.split(' ')[0]; // Ambil nama pertama saja
        });
      } else if (user.email != null) {
        setState(() {
          _userName = user.email!.split('@')[0]; // Gunakan username dari email
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header dengan Nama User dan Profil
                _buildHeader(),

                const SizedBox(height: 20),

                // Grafik Distribusi
                _buildDistributionChart(),

                const SizedBox(height: 20),

                // Status Distribusi Card
                _buildStatusCard(),

                const SizedBox(height: 20),

                // Riwayat Pemberitahuan Card
                _buildNotificationHistoryCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Widget Header dengan nama user dan ikon profil
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo dan nama user
        Row(
          children: [
            // Logo
            Container(
              height: 40,
              width: 70,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: Image.asset(
                'assets/splashscreen.png', // Pastikan logo ada di assets
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
            // Teks Hai, {nama}
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

        // Ikon profil
        GestureDetector(
          onTap: () {
            // Navigasi ke halaman profil
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          },
          child: Container(
            height: 40,
            width: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF626F47),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFFF9F3D1), size: 24),
          ),
        ),
      ],
    );
  }

  // Widget Grafik Distribusi
  Widget _buildDistributionChart() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF9F3D1),
      ),
      child: Column(
        children: [
          // Data Grafik
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Maret 2023
              _buildChartBar('947', 0.35, 'Distribusi Maret\n2023'),

              // Juni 2023
              _buildChartBar('1250', 0.55, 'Distribusi Juni\n2023'),

              // Juli 2023
              _buildChartBar('2034', 0.75, 'Distribusi Juli\n2023'),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Bar untuk Grafik
  Widget _buildChartBar(String value, double height, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
        const Text(
          'MBG\nterdistribusi',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Color(0xFF626F47)),
        ),
        const SizedBox(height: 5),
        Container(
          width: 80,
          height: 150 * height,
          decoration: const BoxDecoration(
            color: Color(0xFF626F47),
            borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFF626F47)),
        ),
      ],
    );
  }

  // Widget Status Distribusi Card
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3D1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
      ),
      child: Column(
        children: [
          // Header dengan judul dan tombol Lihat Semua
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
                onPressed: () {
                  // Navigasi ke halaman distribusi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DistribusiPage(),
                    ),
                  );
                },
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

          // Status icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(Icons.check_circle_outline, 'Berhasil'),
              _buildStatusItem(Icons.access_time, 'Tertunda'),
              _buildStatusItem(Icons.cancel_outlined, 'Gagal', isRed: true),
              _buildStatusItem(Icons.people_outline, 'Jumlah Penerima'),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Status Item
  Widget _buildStatusItem(IconData icon, String label, {bool isRed = false}) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman distribusi saat status diklik
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DistribusiPage()),
        );
      },
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRed ? Colors.red : const Color(0xFF626F47),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFF9F3D1), size: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF626F47)),
          ),
        ],
      ),
    );
  }

  // Widget Riwayat Pemberitahuan Card
  Widget _buildNotificationHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F3D1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8F8962), width: 1),
      ),
      child: Column(
        children: [
          // Header dengan judul dan tombol Lihat Semua
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
                onPressed: () {
                  // Navigasi ke halaman notifikasi
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotifikasiPage(),
                    ),
                  );
                },
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

          // Daftar notifikasi
          _buildNotificationItem(),
          const Divider(color: Color(0xFF8F8962), height: 1),
          _buildNotificationItem(),
          const Divider(color: Color(0xFF8F8962), height: 1),
          _buildNotificationItem(),
        ],
      ),
    );
  }

  // Widget Notification Item
  Widget _buildNotificationItem() {
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
              children: const [
                Text(
                  'Pengajuan Distribusi Perlu Kon...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                Text(
                  'Laporan pengajuan pada tanggal 4 April...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF626F47)),
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
        if (index == 1) {
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
        // Implementasi navigasi ke halaman lain
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
