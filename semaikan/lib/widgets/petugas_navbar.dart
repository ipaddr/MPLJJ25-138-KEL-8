import 'package:flutter/material.dart';

class PetugasNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PetugasNavbar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF8B9969), // Warna hijau olive sesuai gambar
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.inventory_2_outlined, 1),
            _buildNavItem(Icons.map_outlined, 2),
            _buildNavItem(Icons.assignment_outlined, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isActive = currentIndex == index;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color:
            isActive
                ? const Color(0xFF6B7A4F)
                : Colors.transparent, // Warna active lebih gelap
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => onTap(index),
          child: Icon(
            icon,
            size: 24,
            color: const Color(0xFFF4F1E8),
          ), // Warna icon cream/putih
        ),
      ),
    );
  }
}
