import 'package:flutter/material.dart';
import 'package:semaikan/home.dart'; // Pastikan import home.dart

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
                _buildTextField('Email', _emailController),
                const SizedBox(height: 15),
                _buildTextField(
                  'Kata Sandi',
                  _kataSandiController,
                  isPassword: true,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      // Setelah login berhasil, arahkan ke halaman HomeScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
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
