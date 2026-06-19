import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          // พื้นหลัง Gradient แบบเดียวกับหน้าหลัก
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDCEAF1), Color(0xFFD2E0C4)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ส่วนหัว (ปุ่มย้อนกลับ + ข้อความ)
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context), // กดเพื่อย้อนกลับ
                      child: const Icon(
                        Icons.reply, // ใช้ไอคอนลูกศรย้อนกลับแบบโค้งคล้ายในรูป
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "ประวัติการบันทึก",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 2. ช่องค้นหา (Search Bar)
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3), // สีพื้นหลังช่องค้นหา (ขาวอมเทา)
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "ค้นหา เช่น ชื่อสวน",
                      hintStyle: TextStyle(color: Colors.grey[700], fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(left: 15, top: 12),
                      suffixIcon: const Icon(Icons.search, color: Colors.black, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 3. รายการประวัติ (ListView เพื่อให้เลื่อนดูได้ถ้ารายการเยอะ)
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildHistoryCard("สวน3", "15มกราคม", "12.00"),
                      _buildHistoryCard("สวน2", "14มกราคม", "9.00"),
                      _buildHistoryCard("สวน1", "13มกราคม", "13.00"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ฟังก์ชันสำหรับสร้างการ์ดประวัติแต่ละอัน ---
  Widget _buildHistoryCard(String gardenName, String date, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEBA), // สีพื้นหลังกล่อง (สีเหลืองอ่อน)
        borderRadius: BorderRadius.circular(15), // ขอบมน
        border: Border.all(color: Colors.black87, width: 1), // เส้นขอบสีดำ
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                gardenName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Text(date, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  const SizedBox(width: 15),
                  Text(time, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          // ข้อความรายละเอียดสารอาหาร
          const Text(
            "ไนโตรเจน ( N ) : 30 ฟอสฟอรัส ( P ) : 0\nโพแทสเซียม ( K ) : 38 ......",
            style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}