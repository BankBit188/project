import 'dart:convert';
import 'package:http/http.dart' as http;

class EarthService {
  // 🔹 ใช้ URL ของ Ngrok ตัวเดียวกับระบบพืชปลูกเพื่อให้คุยกับหลังบ้านได้เสถียร
  static const String baseUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev/api';

  // ฟังก์ชันส่วนกลางสำหรับดึงหรือส่งข้อมูล API
  static Future<dynamic> _fetchAPI(String endpoint, {String method = 'GET', Map<String, dynamic>? body}) async {
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

  // 🔹 ดึงข้อมูลประเภทดินทั้งหมด (GET /earthtype)
  static Future<dynamic> getEarthTypes() async {
    return await _fetchAPI('/earthtype', method: 'GET');
  }
}