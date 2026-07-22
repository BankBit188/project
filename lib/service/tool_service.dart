import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;

class ToolService {
  // 🔹 1. ลิงก์ Ngrok สำหรับเป็นทางผ่านหลัก
  static const String baseUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev/api';

  // 2. ฟังก์ชันส่วนกลางสำหรับยิง API (เพิ่มให้รองรับการรับค่า token เพื่อใส่ใน Header)
  static Future<dynamic> _fetchAPI(
    String endpoint, {
    String method = 'GET', 
    Map<String, dynamic>? body,
    String? token, // 🟩 เพิ่มพารามิเตอร์รับ token ตรงนี้
  }) async {
    // 🔹 ชี้พาธไปหา Ngrok URL ทันที
    final url = Uri.parse('$baseUrl$endpoint'); 
    
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    // 🟩 ถ้ามีการส่ง token มา ให้แนบ Authorization Bearer เข้าไปใน Header
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      http.Response response;

      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      } else {
        response = await http.get(url, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'HTTP error! status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 🟩 ปรับปรุงให้รับค่า 2 ตัวคือ id และ token เพื่อส่งต่อไปยัง API หลังบ้าน
  // (เปลี่ยนชนิดข้อมูล id จาก int เป็น String เพื่อให้ตรงกับข้อความที่ดึงมาจาก Secure Storage)
  static Future<dynamic> gettoolbyuser(String id, String token) async {
    return await _fetchAPI(
      '/tool/byuser/$id', 
      method: 'GET',
      token: token, // 🟩 ส่ง token ต่อไปให้ฟังก์ชันส่วนกลางใช้งาน
    );
  }
  static Future<dynamic> createhistory({
    required String userId,
    required String token,
    required String title,
    required String province,
    required String district,
    required String Amphur,
    Map<String, dynamic>? toolData, // ข้อมูลเซนเซอร์ทั้งหมดจากอุปกรณ์
  }) async {
    // รวบรวมข้อมูลทั้งหมดเข้าด้วยกันใน Map
    final Map<String, dynamic> requestBody = {
      'Userid': userId,
      'title': title,
      'province': province,
      'Amphur': Amphur,
      'district': district,
      // รวมค่าเซนเซอร์ทั้งหมดลงไปใน Body (เช่น N, P, K, Ca, Mg, S, humid, temperature, salty, pH)
      if (toolData != null) ...toolData,
    };

    return await _fetchAPI(
      '/history/create', 
      method: 'POST',
      body: requestBody,
      token: token, // ส่ง token ต่อไปให้ฟังก์ชันส่วนกลางใช้งาน
    );
  }
  
  static Future<dynamic> gethistorybyuser(String userId, String token) async {
    return await _fetchAPI(
      '/history/user/$userId',
      method: 'GET',
      token: token,
    );
  }
}