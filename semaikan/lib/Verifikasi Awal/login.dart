import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Screen Khusus Petugas/home.dart'; // Import file home.dart

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // GlobalKey untuk validasi form
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _kataSandiController = TextEditingController();
  final TextEditingController _konfirmasiKataSandiController =
      TextEditingController();
  final TextEditingController _namaLengkapController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Auth
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore
  bool _isLoading = false; // Status loading saat proses autentikasi
  String? _errorMessage; // Pesan error jika autentikasi gagal

  // State untuk mode daftar petugas distribusi
  bool _isRegisterMode = false;
  bool _registerModeActivated = false;

  @override
  void initState() {
    super.initState();
    // Listener untuk mendeteksi kata kunci daftar petugas distribusi
    _emailController.addListener(_checkRegisterKeyword);
  }

  // Fungsi untuk mengecek kata kunci daftar petugas distribusi
  void _checkRegisterKeyword() {
    // Jika kata kunci terdeteksi, aktifkan mode daftar
    if (_emailController.text == "daftar_petugas_distribusi" &&
        !_registerModeActivated) {
      setState(() {
        _isRegisterMode = true;
        _registerModeActivated = true;
        // Reset error message ketika mode berubah
        _errorMessage = null;
      });
    }
  }

  // Fungsi untuk mendapatkan tanggal dan waktu dalam format WIB
  String _getCurrentDateTimeWIB() {
    final now = DateTime.now();
    // Menambahkan 7 jam untuk konversi ke WIB (UTC+7)
    final wibTime = now.add(const Duration(hours: 7));
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return '${formatter.format(wibTime)}WIB';
  }

  // Fungsi untuk menyimpan data petugas distribusi ke Firestore
  Future<void> _savePetugasDistribusiDataToFirestore(
    String userId,
    String email,
  ) async {
    try {
      await _firestore.collection('Account_Storage').doc(userId).set({
        'email': email,
        'account_category': 'petugas_distribusi',
        'profile_picture': '', // Kosong untuk sementara
        'date_registry': _getCurrentDateTimeWIB(),
        'nama_lengkap': _namaLengkapController.text.trim(),
      });
    } catch (e) {
      print('Error saving petugas distribusi data to Firestore: $e');
      throw e; // Re-throw error untuk ditangani di fungsi pemanggil
    }
  }

  // Fungsi untuk mendaftar petugas distribusi
  Future<void> _registerPetugasDistribusi() async {
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
        // Tunggu sebentar untuk memastikan autentikasi selesai
        await Future.delayed(const Duration(milliseconds: 500));

        // Simpan data petugas distribusi ke Firestore
        await _savePetugasDistribusiDataToFirestore(
          userCredential.user!.uid,
          _emailController.text.trim(),
        );

        if (mounted) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrasi petugas distribusi berhasil! Silakan login dengan akun baru Anda.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );

          // Reset ke mode login setelah registrasi berhasil
          setState(() {
            _isRegisterMode = false;
            _registerModeActivated = false;
            // Simpan email untuk login
            String registeredEmail = _emailController.text.trim();
            // Clear semua field
            _emailController.clear();
            _kataSandiController.clear();
            _konfirmasiKataSandiController.clear();
            _namaLengkapController.clear();
            _errorMessage = null;
            // Set email yang baru didaftarkan ke field email untuk memudahkan login
            _emailController.text = registeredEmail;
          });
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
    } on FirebaseException catch (e) {
      setState(() {
        if (e.code == 'permission-denied') {
          _errorMessage =
              'Tidak memiliki izin untuk menyimpan data. Silakan coba lagi.';
        } else {
          _errorMessage = 'Terjadi kesalahan Firestore: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat menyimpan data: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
      body: _isRegisterMode ? _buildRegisterLayout() : _buildLoginLayout(),
    );
  }

  // Layout untuk mode login normal (center)
  Widget _buildLoginLayout() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Teks MASUK
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

              // Input fields untuk login
              _buildTextField('Email', _emailController, isEmail: true),
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

              // Tombol Masuk
              _isLoading
                  ? const CircularProgressIndicator(color: Color(0xFF8F8962))
                  : ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
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
    );
  }

  // Layout untuk mode daftar petugas distribusi (scrollable)
  Widget _buildRegisterLayout() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Teks DAFTAR PETUGAS DISTRIBUSI
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 20, color: Color(0xFF626F47)),
                    children: [
                      TextSpan(
                        text: 'DAFTAR PETUGAS DISTRIBUSI\n',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Input fields untuk daftar
                _buildTextField('Nama Lengkap', _namaLengkapController),
                const SizedBox(height: 15),
                _buildTextField('Email', _emailController, isEmail: true),
                const SizedBox(height: 15),
                _buildTextField(
                  'Kata Sandi',
                  _kataSandiController,
                  isPassword: true,
                ),
                const SizedBox(height: 15),
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

                // Tombol Daftar
                _isLoading
                    ? const CircularProgressIndicator(color: Color(0xFF8F8962))
                    : ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _registerPetugasDistribusi();
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

                // Spacer untuk mendorong konten ke bawah
                const SizedBox(height: 50),

                // Mode indicator dan reset button di bagian bawah
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Mode: Daftar Petugas Distribusi terdeteksi',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isRegisterMode = false;
                            _registerModeActivated = false;
                            _emailController.clear();
                            _kataSandiController.clear();
                            _konfirmasiKataSandiController.clear();
                            _namaLengkapController.clear();
                            _errorMessage = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Reset ke Mode Login',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
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
        // Skip validasi untuk field yang tidak diperlukan berdasarkan mode
        if (_isRegisterMode) {
          // Dalam mode register, semua field wajib diisi
          if (value == null || value.isEmpty) {
            return 'Field ini harus diisi';
          }
        } else {
          // Dalam mode login, skip validasi untuk field register
          if (controller == _namaLengkapController ||
              controller == _konfirmasiKataSandiController) {
            return null;
          }
          if (value == null || value.isEmpty) {
            return 'Field ini harus diisi';
          }
        }

        if (isEmail &&
            !_isValidEmail(value) &&
            value != "daftar_petugas_distribusi") {
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
    _emailController.dispose();
    _kataSandiController.dispose();
    _konfirmasiKataSandiController.dispose();
    _namaLengkapController.dispose();
    super.dispose();
  }
}
