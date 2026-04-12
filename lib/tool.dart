import 'package:flutter/material.dart';
import 'package:project/navbars.dart';
import 'package:project/history.dart';
import 'package:project/menu.dart';

import 'package:project/profile.dart'; // เพิ่มบรรทัดนี้

class ToolPage extends StatelessWidget {
  const ToolPage({super.key});

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
            colors: [Color(0xFFDCEAF1), Color(0xFFD2E0C4)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "อุปกรณ์",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "20 มกราคม 2569   12.00",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),

                    // --- PopupMenuButton ---
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.black54),
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.menu,
                          size: 35,
                          color: Colors.black,
                        ),
                        offset: const Offset(0, 45),
                        color: const Color(0xFFFCEEBA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(
                            color: Colors.black54,
                            width: 1,
                          ),
                        ),
                        onSelected: (String value) {
                          if (value == 'profile') {
                            // --- เพิ่มคำสั่งสำหรับเปลี่ยนไปหน้าโปรไฟล์ ---
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                            // ------------------------------------
                          } else if (value == 'report') {
                            _showReportDialog(context);
                          } else if (value == 'history') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HistoryPage(),
                              ),
                            );
                          } else if (value == 'logout') {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MenuPage(isLoggedIn: false),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          } else {
                            print("คุณคลิกเลือก: $value");
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              _buildPopupMenuItem('profile', 'โปรไฟล์'),
                              const PopupMenuDivider(height: 1),
                              _buildPopupMenuItem(
                                'history',
                                'ประวัติการบันทึก',
                              ),
                              const PopupMenuDivider(height: 1),
                              _buildPopupMenuItem('report', 'รายงานปัญหา'),
                              const PopupMenuDivider(height: 1),
                              _buildPopupMenuItem('logout', 'ออกจากระบบ'),
                            ],
                      ),
                    ),

                    // -----------------------------------------------------
                  ],
                ),
                const SizedBox(height: 40),
                _buildElementRow("N", "30", "P", "0", "K", "38"),
                const SizedBox(height: 20),
                _buildElementRow("Ca", "30", "Mg", "0", "S", "38"),
                const SizedBox(height: 40),
                _buildDetailRow(
                  Icons.water_drop,
                  "ความชื้น",
                  "60 %",
                  Colors.lightBlue,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.thermostat,
                  "อุณหภูมิ",
                  "20 C°",
                  Colors.black54,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.waves,
                  "ความเค็ม",
                  "0.5 mS/cm",
                  Colors.black54,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomButton("บันทึกข้อมูล"),
                    _buildBottomButton("พืชปลูกที่เหมาะสม"),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AuthNavBar(currentIndex: 4),
    );
  }

  // --- ส่วนของฟังก์ชันสร้าง ป๊อปอัป (Dialog) แจ้งปัญหา ---
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFFCEEBA), // สีเหลืองอ่อนพื้นหลัง
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), // ขอบมน
            side: const BorderSide(
              color: Colors.black87,
              width: 1,
            ), // เส้นขอบดำ
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              // ป้องกัน overflow เมื่อคีย์บอร์ดเด้ง
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. หัวข้อและปุ่มปิด
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          "แจ้งปัญหา",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () =>
                              Navigator.of(context).pop(), // กดกากบาทเพื่อปิด
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. กล่องข้อความหัวข้อ
                  Row(
                    children: [
                      const Text(
                        "หัวข้อ : ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // ช่องกรอกขอบมน
                            border: Border.all(color: Colors.black54),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // 3. กล่องข้อความรายละเอียด
                  const Text(
                    "รายละเอียด",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 120, // ความสูงกล่องรายละเอียด
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black54,
                      ), // กล่องเหลี่ยมปกติแบบในรูป
                    ),
                    child: const TextField(
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 4. ส่วนเลือกรูปภาพ
                  Row(
                    children: [
                      const Text(
                        "รูปภาพ : ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "ยังไม่เลือกรูปภาพ",
                        style: TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      // ปุ่มเลือกรูปภาพสีเทา
                      Container(
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.black54),
                        ),
                        child: TextButton(
                          onPressed: () {
                            // โค้ดสำหรับเปิดแกลลอรี่เลือกรูปภาพ
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                          ),
                          child: const Text(
                            "เลือกรูปภาพ",
                            style: TextStyle(color: Colors.black, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 5. ปุ่มส่ง
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      height: 40,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6BBA90), // สีเขียวหม่นตามรูป
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black87),
                      ),
                      child: TextButton(
                        onPressed: () {
                          // โค้ดสำหรับการส่งข้อมูลรายงานปัญหา
                          Navigator.of(
                            context,
                          ).pop(); // ส่งเสร็จแล้วปิดหน้าต่าง
                        },
                        child: const Text(
                          "ส่ง",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  // -------------------------------------------------------------

  PopupMenuItem<String> _buildPopupMenuItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildElementRow(
    String l1,
    String v1,
    String l2,
    String v2,
    String l3,
    String v3,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _elementText(l1, v1),
        _elementText(l2, v2),
        _elementText(l3, v3),
      ],
    );
  }

  Widget _elementText(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 20),
        children: [
          TextSpan(
            text: "$label ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
          ),
          TextSpan(text: ": $value"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, size: 35, color: iconColor),
        const SizedBox(width: 15),
        Text("$label   : $value", style: const TextStyle(fontSize: 20)),
      ],
    );
  }

  Widget _buildBottomButton(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF4D9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black87),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
