import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:project/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ---------- ตัวแปรสำหรับจัดการข้อมูลที่อยู่ ----------
  List<dynamic> _allProvinces = []; // เก็บข้อมูล JSON ทั้งหมด
  
  // ลิสต์ตัวเลือกที่ผ่านการกรองแล้ว
  List<Map<String, dynamic>> _regions = [
    {'id': 1, 'name': 'ภาคเหนือ'},
    {'id': 2, 'name': 'ภาคกลาง'},
    {'id': 3, 'name': 'ภาคตะวันออกเฉียงเหนือ'},
    {'id': 4, 'name': 'ภาคตะวันตก'},
    {'id': 5, 'name': 'ภาคตะวันออก'},
    {'id': 6, 'name': 'ภาคใต้'},
  ];
  List<dynamic> _filteredProvinces = [];
  List<dynamic> _filteredAmphures = [];
  List<dynamic> _filteredTambons = [];

  // ค่าที่ผู้ใช้กำลังเลือก (เก็บเป็น ID)
  int? _selectedRegionId;
  int? _selectedProvinceId;
  int? _selectedAmphureId;
  int? _selectedTambonId;

  @override
  void initState() {
    super.initState();
    _loadAddressData(); // โหลดข้อมูลตอนเปิดหน้า
  }

  // ฟังก์ชันโหลดและแปลงไฟล์ JSON
  Future<void> _loadAddressData() async {
    try {
      // ตรวจสอบ path ให้ตรงกับ pubspec.yaml ของคุณ
      String jsonString = await rootBundle.loadString('assets/data/thailand_data.json');
      setState(() {
        _allProvinces = jsonDecode(jsonString);
      });
    } catch (e) {
      debugPrint("Error loading JSON: $e");
    }
  }

  // ---------- Logic การเลือก Dropdown ----------

  void _onRegionChanged(int? regionId) {
    setState(() {
      _selectedRegionId = regionId;
      // รีเซ็ตค่าลูกทั้งหมด
      _selectedProvinceId = null;
      _selectedAmphureId = null;
      _selectedTambonId = null;
      _filteredAmphures = [];
      _filteredTambons = [];
      
      // กรองจังหวัดที่ geography_id ตรงกับภาคที่เลือก
      _filteredProvinces = _allProvinces.where((p) => p['geography_id'] == regionId).toList();
    });
  }

  void _onProvinceChanged(int? provinceId) {
    setState(() {
      _selectedProvinceId = provinceId;
      // รีเซ็ตค่าลูกทั้งหมด
      _selectedAmphureId = null;
      _selectedTambonId = null;
      _filteredTambons = [];

      // ดึงอาเรย์ amphure ออกมาจากจังหวัดที่เลือก
      var province = _filteredProvinces.firstWhere((p) => p['id'] == provinceId);
      _filteredAmphures = province['amphure'] ?? [];
    });
  }

  void _onAmphureChanged(int? amphureId) {
    setState(() {
      _selectedAmphureId = amphureId;
      // รีเซ็ตค่าตำบล
      _selectedTambonId = null;

      // ดึงอาเรย์ tambon ออกมาจากอำเภอที่เลือก
      var amphure = _filteredAmphures.firstWhere((a) => a['id'] == amphureId);
      _filteredTambons = amphure['tambon'] ?? [];
    });
  }

  void _onTambonChanged(int? tambonId) {
    setState(() {
      _selectedTambonId = tambonId;
      // หากต้องการรหัสไปรษณีย์ สามารถดึงตรงนี้ได้เลย
      // var tambon = _filteredTambons.firstWhere((t) => t['id'] == tambonId);
      // print("Zip Code: ${tambon['zip_code']}");
    });
  }

  // ------------------------------------------

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(  
                  onTap: () {
                    // ใช้ pushReplacement เพื่อไม่ให้ผู้ใช้กดกลับมาหน้า Login ได้อีกผ่านปุ่ม back ของมือถือ
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()), // เปลี่ยน LoginPage เป็นชื่อ Class ของคุณ
                    );
                  },
                  child: const Icon(Icons.reply, size: 40, color: Colors.black),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    "ลงทะเบียนอุปกรณ์",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 30),
                
                Row(
                  children: [
                    Expanded(child: _buildTextField("หมายเลขอุปกรณ์")),
                    const SizedBox(width: 10),
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECE1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black54),
                      ),
                      child: const Center(
                        child: Text("ตรวจสอบ", style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // --------- เปลี่ยนเป็นเรียก _buildDynamicDropdown ---------
                _buildDynamicDropdown(
                  hint: "ภาค",
                  value: _selectedRegionId,
                  items: _regions,
                  onChanged: _onRegionChanged,
                  displayKey: 'name', // key ใน Map ของภาค
                ),
                const SizedBox(height: 15),
                _buildDynamicDropdown(
                  hint: "จังหวัด",
                  value: _selectedProvinceId,
                  items: _filteredProvinces,
                  onChanged: _onProvinceChanged,
                ),
                const SizedBox(height: 15),
                _buildDynamicDropdown(
                  hint: "อำเภอ",
                  value: _selectedAmphureId,
                  items: _filteredAmphures,
                  onChanged: _onAmphureChanged,
                ),
                const SizedBox(height: 15),
                _buildDynamicDropdown(
                  hint: "ตำบล",
                  value: _selectedTambonId,
                  items: _filteredTambons,
                  onChanged: _onTambonChanged,
                ),
                // --------------------------------------------------------

                const SizedBox(height: 15),
                _buildTextField("ชื่อผู้ใช้"),
                const SizedBox(height: 15),
                _buildTextField("อีเมล"),
                const SizedBox(height: 15),
                
                _buildPasswordField(
                  hint: "รหัสผ่าน",
                  isObscure: _obscurePassword,
                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                const SizedBox(height: 15),
                
                _buildPasswordField(
                  hint: "ยืนยันรหัสผ่าน",
                  isObscure: _obscureConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
                const SizedBox(height: 30),
                
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // ส่ง _selectedProvinceId, _selectedAmphureId, _selectedTambonId ไปบันทึกลง Database ได้เลย
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D460B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "ลงทะเบียนอุปกรณ์",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget สร้าง TextField ธรรมดา
  Widget _buildTextField(String hint) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  // Widget สร้าง Dropdown แบบมีข้อมูลเชื่อมโยง
  Widget _buildDynamicDropdown({
    required String hint,
    required int? value,
    required List<dynamic> items,
    required void Function(int?) onChanged,
    String displayKey = 'name_th', // Default ใช้ 'name_th' สำหรับไฟล์ JSON Kongvut
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          hint: Text(hint),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items.map<DropdownMenuItem<int>>((dynamic item) {
            return DropdownMenuItem<int>(
              value: item['id'],
              child: Text(item[displayKey] ?? ''),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Widget สร้าง TextField สำหรับรหัสผ่านพร้อมปุ่มเปิด/ปิดตา
  Widget _buildPasswordField({
    required String hint,
    required bool isObscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        obscureText: isObscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.black54,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}