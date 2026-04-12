import 'package:flutter/material.dart';
import 'package:project/tool.dart'; // โยงไปหน้าอุปกรณ์หลังล็อกอินเสร็จ
import 'package:project/register.dart';
import 'package:project/menu.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(  
                  onTap: () {
                    // ใช้ pushReplacement เพื่อไม่ให้ผู้ใช้กดกลับมาหน้า Login ได้อีกผ่านปุ่ม back ของมือถือ
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MenuPage()), // เปลี่ยน MenuPage เป็นชื่อ Class ของคุณ
                    );
                  },
                  child: const Icon(Icons.reply, size: 40, color: Colors.black),
                ),
                const SizedBox(height: 50),
                const Center(
                  child: Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 40),
                _buildTextField("อีเมล"),
                const SizedBox(height: 20),
                _buildTextField("รหัสผ่าน", obscureText: true),
                const SizedBox(height: 30),
                _buildButton("เข้าสู่ระบบ", const Color(0xFF4C8E16), () {
                  // ล็อกอินสำเร็จ ไปหน้า Tool
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ToolPage()));
                }),
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
    );
  }

  Widget _buildTextField(String hint, {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECE1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
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