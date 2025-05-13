import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3D1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8F8962),
        title: const Text('Home', style: TextStyle(color: Color(0xFFF9F3D1))),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Welcome to Home Page',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF626F47),
          ),
        ),
      ),
    );
  }
}
