import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // --- ส่วนของพื้นหลังไล่สี (Gradient) แบบเดียวกับหน้าอุปกรณ์ ---
        decoration: const BoxDecoration(
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- ส่วนหัว (ปุ่มย้อนกลับ + คำว่า โปรไฟล์) ---
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.reply, // ไอคอนลูกศรโค้งย้อนกลับ
                        size: 35,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        Navigator.pop(context); // คำสั่งกดย้อนกลับไปหน้าก่อนหน้า
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "โปรไฟล์",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 60),

                // --- ส่วนรูปประจำตัว (Avatar แบบที่วาดเองให้เหมือนในรูป) ---
                Column(
                  children: [
                    // ส่วนหัว
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA05A2C), // สีน้ำตาล
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // ส่วนลำตัว
                    Container(
                      width: 110,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA05A2C), // สีน้ำตาล
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // --- ส่วนชื่อผู้ใช้ ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Suthat",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        // โค้ดสำหรับกดแก้ไขชื่อ
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // --- ส่วนรหัสผ่าน ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "รหัสผ่าน",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 15),
                    // กล่องสีเทาแสดงรหัสผ่าน
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCDCDC), // สีเทาอ่อน
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        "********",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          letterSpacing: 2.0, // เพิ่มระยะห่างระหว่างตัวดอกจัน
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    InkWell(
                      onTap: () {
                        // โค้ดสำหรับกดเปลี่ยนรหัสผ่าน
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}