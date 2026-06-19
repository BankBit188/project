import 'dart:io'; // 🟩 เพิ่มเข้ามาเพื่อใช้กับคลาส File ของรูปภาพ
import 'package:flutter/material.dart';
import 'package:project/navbar/navbars.dart';
import 'package:project/mainpage/history.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/mainpage/profile.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart'; // 🟩 ลงแพ็กเกจเพิ่มเพื่อดึงรูปจากเครื่อง (flutter pub add image_picker)
import 'package:project/service/reports_service.dart'; // 🟩 Import ไฟล์บริการจัดการ Report ที่เราเพิ่งสร้างร่วมกัน
import 'package:project/service/user_service.dart'; // 🟩 เพิ่ม Import ตรงนี้เพื่อใช้ดึงข้อมูล Username ปัจจุบันมาส่ง Report

import 'package:intl/date_symbol_data_local.dart'; // 🟩 สำหรับเปิดใช้งาน Locale ภาษาไทย
import 'package:intl/intl.dart'; // 🟩 แพ็กเกจสำหรับจัดการ Format วันและเวลา

// 🟩 เปลี่ยนโครงสร้างจาก StatelessWidget เป็น StatefulWidget เพื่อใช้ดึงข้อมูล Token ล่าสุด
class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  // 🟩 อินสแตนซ์ของ Secure Storage สำหรับอ่าน/ลบ Token
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 🟩 ตัวแปรสำหรับเก็บค่าเพื่อนำไปเช็คหรือส่งต่อให้ API ตัวอื่น
  String? _authToken;
  String? _userId; // 🟩 เพิ่มสำหรับเก็บ User ID ไปควานหาชื่อผู้ใช้

  // 🟩 ตัวแปรสำหรับเก็บสตริงวันเวลาปัจจุบันที่แปลงเป็นภาษาไทยแล้ว
  String _currentDateTimeString = "";

  @override
  void initState() {
    super.initState();
    _initThaiDateTime(); // 🟩 เรียกเซ็ตค่าและดึงวันเวลาปัจจุบันภาษาไทย
    _loadToken(); // 🟩 เรียกโหลด Token ทันทีเมื่อเปิดหน้าอุปกรณ๋ขึ้นมา
  }

  // 🟩 ฟังก์ชันสำหรับดึงและจัดฟอร์แมตวันเวลาปัจจุบันให้เป็นภาษาไทย พ.ศ.
  void _initThaiDateTime() {
    // เปิดใช้งานข้อมูลวันเวลาในระบบภูมิภาคของภาษาไทย ('th')
    initializeDateFormatting('th', null).then((_) {
      final now = DateTime.now();
      
      // ฟอร์แมตวันที่ เช่น "20 มกราคม"
      final dateNew = DateFormat('d MMMM', 'th').format(now);
      
      // ดึงปี ค.ศ. ปัจจุบันมาบวก 543 เพื่อทำเป็นปี พ.ศ.
      final thaiYear = now.year + 543;
      
      // ฟอร์แมตเวลา เช่น "12.00"
      final timeNew = DateFormat('HH.mm').format(now);

      if (!mounted) return;
      setState(() {
        // นำมาประกอบร่างตาม Format ที่อยากได้: "20 มกราคม 2569   12.00"
        _currentDateTimeString = "$dateNew $thaiYear   $timeNew";
      });
    });
  }

  // 🟩 ฟังก์ชันสำหรับดึง Token และ User ID ออกจากหน่วยความจำ
  Future<void> _loadToken() async {
    String? token = await _secureStorage.read(key: "auth_token");
    String? userId = await _secureStorage.read(key: "user_id");
    if (!mounted) return;
    setState(() {
      _authToken = token;
      _userId = userId;
    });
    // เทสพิมพ์พ่นดูใน Debug Console ว่า ข้อมูลมาจริงไหม
    print("ระบบตรวจสอบพบ Token ปัจจุบัน: $_authToken, UserID: $_userId");
  }

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
                    
                    // 🛠️ ส่วนที่แก้ไข: นำข้อมูลตัวแปรจากวันเวลาปัจจุบันมาแสดงผลแทนค่าเดิมที่กรอกค้างไว้ (Static)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _currentDateTimeString.isNotEmpty 
                            ? _currentDateTimeString 
                            : "กำลังโหลดเวลา...", // แสดงข้อความรอระหว่างที่ format ทำงานแป๊บหนึ่ง
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),

                    // --- PopupMenuButton ---
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.black54),
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
                        onSelected: (String value) async {
                          if (value == 'profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
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
                            await _secureStorage.delete(key: "auth_token");
                            await _secureStorage.delete(key: "user_id");
                            print("ลบ Token สำเร็จ ออกจากระบบเรียบร้อยแล้ว");

                            if (!mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MenuPage(isLoggedIn: false),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          } else {
                            print("คุณคลิกเลือก: $value");
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          _buildPopupMenuItem('profile', 'โปรไฟล์'),
                          const PopupMenuDivider(height: 1),
                          _buildPopupMenuItem('history', 'ประวัติการบันทึก'),
                          const PopupMenuDivider(height: 1),
                          _buildPopupMenuItem('report', 'รายงานปัญหา'),
                          const PopupMenuDivider(height: 1),
                          _buildPopupMenuItem('logout', 'ออกจากระบบ'),
                        ],
                      ),
                    ),
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
    final TextEditingController titleController = TextEditingController();
    final TextEditingController detailController = TextEditingController();
    File? selectedImageFile;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFFCEEBA),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.black87, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              onTap: () {
                                titleController.dispose();
                                detailController.dispose();
                                Navigator.of(context).pop();
                              },
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
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black54),
                              ),
                              child: TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
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
                      const Text(
                        "รายละเอียด",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black54),
                        ),
                        child: TextField(
                          controller: detailController,
                          maxLines: null,
                          expands: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          const Text(
                            "รูปภาพ : ",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              selectedImageFile != null
                                  ? selectedImageFile!.path.split('/').last
                                  : "ยังไม่เลือกรูปภาพ",
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.black54),
                            ),
                            child: TextButton(
                              onPressed: () async {
                                final XFile? image = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null) {
                                  setDialogState(() {
                                    selectedImageFile = File(image.path);
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: Size.zero,
                              ),
                              child: const Text(
                                "เลือกรูปภาพ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          height: 40,
                          width: 90,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6BBA90),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.black87),
                          ),
                          child: TextButton(
                            onPressed: () async {
                              if (titleController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('กรุณากรอกหัวข้อแจ้งปัญหา'),
                                  ),
                                );
                                return;
                              }

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                String currentUsername = "ไม่ระบุชื่อผู้ใช้";
                                
                                if (_userId != null && _authToken != null) {
                                  try {
                                    final userData = await UserService.getUserById(_userId!, _authToken);
                                    currentUsername = userData['username'] ?? "ไม่ระบุชื่อผู้ใช้";
                                  } catch (userError) {
                                    print("ดึงชื่อผู้ใช้ล้มเหลว: $userError");
                                  }
                                }

                                Map<String, String> reportData = {
                                  'username': currentUsername,
                                  'reporttitle': titleController.text.trim(),
                                  'reportdetail': detailController.text.trim(),
                                };

                                final response = await ReportsService.createReport(
                                  reportData: reportData,
                                  imageFile: selectedImageFile,
                                );

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        response['message'] ?? 'ส่งรายงานสำเร็จ',
                                      ),
                                    ),
                                  );
                                  titleController.dispose();
                                  detailController.dispose();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('ส่งข้อมูลล้มเหลวเนื่องจาก: $e'),
                                    ),
                                  );
                                }
                              }
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
      },
    );
  }

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