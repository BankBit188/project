import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/service/user_service.dart';
import 'package:project/style/style_profile.dart';

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
      String? userId = await _secureStorage.read(key: "Userid");

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

  void _showEditUsernameDialog() {
    final TextEditingController usernameController = TextEditingController(
      text: _username,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProfileEditUsernameDialog(
          controller: usernameController,
          onSave: () async {
            if (usernameController.text.trim().isEmpty) return;

            Navigator.pop(context);
            setState(() {
              _isLoading = true;
            });

            try {
              await UserService.updateUsername(
                id: _userId!,
                username: usernameController.text.trim(),
                token: _authToken,
              );

              _showSnackBar("แก้ไขชื่อผู้ใช้งานสำเร็จ", Colors.green);
              _fetchUserProfile();
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
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProfileChangePasswordDialog(
          oldPasswordController: oldPasswordController,
          newPasswordController: newPasswordController,
          confirmPasswordController: confirmPasswordController,
          onSave: () async {
            if (oldPasswordController.text.isEmpty ||
                newPasswordController.text.isEmpty) {
              _showSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
              return;
            }

            if (newPasswordController.text != confirmPasswordController.text) {
              _showSnackBar("รหัสผ่านใหม่ไม่ตรงกัน!", Colors.red);
              return;
            }

            Navigator.pop(context);
            setState(() {
              _isLoading = true;
            });

            try {
              await UserService.updatePassword(
                id: _userId!,
                oldPassword: oldPasswordController.text,
                newPassword: newPasswordController.text,
                token: _authToken,
              );

              _showSnackBar("เปลี่ยนรหัสผ่านสำเร็จแล้ว", Colors.green);
            } catch (e) {
              print("Error: $e");
              _showSnackBar(
                e.toString().replaceAll('Exception: ', ''),
                Colors.red,
              );
            } finally {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: ProfileTheme.pageDecoration,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: ProfileTheme.primaryGreen,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Header (ไอคอนอยู่ขวาสุด)
                      ProfileHeaderWidget(
                        onBackPressed: () => Navigator.pop(context),
                      ),

                      const SizedBox(height: 35),

                      // 2. Avatar (ไอคอนสีเขียว + ขอบดำมีเงา)
                      const ProfileAvatarWidget(),

                      const SizedBox(height: 30),

                      // 3. Username Tile
                      ProfileUsernameTile(
                        username: _username,
                        onEditPressed: _showEditUsernameDialog,
                      ),

                      const SizedBox(height: 16),

                      // 4. Password Tile
                      ProfilePasswordTile(
                        onEditPressed: _showChangePasswordDialog,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}