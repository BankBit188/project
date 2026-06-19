import 'dart:convert';
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http;

class PlantsService {
  // 🔹 1. เปลี่ยนมาใช้ลิงก์ Ngrok ของคุณเป็นทางผ่านหลักชิ้นเดียวจบ
  static const String baseUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev/api';

  // 2. ฟังก์ชันส่วนกลางสำหรับยิง API (ปรับให้ดึงค่า baseUrl ตัวบนตรงๆ)
  static Future<dynamic> _fetchAPI(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
    // 🔹 ชี้พาธไปหา Ngrok URL ทันที
    final url = Uri.parse('$baseUrl$endpoint'); 
    
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

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

  // ดึงข้อมูลผู้ใช้ทั้งหมด (GET /plants)
  static Future<dynamic> getplants() async {
    return await _fetchAPI('/plants', method: 'GET');
  }

  // ดึงข้อมูลผู้ใช้ตาม ID (GET /plants/{id})
  static Future<dynamic> getplantsById(int id) async {
    return await _fetchAPI('/plants/$id', method: 'GET');
  }
}