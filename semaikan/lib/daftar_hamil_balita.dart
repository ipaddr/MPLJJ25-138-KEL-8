import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_ip.dart';

class DaftarHamilBalitaScreen extends StatefulWidget {
  const DaftarHamilBalitaScreen({super.key});

  @override
  State<DaftarHamilBalitaScreen> createState() =>
      _DaftarHamilBalitaScreenState();
}

class _DaftarHamilBalitaScreenState extends State<DaftarHamilBalitaScreen> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey untuk validasi form
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _usiaKehamilanController =
      TextEditingController();
  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _tinggiBadanController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // Controller untuk email
  final TextEditingController _kataSandiController = TextEditingController();
  final TextEditingController _konfirmasiKataSandiController =
      TextEditingController(); // Controller untuk konfirmasi kata sandi

  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Auth
  bool _isLoading = false; // Status loading saat proses pendaftaran
  String? _errorMessage; // Pesan error jika pendaftaran gagal

  // Fungsi untuk mendaftar dengan Firebase
  Future<void> _registerWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Verifikasi apakah kata sandi dan konfirmasi kata sandi sama
    if (_kataSandiController.text != _konfirmasiKataSandiController.text) {
      setState(() {
        _errorMessage = 'Kata sandi dan konfirmasi kata sandi tidak cocok';
        _isLoading = false;
      });
      return;
    }

    try {
      // Mendaftarkan pengguna baru dengan Firebase
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _kataSandiController.text,
      );

      // Jika pendaftaran berhasil
      if (userCredential.user != null) {
        // Tambahkan data pengguna tambahan ke Firestore atau Realtime Database
        // Contoh: simpan data ibu hamil/balita ke database
        // Kode untuk menyimpan data dapat ditambahkan di sini

        if (mounted) {
          // Navigasi ke halaman login setelah pendaftaran berhasil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoginIPScreen(userType: 'hamil'),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'Kata sandi terlalu lemah';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email sudah digunakan oleh akun lain';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Format email tidak valid';
        } else {
          _errorMessage = 'Terjadi kesalahan: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: SingleChildScrollView(
        // Memungkinkan scroll jika konten terlalu panjang
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                          text: 'DAFTAR IBU HAMIL/BALITA\n',
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Input fields
                  _buildTextField('Nama Lengkap', _namaLengkapController),
                  const SizedBox(height: 15),
                  _buildTextField('NIK', _nikController),
                  const SizedBox(height: 15),
                  _buildTextField(
                    'Usia Kehamilan/Usia Balita',
                    _usiaKehamilanController,
                  ),
                  const SizedBox(height: 15),

                  // Row dengan 2 TextFields (Berat Badan dan Tinggi Badan)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Berat Badan Field
                      Expanded(
                        child: _buildTextField(
                          'Berat Badan',
                          _beratBadanController,
                        ),
                      ),
                      const SizedBox(
                        width: 15,
                      ), // Menambahkan jarak antar field
                      // Tinggi Badan Field
                      Expanded(
                        child: _buildTextField(
                          'Tinggi Badan',
                          _tinggiBadanController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Tambahkan field email di sini
                  _buildTextField('Email', _emailController, isEmail: true),
                  const SizedBox(height: 15),

                  // Field kata sandi
                  _buildTextField(
                    'Kata Sandi',
                    _kataSandiController,
                    isPassword: true,
                  ),
                  const SizedBox(height: 15),

                  // Tambahkan field konfirmasi kata sandi
                  _buildTextField(
                    'Konfirmasi Kata Sandi',
                    _konfirmasiKataSandiController,
                    isPassword: true,
                    isConfirmPassword: true,
                  ),

                  // Menampilkan pesan error jika ada
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Tombol Daftar dengan indikator loading
                  _isLoading
                      ? const CircularProgressIndicator(
                        color: Color(0xFF8F8962),
                      )
                      : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            // Memanggil fungsi registrasi Firebase
                            _registerWithEmailAndPassword();
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
                            color: Color(0xFFF9F3D1),
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
                              (context) => LoginIPScreen(
                                userType: 'hamil',
                              ), // Ganti dengan LoginScreen yang sesuai
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
      ),
    );
  }

  // Membuat text field yang digunakan dalam form
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    bool isEmail = false,
    bool isConfirmPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword, // Menyembunyikan teks jika itu adalah password
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
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

        if (isEmail && !_isValidEmail(value)) {
          return 'Masukkan format email yang valid';
        }

        if (isConfirmPassword && value != _kataSandiController.text) {
          return 'Konfirmasi kata sandi tidak cocok';
        }

        return null;
      },
    );
  }

  // Fungsi untuk validasi format email
  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  @override
  void dispose() {
    // Membersihkan semua controller saat widget di-dispose
    _namaLengkapController.dispose();
    _nikController.dispose();
    _usiaKehamilanController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    _emailController.dispose();
    _kataSandiController.dispose();
    _konfirmasiKataSandiController.dispose();
    super.dispose();
  }
}
