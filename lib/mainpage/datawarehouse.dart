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
    // 📌 คำนวณความสูงการ์ดให้ Responsive ตามขนาดหน้าจอ
    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardHeight = (screenHeight * 0.16).clamp(130.0, 160.0);

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
                padding: EdgeInsets.fromLTRB(25, 25, 25, 15),
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
                    // 🔹 พืชปลูก (1.png - จัดอยู่ตรงกลาง)
                    _buildDataCard(
                      title: "พืชปลูก",
                      imagePath: "assets/images/1.png",
                      cardHeight: cardHeight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlantsPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 🔹 ดิน (2.png)
                    _buildDataCard(
                      title: "ดิน",
                      imagePath: "assets/images/2.png",
                      cardHeight: cardHeight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EarthPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 🔹 การปรับสภาพดิน (3.png)
                    _buildDataCard(
                      title: "การปรับสภาพดิน",
                      imagePath: "assets/images/3.png",
                      cardHeight: cardHeight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdjustPage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 🔹 แนะนำพืชปลูกตามประเภทของดิน (4.png)
                    _buildDataCard(
                      title: "แนะนำพืชปลูกตามประเภทของดิน",
                      imagePath: "assets/images/4.png",
                      cardHeight: cardHeight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EarthTypePage()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 🔹 แนะนำพืชปลูกตามปริมาณธาตุอาหาร (5.png)
                    _buildDataCard(
                      title: "แนะนำพืชปลูกตามปริมาณธาตุอาหาร",
                      imagePath: "assets/images/5.png",
                      cardHeight: cardHeight,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SoilPage()),
                      ),
                    ),
                    const SizedBox(height: 25), 
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

  // 🔹 ฟังก์ชันสร้างการ์ดคลังข้อมูลแบบ Responsive และรูปอยู่ตรงกลางทุกรูป
  Widget _buildDataCard({
    required String title,
    required String imagePath,
    required VoidCallback onTap,
    required double cardHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDB4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black87, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14.5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // คำนวณความสูงรูปให้อยู่ในสัดส่วน 50% ของตัวการ์ดเสมอ
              final double responsiveImgHeight = constraints.maxHeight * 0.52;

              return Stack(
                children: [
                  // 📌 1. ข้อความชื่อเรื่อง
                  Positioned(
                    top: constraints.maxHeight * 0.12,
                    left: 20,
                    right: 20,
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: (constraints.maxHeight * 0.14).clamp(16.0, 20.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 📌 2. รูปภาพประกอบแนบขอบล่างและจัดอยู่ตรงกลางแนวนอนทุกรูป
                  Positioned(
                    bottom: 6,
                    left: 12,
                    right: 12,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        imagePath,
                        height: responsiveImgHeight,
                        fit: BoxFit.contain, // รักษาสัดส่วนภาพไม่ให้เบี้ยว
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}