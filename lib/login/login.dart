import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'package:project/mainpage/tool.dart'; 
import 'package:project/login/register.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/service/user_service.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isLoading = false; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🟩 ฟังก์ชันล็อกอินที่ได้รับการอัปเดตระบบเซฟ ID
  void _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("กรุณากรอกข้อมูลให้ครบถ้วน", Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await UserService.login(email, password); 
      if (result['token'] != null) {
        await _secureStorage.write(key: "auth_token", value: result['token']);

        if (result['user'] != null) {
          final userData = result['user'];
          final idToSave = userData['Userid'] ?? userData['id'];
          
          // 🟩 เพิ่มคำสั่ง Print เพื่อดูว่าไอดีที่จะเซฟคือเลขอะไร
          print("ID ที่สกัดได้เตรียมบันทึก: $idToSave");

          if (idToSave != null) {
            await _secureStorage.write(key: "user_id", value: idToSave.toString());
            
            // 🟩 เพิ่มคำสั่งยืนยันการบันทึก
            print("บันทึก user_id สำเร็จแล้ว!");
          }
        }

        _showSnackBar("เข้าสู่ระบบสำเร็จ", Colors.green);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ToolPage()),
            (route) => false, 
          );
        }
      } else {
        _showSnackBar("อีเมลหรือรหัสผ่านไม่ถูกต้อง", Colors.red);
      }
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
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
                padding: const EdgeInsets.all(30.0),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 60, 
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(  
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MenuPage()),
                                    );
                                  },
                                  child: const Icon(Icons.reply, size: 40, color: Colors.black),
                                ),
                                const SizedBox(height: 50),
                                const Center(
                                  child: Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 40),
                                _buildTextField("อีเมล", _emailController),
                                const SizedBox(height: 20),
                                _buildTextField("รหัสผ่าน", _passwordController, obscureText: true),
                                const SizedBox(height: 30),
                                _buildButton("เข้าสู่ระบบ", const Color(0xFF4C8E16), _handleLogin),
                                const SizedBox(height: 15),
                                _buildButton("ลงทะเบียนอุปกรณ์", const Color(0xFF1D460B), () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                                  );
                                }),
                                const SizedBox(height: 20),
                                const Center(
                                  child: Text("ลืมรหัสผ่าน?", style: TextStyle(color: Colors.black54, fontSize: 16)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller, 
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.black87)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}