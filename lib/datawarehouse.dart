import 'package:flutter/material.dart';
import 'package:project/navbars.dart'; // นำเข้าไฟล์ navbars.dart ที่เราสร้างไว้
import 'package:project/menu.dart'; // นำเข้าหน้า Menu เพื่อให้กดกลับไปได้
import 'package:project/recommentplants.dart'; // เผื่อไว้ใช้ตอนเปลี่ยนหน้าไปแนะนำพืชปลูก

class DataWarehousePage extends StatefulWidget {
  final bool isLoggedIn;
  const DataWarehousePage({super.key, this.isLoggedIn = false});

  @override
  State<DataWarehousePage> createState() => _DataWarehousePageState();
}

class _DataWarehousePageState extends State<DataWarehousePage> {
  // ตั้งค่าให้เมนูที่ 2 (index 1) คือเมนูคลังข้อมูลถูกเลือก
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
              Color(0xFFDCEAF1), // สีฟ้าอ่อนด้านบน
              Color(0xFFD2E0C4), // สีเขียวอ่อนด้านล่าง
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวข้อหน้า
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

              // รายการการ์ด (สามารถเลื่อนขึ้นลงได้)
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildPlantCard(),
                    const SizedBox(height: 20),
                    _buildStandardCard(
                      title: "ดิน",
                      // ใช้ Icon ชั่วคราวแทนรูปภาพแผนภูมิ NPK
                      illustration: const Icon(
                        Icons.pie_chart_outline,
                        size: 60,
                        color: Color(0xFF6B9077),
                      ),
                      // หากมีไฟล์รูปภาพแล้ว ให้เปลี่ยนไปใช้:
                      // illustration: Image.asset("assets/images/soil_chart.png", height: 60),
                    ),
                    const SizedBox(height: 20),
                    _buildStandardCard(
                      title: "การปรับสภาพดิน",
                      illustration: const Icon(
                        Icons.hardware,
                        size: 60,
                        color: Color(0xFF8B5E34),
                      ), // ไอคอนชั่วคราวแทนที่ตักดิน
                    ),
                    const SizedBox(height: 20),
                    _buildStandardCard(
                      title: "แนะนำพืชปลูกตามประเภทของดิน",
                      illustration: const Icon(
                        Icons.recycling,
                        size: 60,
                        color: Color(0xFF45911B),
                      ), // ไอคอนชั่วคราว
                    ),
                    const SizedBox(height: 20),
                    _buildStandardCard(
                      title: "แนะนำพืชปลูกตามปริมาณธาตุอาหาร",
                      illustration: const Icon(
                        Icons.science,
                        size: 60,
                        color: Color(0xFF6B9077),
                      ), // ไอคอนชั่วคราว
                    ),
                    const SizedBox(height: 30), // เว้นระยะด้านล่างสุด
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // เรียกใช้แถบเมนูด้านล่างที่ Import มาจาก navbars.dart
      // ลบ bottomNavigationBar ของเก่าออกทั้งหมด แล้วใส่แค่นี้แทน
      bottomNavigationBar: widget.isLoggedIn 
          ? const AuthNavBar(currentIndex: 1) // 1 คือตำแหน่งของคลังข้อมูล
          : const GuestNavBar(currentIndex: 1), 
    );
  }

  // 1. การ์ดพิเศษสำหรับ "พืชปลูก" (มีกราฟิกดินด้านล่างการ์ด)
  Widget _buildPlantCard() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDB4), // สีเหลืองครีม
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black87, width: 1.5), // เส้นขอบสีดำ
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 15,
            left: 20,
            child: Text(
              "พืชปลูก",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // กราฟิกจำลองชั้นดินด้านล่าง
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFF8B5E34), // สีน้ำตาลดิน
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
                    child: Icon(
                      Icons.energy_savings_leaf,
                      color: Color(0xFF8CC152),
                      size: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Icon(
                      Icons.energy_savings_leaf,
                      color: Color(0xFF8CC152),
                      size: 30,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 15),
                    child: Icon(
                      Icons.energy_savings_leaf,
                      color: Color(0xFF8CC152),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. การ์ดมาตรฐานสำหรับหัวข้ออื่นๆ (มีภาพประกอบอยู่ตรงกลาง)
  Widget _buildStandardCard({
    required String title,
    required Widget illustration,
  }) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF2EDB4), // สีเหลืองครีม
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black87, width: 1.5), // เส้นขอบสีดำ
      ),
      child: Stack(
        children: [
          Positioned(
            top: 15,
            left: 20,
            right: 20,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ตำแหน่งวางภาพประกอบตรงกลาง
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: illustration,
            ),
          ),
        ],
      ),
    );
  }
}
