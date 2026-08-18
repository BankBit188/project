import 'package:flutter/material.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/mainpage/datawarehouse.dart';
import 'package:project/mainpage/recommentplants.dart';
import 'package:project/login/login.dart';
import 'package:project/mainpage/chat.dart';
import 'package:project/mainpage/tool.dart';

// ---------------------------------------------
// 1. แถบเมนูสำหรับผู้ที่ยังไม่ได้ ล็อกอิน (4 ปุ่ม)
// ---------------------------------------------
class GuestNavBar extends StatelessWidget {
  final int currentIndex;
  const GuestNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return _CustomBottomBarLayout(
      currentIndex: currentIndex,
      items: [
        _NavItemData(icon: Icons.home_rounded, page: const MenuPage()), 
        _NavItemData(icon: Icons.menu_book_rounded, page: const DataWarehousePage()),
        _NavItemData(icon: Icons.local_florist_rounded, page: const RecommendPlantsPage()),
        _NavItemData(icon: Icons.business_center_rounded, page: const LoginPage()),
      ],
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
    return _CustomBottomBarLayout(
      currentIndex: currentIndex,
      items: [
        _NavItemData(icon: Icons.home_rounded, page: const MenuPage(isLoggedIn: true)), 
        _NavItemData(icon: Icons.menu_book_rounded, page: const DataWarehousePage(isLoggedIn: true)),
        _NavItemData(icon: Icons.local_florist_rounded, page: const RecommendPlantsPage(isLoggedIn: true)),
        _NavItemData(icon: Icons.chat_bubble_rounded, page: const ChatPage()), 
        _NavItemData(icon: Icons.business_center_rounded, page: const ToolPage()), 
      ],
    );
  }
}

// ---------------------------------------------
// 3. ส่วนประกอบการตกแต่งหลัก (ภายในไฟล์เดียว)
// ---------------------------------------------
class _NavItemData {
  final IconData icon;
  final Widget page;

  _NavItemData({required this.icon, required this.page});
}

class _CustomBottomBarLayout extends StatelessWidget {
  final int currentIndex;
  final List<_NavItemData> items;

  const _CustomBottomBarLayout({
    required this.currentIndex,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => item.page),
                      );
                    }
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD6B98D) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFD6B98D).withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        item.icon,
                        size: isSelected ? 28 : 26,
                        color: Colors.black87, // 💡 ชัดเจน 100% เท่ากันทุกปุ่ม ไม่ดรอปสีลง
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}