import 'dart:io'; // 🟩 สำหรับใช้กับคลาส File ของรูปภาพ
import 'package:flutter/material.dart';
import 'package:project/navbar/navbars.dart';
import 'package:project/mainpage/history.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/mainpage/profile.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart'; 
// 🟩 ลงแพ็กเกจเพิ่มเพื่อดึงรูปจากเครื่อง (flutter pub add image_picker)
import 'package:project/service/reports_service.dart';
// 🟩 Import ไฟล์บริการจัดการ Report
import 'package:project/service/user_service.dart'; 
// 🟩 เพิ่ม Import ตรงนี้เพื่อใช้ดึงข้อมูล Username ปัจจุบันมาส่ง Report

import 'package:intl/date_symbol_data_local.dart';
// 🟩 สำหรับเปิดใช้งาน Locale ภาษาไทย
import 'package:intl/intl.dart'; 
// 🟩 แพ็กเกจสำหรับจัดการ Format วันและเวลา

// 🔵 1. นำเข้าไฟล์บริการข้อมูลอุปกรณ์ และบริการข้อมูลพืช
import 'package:project/service/tool_service.dart';
import 'package:project/service/plants_service.dart'; // 🌿 เพิ่ม Service ดึงข้อมูลพืช

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
  String? _userId;

  // 🔵 2. เพิ่มตัวแปรเก็บข้อมูลอุปกรณ์จาก API และสเตตัสการโหลด
  Map<String, dynamic>? _toolData;
  bool _isLoadingTool = false;

  // 🟩 ตัวแปรสำหรับเก็บสตริงวันเวลาปัจจุบันที่แปลงเป็นภาษาไทยแล้ว
  String _currentDateTimeString = "";

  @override
  void initState() {
    super.initState();
    _initThaiDateTime();
    // 🟩 เรียกเซ็ตค่าและดึงวันเวลาปัจจุบันภาษาไทย
    _loadToken();
    // 🟩 เรียกโหลด Token ทันทีเมื่อเปิดหน้าอุปกรณ์ขึ้นมา
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
        // นำมาประกอบร่างตาม Format: "20 มกราคม 2569   12.00"
        _currentDateTimeString = "$dateNew $thaiYear   $timeNew";
      });
    });
  }

  // 🟩 ฟังก์ชันสำหรับดึง Token และ User ID ออกจากหน่วยความจำ
  Future<void> _loadToken() async {
    String? token = await _secureStorage.read(key: "auth_token");
    String? userId = await _secureStorage.read(key: "Userid");

    if (!mounted) return;
    setState(() {
      _authToken = token;
      _userId = userId;
    });

    // เทสพิมพ์พ่นดูใน Debug Console ว่า ข้อมูลมาจริงไหม
    print("ระบบตรวจสอบพบ Token ปัจจุบัน: $_authToken, UserID: $_userId");

    // 🔵 3. หากมี User ID และ Token ครบถ้วน ให้ไปดึงข้อมูลจาก API ทันที
    if (_userId != null && _authToken != null) {
      _fetchToolData();
    }
  }

  // 🔵 4. ฟังก์ชันดึงข้อมูลอุปกรณ์ของ User รายนี้จาก API หลังบ้าน
  Future<void> _fetchToolData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTool = true;
    });
    try {
      final response = await ToolService.gettoolbyuser(_userId!, _authToken!);
      if (response != null && response['status'] == 'success') {
        if (!mounted) return;
        setState(() {
          _toolData = response['data']; // 🟢 เก็บส่วนของ data เอาไว้ใช้งาน
          _isLoadingTool = false;
        });
        print("ดึงข้อมูลอุปกรณ์สำเร็จ: $_toolData");
      } else {
        if (!mounted) return;
        setState(() {
          _isLoadingTool = false;
        });
        print("ไม่สามารถดึงข้อมูลอุปกรณ์ได้ หรือสถานะไม่ใช่ success");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTool = false;
      });
      print("เกิดข้อผิดพลาดในการโหลดข้อมูลอุปกรณ์: $e");
    }
  }

  // 📍 5. ฟังก์ชันเปิด Modal "ระบุสถานที่และที่ตั้ง" เมื่อกดปุ่มบันทึกข้อมูล
  // 📍 5. ฟังก์ชันเปิด Modal "ระบุสถานที่และที่ตั้ง" เมื่อกดปุ่มบันทึกข้อมูล (ฉบับแก้ไขแล้ว)
  void _showSaveLocationDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    
    // 🟢 กำหนดค่าเริ่มต้นให้กับ Dropdown เพื่อป้องกันการส่งค่า null/ว่าง ไปหา Laravel
    String? selectedProvince = "เชียงราย";
    String? selectedAmphur = "เมือง";     // อำเภอ
    String? selectedDistrict = "เวียง";   // ตำบล

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFF5EFCB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: const BorderSide(color: Colors.black87, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "ระบุสถานที่และที่ตั้ง",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ช่อง สถานที่
                    _buildLocationInputRow(
                      label: "สถานที่ :",
                      child: TextField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: InputBorder.none,
                          hintText: "เช่น แปลงนาที่ 1",
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ช่อง จังหวัด (Dropdown)
                    _buildLocationInputRow(
                      label: "จังหวัด :",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedProvince,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                          items: ["เชียงราย", "เชียงใหม่", "พะเยา", "กรุงเทพมหานคร"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() => selectedProvince = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ช่อง อำเภอ (Dropdown -> แก้ไขแมปเข้า selectedAmphur)
                    _buildLocationInputRow(
                      label: "อำเภอ :",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAmphur,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                          items: ["เมือง", "แม่สาย", "พาน", "เชียงของ"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() => selectedAmphur = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ช่อง ตำบล (Dropdown -> แก้ไขแมปเข้า selectedDistrict)
                    _buildLocationInputRow(
                      label: "ตำบล :",
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDistrict,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                          items: ["เวียง", "รอบเวียง", "บ้านดู่", "นางแล"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) {
                            setDialogState(() => selectedDistrict = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ปุ่ม ยืนยัน / ยกเลิก
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // ปุ่มยืนยัน
                        InkWell(
                          onTap: () async {
                            // 🟢 1. ตรวจสอบ Token ก่อน
                            if (_authToken == null || _userId == null || _authToken!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("ไม่พบข้อมูลการเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่อีกครั้ง")),
                              );
                              return;
                            }

                            // 🟢 2. Validation เช็คว่ากรอกข้อมูลครบถ้วนไหม
                            if (titleController.text.trim().isEmpty ||
                                selectedProvince == null ||
                                selectedAmphur == null ||
                                selectedDistrict == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("กรุณากรอกข้อมูลสถานที่และเลือกที่ตั้งให้ครบถ้วน")),
                              );
                              return;
                            }

                            // แสดง Loading Dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              // เรียกใช้ API createhistory
                              await ToolService.createhistory(
                                userId: _userId!,
                                token: _authToken!,
                                title: titleController.text.trim(),
                                province: selectedProvince!,
                                Amphur: selectedAmphur!,     // อำเภอ
                                district: selectedDistrict!, // ตำบล
                                toolData: _toolData,
                              );

                              if (context.mounted) {
                                Navigator.pop(context); // ปิด Dialog Loading
                                Navigator.pop(dialogContext); // ปิด Modal ป๊อปอัป
                                titleController.dispose();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อยแล้ว")),
                                );

                                // นำทางไปหน้า HistoryPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HistoryPage(),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // ปิด Dialog Loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("บันทึกข้อมูลไม่สำเร็จ: $e")),
                                );
                              }
                            }
                          },
                          child: Container(
                            width: 110,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6BBA90),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black87, width: 1.2),
                            ),
                            child: const Text(
                              "ยืนยัน",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // ปุ่มยกเลิก
                        InkWell(
                          onTap: () {
                            titleController.dispose();
                            Navigator.pop(dialogContext);
                          },
                          child: Container(
                            width: 110,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE26A6A),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black87, width: 1.2),
                            ),
                            child: const Text(
                              "ยกเลิก",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Widget ช่วยสร้างแถวฟอร์มระบุสถานที่ (แคปซูลขอบมน)
  Widget _buildLocationInputRow({required String label, required Widget child}) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE8C8), // สีพื้นหลังแคปซูล
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black87, width: 1),
            ),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }

  // 🌿 6. ฟังก์ชันสำหรับคำนวณหาพืชที่เหมาะสมโดยใช้ค่าจาก API (_toolData)
  void _recommendPlantsFromToolData() async {
    if (_toolData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ยังไม่มีข้อมูลสภาพดิน กรุณารอโหลดข้อมูลสักครู่")),
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
      List<dynamic> allPlants = await PlantsService.getplants();

      double? inputPH = double.tryParse(_toolData?['pH']?.toString() ?? _toolData?['ph']?.toString() ?? '');
      double? inputHumid = double.tryParse(_toolData?['humid']?.toString() ?? '');
      double? inputTemp = double.tryParse(_toolData?['temperature']?.toString() ?? '');
      double? inputSalty = double.tryParse(_toolData?['salty']?.toString() ?? '');
      double? inputN = double.tryParse(_toolData?['N']?.toString() ?? '');
      double? inputP = double.tryParse(_toolData?['P']?.toString() ?? '');
      double? inputK = double.tryParse(_toolData?['K']?.toString() ?? '');
      double? inputCa = double.tryParse(_toolData?['Ca']?.toString() ?? '');
      double? inputMg = double.tryParse(_toolData?['Mg']?.toString() ?? '');
      double? inputS = double.tryParse(_toolData?['S']?.toString() ?? '');

      List<Map<String, dynamic>> scoredPlants = [];

      for (var plant in allPlants) {
        int score = 0;

        bool checkRange(double? input, dynamic minVal, dynamic maxVal) {
          if (input == null || minVal == null || maxVal == null) return false;
          double min = double.tryParse(minVal.toString()) ?? 0.0;
          double max = double.tryParse(maxVal.toString()) ?? double.infinity;
          return input >= min && input <= max;
        }

        if (checkRange(inputPH, plant['minPH'], plant['maxPH'])) score++;
        if (checkRange(inputHumid, plant['minhumid'], plant['maxhumid'])) score++;
        if (checkRange(inputTemp, plant['mintemperature'], plant['maxtemperature'])) score++;
        if (checkRange(inputSalty, plant['minsalty'], plant['maxsalty'])) score++;
        if (checkRange(inputN, plant['minN'], plant['maxN'])) score++;
        if (checkRange(inputP, plant['minP'], plant['maxP'])) score++;
        if (checkRange(inputK, plant['minK'], plant['maxK'])) score++;
        if (checkRange(inputCa, plant['minCa'], plant['maxCa'])) score++;
        if (checkRange(inputMg, plant['minMg'], plant['maxMg'])) score++;
        if (checkRange(inputS, plant['minS'], plant['maxS'])) score++;

        scoredPlants.add({
          'plantData': plant,
          'score': score,
        });
      }

      scoredPlants.sort((a, b) => b['score'].compareTo(a['score']));
      List<Map<String, dynamic>> top5Plants = scoredPlants.take(5).toList();

      if (mounted) {
        Navigator.pop(context); 
        _showResultsBottomSheet(top5Plants); 
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการคำนวณ: $e")),
        );
      }
    }
  }

  // 🌿 UI Modal เปิดป๊อปอัปแสดงผลลัพธ์พืช 5 อันดับแรก
  void _showResultsBottomSheet(List<Map<String, dynamic>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF1E6C9),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5A36),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "แนะนำพืชปลูกที่เหมาะสมกับดิน",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var plant = items[index]['plantData'];
                    String plantName = plant['normal_name'] ?? 'ไม่ระบุชื่อ';
                    String imageUrl = plant['img_url'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6F8E5F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2E5A36), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${index + 1} $plantName",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            width: 110,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(15),
                              image: imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl.isEmpty
                                ? const Icon(Icons.eco, color: Colors.white, size: 40)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                // 🛠️ ส่วนหัว: ข้อความอุปกรณ์ + รีเฟรช ชิดซ้าย และเมนูสามขีด ชิดขวา
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "อุปกรณ์",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _isLoadingTool
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.refresh, size: 28, color: Colors.black87),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  _fetchToolData();
                                  _initThaiDateTime();
                                },
                              ),
                      ],
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
                            await _secureStorage.delete(key: "Userid");
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
                
                const SizedBox(height: 6),
                Text(
                  _currentDateTimeString.isNotEmpty
                      ? _currentDateTimeString
                      : "กำลังโหลดเวลา...",
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 35),

                // 🔵 ส่วนแสดงผล NPK จากข้อมูล API
                _buildElementRow(
                  "N", _toolData?['N']?.toString() ?? "-", 
                  "P", _toolData?['P']?.toString() ?? "-", 
                  "K", _toolData?['K']?.toString() ?? "-"
                ),
                const SizedBox(height: 20),

                // 🔵 ส่วนแสดงผล Ca, Mg, S จากข้อมูล API
                _buildElementRow(
                  "Ca", _toolData?['Ca']?.toString() ?? "-", 
                  "Mg", _toolData?['Mg']?.toString() ?? "-", 
                  "S", _toolData?['S']?.toString() ?? "-"
                ),
                const SizedBox(height: 40),

                // 🔵 ส่วนแสดงผล ความชื้น, อุณหภูมิ, ความเค็ม จากข้อมูล API
                _buildDetailRow(
                  Icons.water_drop,
                  "ความชื้น",
                  _toolData != null ? "${_toolData!['humid']} %" : "กำลังโหลด...",
                  Colors.lightBlue,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.thermostat,
                  "อุณหภูมิ",
                  _toolData != null ? "${_toolData!['temperature']} C°" : "กำลังโหลด...",
                  Colors.black54,
                ),
                const SizedBox(height: 20),
                _buildDetailRow(
                  Icons.waves,
                  "ความเค็ม",
                  _toolData != null ? "${_toolData!['salty']} us/cm" : "กำลังโหลด...",
                  Colors.black54,
                ),
                
                const Spacer(),
                // 🛠️ ปุ่มด้านล่าง: ปุ่มบันทึกข้อมูลจะเปิด Modal ระบุสถานที่
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomButton("บันทึกข้อมูล", onTap: () => _showSaveLocationDialog(context)),
                    _buildBottomButton("พืชปลูกที่เหมาะสม", onTap: _recommendPlantsFromToolData),
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
    String l1, String v1,
    String l2, String v2,
    String l3, String v3,
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

  Widget _buildBottomButton(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
      ),
    );
  }
}