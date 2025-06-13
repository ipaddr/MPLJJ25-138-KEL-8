import 'package:flutter/material.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, // ✅ Height untuk floating button
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none, // ✅ Allow overflow
        children: [
          // Main Navigation Bar
          Positioned(
            bottom: 20, // ✅ Space from bottom
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF8B9969), // Earth tone green
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 0),
                  _buildNavItem(Icons.inventory_2_outlined, 1),
                  const SizedBox(width: 60), // Space for floating button
                  _buildNavItem(Icons.map_outlined, 3),
                  _buildNavItem(Icons.assignment_outlined, 4),
                ],
              ),
            ),
          ),

          // Floating Center Button
          Positioned(
            bottom: 50, // ✅ Perfect center position
            left: MediaQuery.of(context).size.width / 2 - 50, // ✅ Centered
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color:
                    currentIndex == 2
                        ? const Color(0xFFD4D0B8)
                        : const Color(0xFFC9C5A8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => onTap(2),
                  child: const Icon(
                    Icons.add,
                    size: 30,
                    color: Color(0xFF6B7A4F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final bool isActive = currentIndex == index;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6B7A4F) : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => onTap(index),
          child: Icon(icon, size: 24, color: const Color(0xFFF4F1E8)),
        ),
      ),
    );
  }
}
