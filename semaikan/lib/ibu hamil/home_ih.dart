import 'package:flutter/material.dart';
import 'package:semaikan/maps.dart';
import 'package:semaikan/profile.dart';
import '../ibu hamil/distribusi_ih.dart';
import '../ibu hamil/laporan_ih.dart';
import '../petugas distribusi/notifikasi.dart'; // Import halaman Notifikasi
import 'package:firebase_auth/firebase_auth.dart';

class HomePageIH extends StatefulWidget {
  const HomePageIH({super.key});

  @override
  State<HomePageIH> createState() => _HomePageIHState();
}

class _HomePageIHState extends State<HomePageIH> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _userName = "Ibu Hamil"; // Default name
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo dan nama user
            Row(
              children: [
                // Logo
                Container(
                  height: 40,
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFF9F3D1),
                  size: 24,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Text(
          'Laporan Pengajuan Distribusi yang kamu ajukan telah dikonfirmasi, jangan lewatkan tanggalnya!',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF626F47),
            fontWeight: FontWeight.bold,
          ),
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
                      builder: (context) => const DistribusiPageIH(),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem('assets/img3.png', 'Pengajuan'),
              _buildStatusItem('assets/img1.png', 'Proses'),
              _buildStatusItem('assets/img2.png', 'Dikirim', isRed: true),
            ],
          ),
        ],
      ),
    );
  }

  // Widget Status Item
  Widget _buildStatusItem(
    String imagePath,
    String label, {
    bool isRed = false,
  }) {
    return Column(
      children: [
        Image.asset(
          imagePath,
          width: 40,
          height: 40,
          color: isRed ? Colors.red : null,
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isRed ? Colors.red : Colors.black)),
      ],
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
                  'Informasi Penting..',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF626F47),
                  ),
                ),
                Text(
                  'Bantuan akan didistribusikan pada 6 Mei 2025...',
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
        if (_currentIndex == index)
          return; // Hindari navigasi ke halaman yang sama

        setState(() {
          _currentIndex = index;
        });

        // Navigasi berdasarkan menu yang dipilih
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePageIH()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DistribusiPageIH()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MapsPage()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
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
