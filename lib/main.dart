import 'package:flutter/material.dart';
import 'package:project/mainpage/menu.dart';

// 1. ===== Import สองบรรทัดนี้เพิ่ม =====
import 'package:provider/provider.dart';
import 'package:project/user_model.dart'; // (ตรวจสอบว่า path นี้ถูกต้อง)

import 'dart:io';

void main() {

  HttpOverrides.global = MyHttpOverrides();
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
      debugShowCheckedModeBanner: false,
      home: MenuPage(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // 🔹 บังคับให้ HttpClient ปล่อยวาง Connection ทันทีที่โหลดรูปเสร็จ 
    // ช่วยให้ PHP Artisan Serve หลังบ้านไม่เกิดอาการท่อตันจนตัดการเชื่อมต่อหนี
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
    return client;
  }
}