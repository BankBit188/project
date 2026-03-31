import 'package:flutter/material.dart';
import 'package:project/menu.dart';
import 'package:project/datawarehouse.dart';
import 'package:project/recommentplants.dart';
import 'package:project/login.dart';
import 'package:project/chat.dart';
import 'package:project/tool.dart';

// ---------------------------------------------
// 1. แถบเมนูสำหรับผู้ที่ยังไม่ได้ ล็อกอิน (4 ปุ่ม)
// ---------------------------------------------
class GuestNavBar extends StatelessWidget {
  final int currentIndex;
  const GuestNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6E5),
        border: Border(top: BorderSide(color: Colors.black87, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home, 0, const MenuPage()), 
          _buildNavItem(context, Icons.menu_book, 1, const DataWarehousePage()),
          _buildNavItem(context, Icons.local_florist, 2, const RecommendPlantsPage()),
          _buildNavItem(context, Icons.business_center, 3, const LoginPage()), // ไปหน้า Login
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, Widget page) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: isSelected
            ? const BoxDecoration(color: Color(0xFFD6B98D), shape: BoxShape.circle)
            : null,
        child: Icon(icon, size: 32, color: Colors.black87),
      ),
    );
  }
}

// ---------------------------------------------
// 2. แถบเมนูสำหรับสมาชิก ล็อกอินแล้ว (5 ปุ่ม)
// ---------------------------------------------
class AuthNavBar extends StatelessWidget {
  final int currentIndex;
  const AuthNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6E5),
        border: Border(top: BorderSide(color: Colors.black87, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // --- จุดที่แก้: เพิ่ม isLoggedIn: true ให้กับหน้าที่ต้องใช้แถบเมนูร่วมกัน ---
          _buildNavItem(context, Icons.home, 0, const MenuPage(isLoggedIn: true)), 
          _buildNavItem(context, Icons.menu_book, 1, const DataWarehousePage(isLoggedIn: true)),
          _buildNavItem(context, Icons.local_florist, 2, const RecommendPlantsPage(isLoggedIn: true)),
          // ------------------------------------------------------------------
          _buildNavItem(context, Icons.chat_bubble, 3, const ChatPage()), // แชทบอท
          _buildNavItem(context, Icons.business_center, 4, const ToolPage()), // อุปกรณ์
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, Widget page) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => page));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: isSelected
            ? const BoxDecoration(color: Color(0xFFD6B98D), shape: BoxShape.circle)
            : null,
        child: Icon(icon, size: 32, color: Colors.black87),
      ),
    );
  }
}