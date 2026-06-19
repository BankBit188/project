import 'package:flutter/material.dart';
import 'package:project/navbar/navbars.dart'; // นำเข้าไฟล์ navbars.dart ที่เราสร้างไว้
import 'package:project/mainpage/menu.dart'; // นำเข้าหน้า Menu เพื่อให้กดกลับไปได้
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
                    // 🔹 พืชปลูก -> ไปหน้า PlantsPage
                    _buildPlantCard(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantsPage())),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 ดิน -> ไปหน้า EarthPage
                    _buildStandardCard(
                      title: "ดิน",
                      illustration: const Icon(Icons.pie_chart_outline, size: 60, color: Color(0xFF6B9077)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EarthPage())),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 การปรับสภาพดิน -> ไปหน้า AdjustPage
                    _buildStandardCard(
                      title: "การปรับสภาพดิน",
                      illustration: const Icon(Icons.hardware, size: 60, color: Color(0xFF8B5E34)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdjustPage())),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 แนะนำพืชปลูกตามประเภทของดิน -> ไปหน้า EarthTypePage
                    _buildStandardCard(
                      title: "แนะนำพืชปลูกตามประเภทของดิน",
                      illustration: const Icon(Icons.recycling, size: 60, color: Color(0xFF45911B)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EarthTypePage())),
                    ),
                    const SizedBox(height: 20),
                    
                    // 🔹 แนะนำพืชปลูกตามปริมาณธาตุอาหาร -> ไปหน้า SoilPage
                    _buildStandardCard(
                      title: "แนะนำพืชปลูกตามปริมาณธาตุอาหาร",
                      illustration: const Icon(Icons.science, size: 60, color: Color(0xFF6B9077)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SoilPage())),
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

  // 🔹 เพิ่มพารามิเตอร์ onTap
  Widget _buildPlantCard({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDB4), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black87, width: 1.5), 
        ),
        child: Stack(
          children: [
            const Positioned(
              top: 15,
              left: 20,
              child: Text(
                "พืชปลูก",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 45,
                decoration: const BoxDecoration(
                  color: Color(0xFF8B5E34), 
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 20),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 30),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: Icon(Icons.energy_savings_leaf, color: Color(0xFF8CC152), size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 เพิ่มพารามิเตอร์ onTap
  Widget _buildStandardCard({
    required String title,
    required Widget illustration,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDB4), 
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black87, width: 1.5), 
        ),
        child: Stack(
          children: [
            Positioned(
              top: 15,
              left: 20,
              right: 20,
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: illustration,
              ),
            ),
          ],
        ),
      ),
    );
  }
}