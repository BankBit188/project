import 'package:flutter/material.dart';
import 'package:project/menu.dart';

// 1. ===== Import สองบรรทัดนี้เพิ่ม =====
import 'package:provider/provider.dart';
import 'package:project/user_model.dart'; // (ตรวจสอบว่า path นี้ถูกต้อง)
void main() {
  // 2. ===== แก้ไขส่วน runApp =====
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserModel(), // สร้าง UserModel ให้แอป"รู้จัก"
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MenuPage(),
    );
  }
}