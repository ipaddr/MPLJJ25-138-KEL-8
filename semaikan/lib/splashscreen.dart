import 'package:flutter/material.dart';
import 'dart:async'; // Untuk menggunakan Future.delayed
import 'daftar_pengguna.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToUserSelection();
  }

  _navigateToUserSelection() {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  const UserSelectionScreen(), // Navigasi ke UserSelectionScreen
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1), // Latar belakang SplashScreen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/splashscreen.png', // Menampilkan logo dari assets
              width: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              'Semaikan', // Nama aplikasi
              style: TextStyle(
                fontFamily: 'Kalnia',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
