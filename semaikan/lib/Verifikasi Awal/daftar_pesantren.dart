import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'login_ip.dart'; // Pastikan login_ip.dart sudah ada di proyek Anda

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
  final TextEditingController _konfirmasiKataSandiController =
      TextEditingController(); // Tambahan untuk konfirmasi kata sandi

  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Auth
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Instance Firestore
  bool _isLoading = false; // Status loading saat proses pendaftaran
  String? _errorMessage; // Pesan error jika pendaftaran gagal

  // Fungsi untuk mendapatkan tanggal dan waktu dalam format WIB
  String _getCurrentDateTimeWIB() {
    final now = DateTime.now();
    // Menambahkan 7 jam untuk konversi ke WIB (UTC+7)
    final wibTime = now.add(const Duration(hours: 7));
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return '${formatter.format(wibTime)}WIB';
  }

  // Fungsi untuk menyimpan data sekolah/pesantren ke Firestore
  Future<void> _saveSchoolDataToFirestore(String userId, String email) async {
    try {
      await _firestore.collection('Account_Storage').doc(userId).set({
        'email': email,
        'account_category': 'sekolah_pesantren',
        'profile_picture':
            '', // Kosong untuk sementara, bisa diisi default atau diupdate nanti
        'date_registry': _getCurrentDateTimeWIB(),
        // Menambahkan data lengkap dari form registrasi sekolah/pesantren
        'nama_lengkap': _namaSekolahController.text.trim(),
        'npsn': _npsnController.text.trim(),
        'alamat_sekolah': _alamatSekolahController.text.trim(),
      });
    } catch (e) {
      print('Error saving school data to Firestore: $e');
      rethrow; // Re-throw error untuk ditangani di fungsi pemanggil
    }
  }

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
        email: _emailSekolahController.text.trim(),
        password: _kataSandiController.text,
      );

      // Jika pendaftaran berhasil
      if (userCredential.user != null) {
        // Tunggu sebentar untuk memastikan autentikasi selesai
        await Future.delayed(const Duration(milliseconds: 500));

        // Simpan data sekolah/pesantren ke Firestore
        await _saveSchoolDataToFirestore(
          userCredential.user!.uid, // UUID dari Firebase Auth
          _emailSekolahController.text.trim(),
        );

        if (mounted) {
          // Tampilkan pesan sukses
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Registrasi sekolah/pesantren berhasil! Data telah disimpan.',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Navigasi ke halaman login setelah pendaftaran berhasil
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const LoginIPScreen(
                    userType: 'sekolah',
                  ), // Sesuaikan dengan parameter yang benar
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
              key: _formKey,
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
                  const SizedBox(height: 30),

                  // Input fields
                  _buildTextField('Nama Sekolah', _namaSekolahController),
                  const SizedBox(height: 15),
                  _buildTextField('Nomor NPSN', _npsnController),
                  const SizedBox(height: 15),
                  _buildTextField('Alamat Sekolah', _alamatSekolahController),
                  const SizedBox(height: 15),
                  _buildTextField(
                    'Email Sekolah',
                    _emailSekolahController,
                    isEmail: true,
                  ),
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
                              (context) =>
                                  const LoginIPScreen(userType: 'sekolah'),
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
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: const Color(0xFFD8D1A8),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Field ini harus diisi';
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
    _namaSekolahController.dispose();
    _npsnController.dispose();
    _alamatSekolahController.dispose();
    _emailSekolahController.dispose();
    _kataSandiController.dispose();
    _konfirmasiKataSandiController.dispose();
    super.dispose();
  }
}
