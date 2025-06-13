import 'package:flutter/material.dart';
import 'package:semaikan/Verifikasi%20Awal/daftar_hamil_balita.dart';
import 'package:semaikan/Verifikasi%20Awal/daftar_pesantren.dart';
import 'package:semaikan/Verifikasi%20Awal/login.dart';

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF9F3D1,
      ), // Latar belakang sesuai dengan warna
      body: Center(
        // Menggunakan Center untuk memastikan seluruh konten berada di tengah
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ), // Menambahkan sedikit padding horisontal untuk estetika
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center, // Menyusun elemen di tengah secara vertikal
            crossAxisAlignment:
                CrossAxisAlignment
                    .center, // Menjaga konten tetap terpusat secara horizontal
            children: [
              const SizedBox(
                height: 20,
              ), // Menambahkan jarak dengan bagian atas
              // Teks dengan RichText untuk dua baris
              RichText(
                textAlign: TextAlign.center, // Menyusun teks di tengah
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF626F47), // Warna teks sesuai permintaan
                  ),
                  children: [
                    TextSpan(
                      text:
                          'DAFTAR PENGGUNA\n', // Teks pertama dengan baris baru
                      style: TextStyle(
                        fontSize: 30, // Ukuran font lebih besar untuk judul
                        fontWeight: FontWeight.bold, // Menebalkan teks
                      ),
                    ),
                    TextSpan(
                      text:
                          'Pilih daftar pengguna sesuai kebutuhan', // Teks kedua
                      style: TextStyle(
                        fontSize: 20, // Ukuran font yang lebih kecil
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ), // Menambah jarak antara teks dan tombol
              // Tombol untuk memilih daftar pengguna
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DaftarPesantrenScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFD8D1A8,
                  ), // Warna tombol sesuai permintaan
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 48,
                  ), // Menambahkan padding pada tombol
                  textStyle: const TextStyle(
                    fontSize: 18, // Menyesuaikan ukuran font pada tombol
                    fontWeight:
                        FontWeight.normal, // Menebalkan teks pada tombol
                  ),
                ),
                child: const Text('Sekolah /Pesantren'),
              ),

              const SizedBox(height: 20), // Jarak antar tombol

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DaftarHamilBalitaScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFD8D1A8,
                  ), // Warna tombol sesuai permintaan
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 60,
                  ), // Menambahkan padding pada tombol
                  textStyle: const TextStyle(
                    fontSize: 18, // Menyesuaikan ukuran font pada tombol
                    fontWeight:
                        FontWeight.normal, // Menebalkan teks pada tombol
                  ),
                ),
                child: const Text('Ibu Hamil/Balita'),
              ),

              const SizedBox(height: 20), // Jarak antar tombol

              ElevatedButton(
                onPressed: () {
                  // Arahkan ke halaman LoginScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFD8D1A8,
                  ), // Warna tombol sesuai permintaan
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 50,
                  ), // Menambahkan padding pada tombol
                  textStyle: const TextStyle(
                    fontSize: 18, // Menyesuaikan ukuran font pada tombol
                    fontWeight:
                        FontWeight.normal, // Menebalkan teks pada tombol
                  ),
                ),
                child: const Text('Petugas Distribusi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
