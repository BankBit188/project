import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:project/mainpage/menu.dart';
import 'package:project/user_model.dart'; // (ตรวจสอบว่า path นี้ถูกต้อง)

// 🔹 แก้ไขตรงนี้: เติม Future<void> และ async เพื่อให้ใช้ await dotenv.load ได้
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // โหลดไฟล์ .env ก่อนเริ่มรันแอป
  await dotenv.load(fileName: ".env");
  
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    ChangeNotifierProvider(
      create: (context) => UserModel(), // สร้าง UserModel ให้แอป "รู้จัก"
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuPage(),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    
    // 🔹 บังคับให้ HttpClient ยอมรับ SSL/Certificate สำหรับการทดสอบ
    client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    
    return client;
  }
}