import 'package:flutter/material.dart';
import 'package:project/navbar/navbars.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/mainpage/recommentplants.dart';

import 'package:project/reccomment/plants.dart';
import 'package:project/reccomment/earth.dart';
import 'package:project/reccomment/adjust.dart';
import 'package:project/reccomment/earthtype.dart';
import 'package:project/reccomment/soil.dart';

class DataWarehousePage extends StatefulWidget {
  final bool isLoggedIn;
  const DataWarehousePage({super.key, this.isLoggedIn = false});

  @override
  State<DataWarehousePage> createState() => _DataWarehousePageState();
}

class _DataWarehousePageState extends State<DataWarehousePage> {
  int _selectedIndex = 1;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDCEAF1), 
              Color(0xFFD2E0C4), 
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(25, 30, 25, 20),
                child: Text(
                  "คลังข้อมูล",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // 🔹 พืชปลูก (รูปแบนเนอร์แนวยาว 1.png)
                    _buildDataCard(
                      title: "พืชปลูก",
                      imagePath: "assets/images/1.png",
                      isFullWidth: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlantsPage()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 ดิน (2.png)
                    _buildDataCard(
                      title: "ดิน",
                      imagePath: "assets/images/2.png",
                      imageHeight: 75,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EarthPage()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 การปรับสภาพดิน (3.png)
                    _buildDataCard(
                      title: "การปรับสภาพดิน",
                      imagePath: "assets/images/3.png",
                      imageHeight: 70,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdjustPage()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 แนะนำพืชปลูกตามประเภทของดิน (4.png)
                    _buildDataCard(
                      title: "แนะนำพืชปลูกตามประเภทของดิน",
                      imagePath: "assets/images/4.png",
                      imageHeight: 75,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EarthTypePage()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 แนะนำพืชปลูกตามปริมาณธาตุอาหาร (5.png)
                    _buildDataCard(
                      title: "แนะนำพืชปลูกตามปริมาณธาตุอาหาร",
                      imagePath: "assets/images/5.png",
                      imageHeight: 75,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SoilPage()),
                      ),
                    ),
                    const SizedBox(height: 30), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.isLoggedIn 
          ? const AuthNavBar(currentIndex: 1) 
          : const GuestNavBar(currentIndex: 1), 
    );
  }

  // 🔹 ฟังก์ชันสร้างการ์ดคลังข้อมูล (รูปแบบเดียวกับหน้า MenuPage)
  Widget _buildDataCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
    bool isFullWidth = false,
    double imageHeight = 75,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDB4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: Stack(
            children: [
              // 📌 1. ข้อความหัวเรื่อง
              Positioned(
                top: 18,
                left: 20,
                right: 20,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 📌 2. รูปภาพประกอบตรงกลางขอบล่าง
              Positioned(
                bottom: isFullWidth ? 0 : 10,
                left: 0,
                right: 0,
                child: Image.asset(
                  imagePath,
                  height: isFullWidth ? null : imageHeight,
                  fit: isFullWidth ? BoxFit.fitWidth : BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}