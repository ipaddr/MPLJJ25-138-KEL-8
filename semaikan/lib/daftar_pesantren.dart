import 'package:flutter/material.dart';
import 'login_ip.dart';

class DaftarPesantrenScreen extends StatefulWidget {
  const DaftarPesantrenScreen({super.key});

  @override
  State<DaftarPesantrenScreen> createState() => _DaftarPesantrenScreenState();
}

class _DaftarPesantrenScreenState extends State<DaftarPesantrenScreen> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey untuk validasi form
  final TextEditingController _namaSekolahController = TextEditingController();
  final TextEditingController _npsnController = TextEditingController();
  final TextEditingController _alamatSekolahController =
      TextEditingController();
  final TextEditingController _emailSekolahController = TextEditingController();
  final TextEditingController _kataSandiController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey, // Menambahkan Form dengan key untuk validasi
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Teks dengan RichText untuk dua baris
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 20, color: Color(0xFF626F47)),
                    children: [
                      TextSpan(
                        text: 'DAFTAR SEKOLAH/PESANTREN\n',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ), // Menambah jarak antara teks dan input field
                // Input fields
                _buildTextField('Nama Sekolah', _namaSekolahController),
                const SizedBox(height: 15),
                _buildTextField('Nomor NPSN', _npsnController),
                const SizedBox(height: 15),
                _buildTextField('Alamat Sekolah', _alamatSekolahController),
                const SizedBox(height: 15),
                _buildTextField('Email Sekolah', _emailSekolahController),
                const SizedBox(height: 15),
                _buildTextField(
                  'Kata Sandi',
                  _kataSandiController,
                  isPassword: true,
                ),

                const SizedBox(
                  height: 30,
                ), // Menambah jarak antara input field dan tombol
                // Tombol Daftar
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Jika form valid, lakukan navigasi ke LoginIPScreen setelah pendaftaran
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const LoginIPScreen(userType: 'sekolah'),
                        ), // Arahkan ke halaman Login
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8F8962),
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 50,
                    ),
                  ),
                  child: const Text(
                    'DAFTAR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(
                        0xFFF9F3D1,
                      ), // Warna teks sesuai dengan warna background tombol
                    ),
                  ),
                ),

                // Tambahkan link untuk mengarahkan ke login jika sudah punya akun
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => LoginIPScreen(userType: 'sekolah'),
                      ),
                    );
                  },
                  child: const Text(
                    'Sudah Punya Akun? Masuk',
                    style: TextStyle(fontSize: 16, color: Color(0xFF626F47)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Membuat text field yang digunakan dalam form
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword, // Menyembunyikan teks jika itu adalah password
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: const Color(0xFFD8D1A8), // Warna latar belakang input
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field ini harus diisi'; // Validasi input kosong
        }
        return null;
      },
    );
  }
}
