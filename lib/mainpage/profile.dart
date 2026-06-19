import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/service/user_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _username = "กำลังโหลด...";
  String? _userId;
  String? _authToken;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      String? token = await _secureStorage.read(key: "auth_token");
      String? userId = await _secureStorage.read(key: "user_id");

      if (token != null && userId != null) {
        _authToken = token;
        _userId = userId;

        final userData = await UserService.getUserById(_userId!, _authToken);

        setState(() {
          _username = userData['username'] ?? "ไม่ระบุชื่อ";
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _username = "ไม่พบข้อมูลผู้ใช้";
        _isLoading = false;
      });
    } catch (e) {
      print("เกิดข้อผิดพลาดในการโหลดโปรไฟล์: $e");
      setState(() {
        _username = "เกิดข้อผิดพลาด";
        _isLoading = false;
      });
    }
  }

  // 🟩 ฟังก์ชันแสดงหน้าต่างแก้ไขชื่อผู้ใช้งาน (Edit Username Dialog)
  void _showEditUsernameDialog() {
    final TextEditingController usernameController = TextEditingController(
      text: _username,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFCEEBA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black87),
          ),
          title: const Text(
            "แก้ไขชื่อผู้ใช้งาน",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้งานใหม่'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6BBA90),
              ),
              onPressed: () async {
                if (usernameController.text.trim().isEmpty) return;

                Navigator.pop(context); // ปิด Dialog
                setState(() {
                  _isLoading = true;
                });

                try {
                  // เรียกใช้งาน API อัปเดตชื่อผู้ใช้จริง
                  await UserService.updateUsername(
                    id: _userId!,
                    username: usernameController.text.trim(),
                    token: _authToken,
                  );

                  _showSnackBar("แก้ไขชื่อผู้ใช้งานสำเร็จ", Colors.green);
                  _fetchUserProfile(); // โหลดโปรไฟล์ใหม่เพื่ออัปเดตหน้าจอ
                } catch (e) {
                  _showSnackBar(
                    e.toString().replaceAll('Exception: ', ''),
                    Colors.red,
                  );
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text(
                "บันทึก",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  // 🟩 ฟังก์ชันแสดงหน้าต่างเปลี่ยนรหัสผ่าน (เปิดการคุยกับ API แล้วจริง ๆ)
  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFCEEBA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black87),
          ),
          title: const Text(
            "เปลี่ยนรหัสผ่านใหม่",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'รหัสผ่านเดิม'),
                ),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'รหัสผ่านใหม่'),
                ),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'ยืนยันรหัสผ่านใหม่',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ยกเลิก", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6BBA90),
              ),
              onPressed: () async {
                if (oldPasswordController.text.isEmpty ||
                    newPasswordController.text.isEmpty) {
                  _showSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  _showSnackBar("รหัสผ่านใหม่ไม่ตรงกัน!", Colors.red);
                  return;
                }

                Navigator.pop(context); // ปิด Dialog
                setState(() {
                  _isLoading = true;
                });

                try {
                  // เรียกใช้งาน API เปลี่ยนรหัสผ่านของจริง
                  await UserService.updatePassword(
                    id: _userId!,
                    oldPassword: oldPasswordController.text,
                    newPassword: newPasswordController.text,
                    token: _authToken,
                  );

                  _showSnackBar("เปลี่ยนรหัสผ่านสำเร็จแล้ว", Colors.green);
                } catch (e) {
                  // พ่นข้อความ Error ที่เกิดขึ้นมาดูใน Debug Console
                  print("Error: $e");
                  _showSnackBar(
                    e.toString().replaceAll('Exception: ', ''),
                    Colors.red,
                  );
                } finally {
                  // 🟩 จุดสำคัญ: ไม่ว่าจะผ่านหรือเอ๋อ ต้องสั่งปิดการหมุนตรงนี้เสมอ!
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              child: const Text(
                "บันทึก",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.reply,
                              size: 35,
                              color: Colors.black,
                            ),
                            onPressed: () => Navigator.pop(context),
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

                      Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xFFA05A2C),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 110,
                            height: 45,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA05A2C),
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _username,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap:
                                _showEditUsernameDialog, // 🟩 ผูกปุ่มแก้ไขเข้ากับหน้าต่างเปลี่ยนชื่อเล่น
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCDCDC),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              "********",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          InkWell(
                            onTap: _showChangePasswordDialog,
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
