import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:project/login/login.dart';
// 🟩 1. Import UserService เข้ามาใช้งาน
import 'package:project/service/user_service.dart'; 

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 🟩 2. เพิ่ม Controllers สำหรับดึงข้อมูลจากช่องกรอก
  final TextEditingController _toolNumberController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // ตัวแปรเช็กสถานะว่าตรวจสอบหมายเลขอุปกรณ์ผ่านหรือยัง
  bool _isToolVerified = false;

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

  String? _selectedRegionName;
  String? _selectedProvinceName;
  String? _selectedAmphureName;
  String? _selectedTambonName;

  @override
  void initState() {
    super.initState();
    _loadAddressData(); // โหลดข้อมูลตอนเปิดหน้า
  }

  // 🟩 ปิดการทำงานของ Controllers เมื่อย้ายหน้าเพื่อประหยัด RAM
  @override
  void dispose() {
    _toolNumberController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ฟังก์ชันโหลดและแปลงไฟล์ JSON
  Future<void> _loadAddressData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data/thailand_data.json');
      setState(() {
        _allProvinces = jsonDecode(jsonString);
      });
    } catch (e) {
      debugPrint("Error loading JSON: $e");
    }
  }

  // 🟩 3. ฟังก์ชันตรวจสอบหมายเลขอุปกรณ์ (ปรับปรุงเพื่อแสดง Alert และเปลี่ยนไอคอนปุ่ม)
  void _checkToolNumber() async {
    String inputToolNumber = _toolNumberController.text.trim();

    if (inputToolNumber.isEmpty) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณากรอกหมายเลขอุปกรณ์ก่อนทำการตรวจสอบ", isWarning: true);
      return;
    }

    try {
      // เรียกใช้ฟังก์ชันดึงข้อมูลรหัสเครื่องมือจากระบบหลังบ้าน
      final response = await UserService.gettoolnumber();

      bool isExist = false;
      if (response is List) {
        // วนลูปเช็กว่าข้อมูลที่กรอก ตรงกับค่าในคีย์ใดคีย์หนึ่งของฐานข้อมูลไหม
        isExist = response.any((item) =>
            item['Toolnumber_id']?.toString() == inputToolNumber);
      }

      setState(() {
        _isToolVerified = isExist;
      });

      if (isExist) {
        _showAlertDialog("ตรวจสอบสำเร็จ", "หมายเลขอุปกรณ์ถูกต้อง", isWarning: false);
      } else {
        _showAlertDialog("ตรวจสอบล้มเหลว", "หมายเลขอุปกรณ์ไม่ถูกต้อง", isWarning: true);
      }
    } catch (e) {
      _showAlertDialog("เกิดข้อผิดพลาด", "เกิดข้อผิดพลาดในการเชื่อมต่อเซิร์ฟเวอร์: $e", isWarning: true);
    }
  }

  // ฟังก์ชันหน้าต่างแจ้งเตือน Alert Dialog
  void _showAlertDialog(String title, String message, {bool isWarning = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded, 
                color: isWarning ? Colors.orange : Colors.green, 
                size: 28
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ตกลง", style: TextStyle(color: Color(0xFF1D460B), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // 🟩 4. ฟังก์ชันส่งข้อมูลสมัครสมาชิก (ปุ่ม ลงทะเบียนอุปกรณ์)
  void _handleRegister() async {
    // 1. ตรวจสอบว่ากรอกข้อความครบทุกช่องหรือยัง (หากว่างอยู่ให้เปิด Alert ทันที)
    if (_toolNumberController.text.trim().isEmpty) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณากรอก หมายเลขอุปกรณ์");
      return;
    }
    if (_selectedRegionName == null) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณาเลือก ภาค");
      return;
    }
    if (_selectedProvinceName == null) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณาเลือก จังหวัด");
      return;
    }
    if (_selectedAmphureName == null) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณาเลือก อำเภอ");
      return;
    }
    if (_selectedTambonName == null) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณาเลือก ตำบล");
      return;
    }
    if (_usernameController.text.trim().isEmpty) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณากรอก ชื่อผู้ใช้");
      return;
    }
    if (_emailController.text.trim().isEmpty) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณากรอก อีเมล");
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณากรอก รหัสผ่าน");
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _showAlertDialog("กรอกข้อมูลไม่ครบ", "กรุณากรอก ยืนยันรหัสผ่าน");
      return;
    }

    // 2. เช็กระบบความปลอดภัยว่าผ่านการตรวจสอบหมายเลขอุปกรณ์หรือยัง
    if (!_isToolVerified) {
      _showAlertDialog("ยังไม่ได้ตรวจสอบอุปกรณ์", "กรุณากดปุ่มตรวจสอบหมายเลขอุปกรณ์ให้ถูกต้องก่อนลงทะเบียน");
      return;
    }

    // 3. เช็กว่ารหัสผ่านและยืนยันรหัสผ่านกรอกตรงกันไหม
    if (_passwordController.text != _confirmPasswordController.text) {
      _showAlertDialog("รหัสผ่านไม่ตรงกัน", "รหัสผ่าน และ ยืนยันรหัสผ่าน ของคุณไม่ตรงกัน กรุณาตรวจสอบอีกครั้ง");
      return;
    }

    // 4. เมื่อผ่านเงื่อนไขครบหมดแล้ว ทำการยิง API สมัครสมาชิก
    try {
      // ตัดคำว่า "ภาค" ออกให้เหลือแต่ชื่อ เช่น "เหนือ", "กลาง"
      String? formattedRegion = _selectedRegionName?.replaceAll('ภาค', '');

      // เรียกใช้งาน UserService ส่งข้อมูลไปบันทึก
      final result = await UserService.createUser(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        region: formattedRegion,
        province: _selectedProvinceName,
        district: _selectedAmphureName, // อำเภอ
        amphur: _selectedTambonName,    // ตำบล
        toolNumberId: _toolNumberController.text.trim(),
      );

      _showSnackBar(result['message'] ?? 'สมัครสมาชิกสำเร็จ!', Colors.green);

      // ย้ายหน้ากลับไปที่หน้าล็อกอิน
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      // ดักจับ Error จาก Laravel หรือ Error Network แล้วโชว์ผ่าน SnackBar สีแดง
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    }
  }

  // ฟังก์ชันทางลัดสำหรับเรียกเปิด SnackBar แจ้งเตือน
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  // ---------- Logic การเลือก Dropdown ----------
  void _onRegionChanged(String? regionName) {
    setState(() {
      _selectedRegionName = regionName;
      _selectedProvinceName = null;
      _selectedAmphureName = null;
      _selectedTambonName = null;
      _filteredAmphures = [];
      _filteredTambons = [];
      
      var region = _regions.firstWhere((r) => r['name'] == regionName, orElse: () => {});
      if (region.isNotEmpty) {
        _filteredProvinces = _allProvinces.where((p) => p['geography_id'] == region['id']).toList();
      } else {
        _filteredProvinces = [];
      }
    });
  }

  void _onProvinceChanged(String? provinceName) {
    setState(() {
      _selectedProvinceName = provinceName;
      _selectedAmphureName = null;
      _selectedTambonName = null;
      _filteredTambons = [];

      var province = _filteredProvinces.firstWhere((p) => p['name_th'] == provinceName, orElse: () => {});
      if (province.isNotEmpty) {
        _filteredAmphures = province['amphure'] ?? [];
      } else {
        _filteredAmphures = [];
      }
    });
  }

  void _onAmphureChanged(String? amphureName) {
    setState(() {
      _selectedAmphureName = amphureName;
      _selectedTambonName = null;

      var amphure = _filteredAmphures.firstWhere((a) => a['name_th'] == amphureName, orElse: () => {});
      if (amphure.isNotEmpty) {
        _filteredTambons = amphure['tambon'] ?? [];
      } else {
        _filteredTambons = [];
      }
    });
  }

  void _onTambonChanged(String? tambonName) {
    setState(() {
      _selectedTambonName = tambonName;
    });
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(  
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()), 
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
                    Expanded(child: _buildTextField("หมายเลขอุปกรณ์", _toolNumberController)),
                    const SizedBox(width: 10),
                    // 🟩 ปรับเปลี่ยนดีไซน์ปุ่มตรวจสอบตรงนี้ตามสถานะ _isToolVerified
                    GestureDetector(
                      onTap: _checkToolNumber, 
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: _isToolVerified ? Colors.green : const Color(0xFFF3ECE1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _isToolVerified ? Colors.green : Colors.black54),
                        ),
                        child: Center(
                          // เปลี่ยนข้อความเป็นเครื่องหมายเช็คถูกเมื่อผ่านการตรวจ
                          child: _isToolVerified 
                              ? const Icon(Icons.check, color: Colors.white, size: 24)
                              : const Text("ตรวจสอบ", style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                _buildDynamicDropdown(
                  hint: "ภาค",
                  value: _selectedRegionName,
                  items: _regions,
                  onChanged: _onRegionChanged,
                  displayKey: 'name',
                  valueKey: 'name',   
                ),
                const SizedBox(height: 15),
                _buildDynamicDropdown(
                  hint: "จังหวัด",
                  value: _selectedProvinceName,
                  items: _filteredProvinces,
                  onChanged: _onProvinceChanged,
                  displayKey: 'name_th',
                  valueKey: 'name_th',
                ),
                const SizedBox(height: 15),
                _buildDynamicDropdown(
                  hint: "อำเภอ",
                  value: _selectedAmphureName,
                  items: _filteredAmphures,
                  onChanged: _onAmphureChanged,
                  displayKey: 'name_th',
                  valueKey: 'name_th',
                ),
                const SizedBox(height: 15),
                _buildDynamicDropdown(
                  hint: "ตำบล",
                  value: _selectedTambonName,
                  items: _filteredTambons,
                  onChanged: _onTambonChanged,
                  displayKey: 'name_th',
                  valueKey: 'name_th',
                ),

                const SizedBox(height: 15),
                _buildTextField("ชื่อผู้ใช้", _usernameController),
                const SizedBox(height: 15),
                _buildTextField("อีเมล", _emailController),
                const SizedBox(height: 15),
                
                _buildPasswordField(
                  hint: "รหัสผ่าน",
                  controller: _passwordController,
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
                  controller: _confirmPasswordController,
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
                    onPressed: _handleRegister, 
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

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextField(
        controller: controller, 
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildDynamicDropdown({
    required String hint,
    required String? value, 
    required List<dynamic> items,
    required void Function(String?) onChanged, 
    String displayKey = 'name_th',
    String valueKey = 'name_th', 
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>( 
          isExpanded: true,
          hint: Text(hint),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
          items: items.map<DropdownMenuItem<String>>((dynamic item) {
            return DropdownMenuItem<String>(
              value: item[valueKey]?.toString(), 
              child: Text(item[displayKey]?.toString() ?? ''),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required TextEditingController controller, 
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
        controller: controller,
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