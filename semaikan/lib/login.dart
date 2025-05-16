import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'petugas distribusi/home.dart'; // Import file home.dart

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey untuk validasi form
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _kataSandiController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Auth
  bool _isLoading = false; // Status loading saat proses autentikasi
  String? _errorMessage; // Pesan error jika autentikasi gagal

  // Fungsi untuk melakukan autentikasi dengan Firebase
  Future<void> _signInWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Melakukan autentikasi dengan Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _kataSandiController.text,
      );

      // Jika autentikasi berhasil
      if (userCredential.user != null) {
        // Navigasi ke halaman Home setelah login berhasil
        if (mounted) {
          // Gunakan pushReplacement agar pengguna tidak bisa kembali ke halaman login
          // dengan tombol back setelah berhasil login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // Menangani error autentikasi Firebase
      setState(() {
        if (e.code == 'user-not-found') {
          _errorMessage = 'Email tidak terdaftar';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Kata sandi tidak valid';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'Format email tidak valid';
        } else if (e.code == 'too-many-requests') {
          _errorMessage = 'Terlalu banyak percobaan login. Coba lagi nanti';
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
      backgroundColor: const Color(0xFFF9F3D1), // Latar belakang sesuai warna
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
                        text: 'MASUK\n',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Input fields
                _buildTextField('Email', _emailController),
                const SizedBox(height: 15),
                _buildTextField(
                  'Kata Sandi',
                  _kataSandiController,
                  isPassword: true,
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

                // Tombol Masuk dengan indikator loading
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF8F8962))
                    : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          // Memanggil fungsi login Firebase
                          _signInWithEmailAndPassword();
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
                        'MASUK',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF9F3D1),
                        ),
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
        if (label == 'Email' && !_isValidEmail(value)) {
          return 'Masukkan format email yang valid';
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
    _emailController.dispose();
    _kataSandiController.dispose();
    super.dispose();
  }
}
