import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Screen 2 User/home_general.dart';

class LoginIPScreen extends StatefulWidget {
  final String userType; // 'hamil' atau 'sekolah'

  const LoginIPScreen({super.key, required this.userType});

  @override
  State<LoginIPScreen> createState() => _LoginIPScreenState();
}

class _LoginIPScreenState extends State<LoginIPScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _kataSandiController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _kataSandiController.dispose();
    super.dispose();
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
        // Verifikasi account_category di Firestore
        try {
          DocumentSnapshot userDoc =
              await _firestore
                  .collection('Account_Storage')
                  .doc(userCredential.user!.uid)
                  .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData =
                userDoc.data() as Map<String, dynamic>;
            String accountCategory = userData['account_category'] ?? '';

            // Cek apakah tipe user sesuai dengan yang dipilih
            bool isValidUserType = false;
            if (widget.userType == 'hamil' &&
                accountCategory == 'ibu_hamil_balita') {
              isValidUserType = true;
            } else if (widget.userType == 'sekolah' &&
                accountCategory == 'sekolah_pesantren') {
              isValidUserType = true;
            }

            if (isValidUserType) {
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const HomeGeneral()),
                );
              }
            } else {
              // Logout jika tipe user tidak sesuai
              await _auth.signOut();
              setState(() {
                _errorMessage =
                    'Akun ini tidak terdaftar untuk tipe pengguna yang dipilih';
              });
            }
          } else {
            // Jika data user tidak ditemukan di Firestore
            await _auth.signOut();
            setState(() {
              _errorMessage =
                  'Data akun tidak ditemukan. Silakan daftar terlebih dahulu.';
            });
          }
        } catch (firestoreError) {
          print('Firestore error: $firestoreError');

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeGeneral()),
            );
          }
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
        } else if (e.code == 'invalid-credential') {
          _errorMessage = 'Email atau kata sandi tidak valid';
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
    // Menentukan judul berdasarkan tipe pengguna
    String title =
        widget.userType == 'sekolah'
            ? 'MASUK SEKOLAH/PESANTREN'
            : 'MASUK IBU HAMIL/BALITA';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF626F47),
                    ),
                    children: [
                      TextSpan(
                        text: '$title\n',
                        style: const TextStyle(
                          fontSize: 26,
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
                      textAlign: TextAlign.center,
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

                const SizedBox(height: 20),

                // Lupa Password Link
                TextButton(
                  onPressed: _isLoading ? null : _showForgotPasswordDialog,
                  child: const Text(
                    'Lupa Kata Sandi?',
                    style: TextStyle(
                      color: Color(0xFF626F47),
                      decoration: TextDecoration.underline,
                      fontSize: 16,
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
      obscureText: isPassword,
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

  // Dialog untuk reset password
  void _showForgotPasswordDialog() {
    final TextEditingController emailResetController = TextEditingController();
    bool isResetLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFF9F3D1),
              title: const Text(
                'Reset Kata Sandi',
                style: TextStyle(
                  color: Color(0xFF626F47),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masukkan email Anda untuk menerima link reset kata sandi',
                    style: TextStyle(color: Color(0xFF626F47)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailResetController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Color(0xFFD8D1A8),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email harus diisi';
                      }
                      if (!_isValidEmail(value)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      isResetLoading
                          ? null
                          : () {
                            Navigator.of(dialogContext).pop();
                          },
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Color(0xFF626F47)),
                  ),
                ),
                isResetLoading
                    ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8F8962),
                        ),
                      ),
                    )
                    : ElevatedButton(
                      onPressed: () async {
                        if (emailResetController.text.isNotEmpty &&
                            _isValidEmail(emailResetController.text)) {
                          setDialogState(() {
                            isResetLoading = true;
                          });

                          try {
                            await _auth.sendPasswordResetEmail(
                              email: emailResetController.text.trim(),
                            );

                            Navigator.of(dialogContext).pop();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Link reset password telah dikirim ke email Anda. Periksa kotak masuk dan folder spam.',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 5),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() {
                              isResetLoading = false;
                            });

                            String errorMessage;
                            switch (e.code) {
                              case 'user-not-found':
                                errorMessage =
                                    'Email tidak terdaftar dalam sistem';
                                break;
                              case 'invalid-email':
                                errorMessage = 'Format email tidak valid';
                                break;
                              case 'too-many-requests':
                                errorMessage =
                                    'Terlalu banyak permintaan. Coba lagi nanti';
                                break;
                              default:
                                errorMessage =
                                    'Terjadi kesalahan: ${e.message}';
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isResetLoading = false;
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Terjadi kesalahan: $e'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Masukkan email yang valid'),
                              backgroundColor: Colors.orange,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8F8962),
                      ),
                      child: const Text(
                        'Kirim',
                        style: TextStyle(
                          color: Color(0xFFF9F3D1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}
