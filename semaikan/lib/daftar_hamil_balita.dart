import 'package:flutter/material.dart';
import 'login_ip.dart';

class DaftarHamilBalitaScreen extends StatefulWidget {
  const DaftarHamilBalitaScreen({super.key});

  @override
  State<DaftarHamilBalitaScreen> createState() =>
      _DaftarHamilBalitaScreenState();
}

class _DaftarHamilBalitaScreenState extends State<DaftarHamilBalitaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaLengkapController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _usiaKehamilanController =
      TextEditingController();
  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _tinggiBadanController = TextEditingController();
  final TextEditingController _kataSandiController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(width: 15), // Menambahkan jarak antar field
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
                _buildTextField(
                  'Kata Sandi',
                  _kataSandiController,
                  isPassword: true,
                ),

                const SizedBox(height: 30),
                // Tombol Daftar
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const LoginIPScreen(userType: 'userType'),
                        ),
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
                      color: Color(0xFFF9F3D1),
                    ),
                  ),
                ),

                // Link untuk mengarahkan ke login jika sudah punya akun
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const LoginIPScreen(userType: 'userType'),
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
        return null;
      },
    );
  }
}
