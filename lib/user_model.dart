import 'package:flutter/material.dart';

class UserModel extends ChangeNotifier {
  String? _userName;
  String? _email;

  String? get userName => _userName;
  String? get email => _email;

  // ฟังก์ชันสำหรับจำลองการ Login
  void setUser(String name, String email) {
    _userName = name;
    _email = email;
    
    // สำคัญมาก: แจ้งเตือน Widget ที่ฟังอยู่ให้เปลี่ยนหน้าหรือแสดงข้อมูลใหม่
    notifyListeners();
  }

  // ฟังก์ชันสำหรับ Logout
  void logout() {
    _userName = null;
    _email = null;
    notifyListeners();
  }
}