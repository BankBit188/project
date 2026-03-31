import 'package:flutter/material.dart';
import 'package:project/navbars.dart'; // นำเข้า Navbar
import 'package:project/menu.dart'; // นำเข้าหน้า Menu
import 'package:project/datawarehouse.dart'; // นำเข้าหน้า DataWarehouse

class RecommendPlantsPage extends StatefulWidget {
  final bool isLoggedIn;
  const RecommendPlantsPage({super.key, this.isLoggedIn = false});

  @override
  State<RecommendPlantsPage> createState() => _RecommendPlantsPageState();
}

class _RecommendPlantsPageState extends State<RecommendPlantsPage> {
  // ตั้งค่าให้เมนูที่ 3 (index 2) ถูกเลือก
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // พื้นหลังไล่สี
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
          child: SingleChildScrollView(
            // ป้องกันปัญหาหน้าจอล้นตอนคีย์บอร์ดเด้ง
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // หัวข้อหน้า
                  const Text(
                    "กรอกข้อมูลสภาพดินเพื่อค้นหา\nพืชปลูกที่เหมาะสม",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // กล่องฟอร์มกรอกข้อมูล
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE4E9D6,
                      ), // สีเขียวหม่นอมครีม (พื้นหลังกล่อง)
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black87, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ส่วนข้อมูลทั่วไป
                        _buildInputField("PH"),
                        _buildInputField("ความชื้น"),
                        _buildInputField("อุณหภูมิ"),
                        _buildInputField("ความเค็ม"),

                        const SizedBox(height: 15),

                        // หัวข้อ: ธาตุอาหารหลัก
                        const Text(
                          "ธาตุอาหารหลัก",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField("N"),
                        _buildInputField("P"),
                        _buildInputField("K"),

                        const SizedBox(height: 15),

                        // หัวข้อ: ธาตุอาหารรอง
                        const Text(
                          "ธาตุอาหารรอง",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInputField("Ca"),
                        _buildInputField("Mg"),
                        _buildInputField("S"),

                        const SizedBox(height: 30),

                        // ปุ่ม "ค้นหา"
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
                                // โค้ดสำหรับคำนวณหรือไปหน้าผลลัพธ์ใส่ตรงนี้
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF3B3838,
                                ), // สีเทาดำเข้ม
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                "ค้นหา",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // แถบเมนูด้านล่าง
      // ลบ bottomNavigationBar ของเก่าออกทั้งหมด แล้วใส่แค่นี้แทน
      bottomNavigationBar: widget.isLoggedIn 
          ? const AuthNavBar(currentIndex: 2) // 2 คือตำแหน่งของหน้าแนะนำพืช
          : const GuestNavBar(currentIndex: 2), // ใส่เลข 0 สำหรับหน้า menu, 1 สำหรับคลังข้อมูล, 2 สำหรับหน้าพืชปลูก
    );
  }

  // Widget ช่วยสร้างช่องกรอกข้อมูลแนวนอน
  Widget _buildInputField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          // ชื่อ Label (เว้นขวาให้ตรงกัน)
          Expanded(
            flex: 2,
            child: Text(
              label,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 15),
          // ช่อง TextField
          Expanded(
            flex: 6,
            child: Container(
              height: 32, // ความสูงของช่องกรอกข้อมูล
              decoration: BoxDecoration(
                color: const Color(
                  0xFFF3DFB8,
                ), // สีครีมส้มอ่อนๆ (พื้นหลังช่องกรอก)
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black87, width: 0.8),
              ),
              child: const TextField(
                keyboardType: TextInputType.number, // ให้พิมพ์ได้เฉพาะตัวเลข
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
