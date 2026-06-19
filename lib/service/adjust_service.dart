import 'dart:convert';
import 'package:http/http.dart' as http;

class AdjustService {
  // 🔹 ใช้ลิงก์อุโมงค์ Ngrok หลักเพื่อยิงทะลุระบบความปลอดภัยของหลังบ้านคอมพิวเตอร์
  static const String baseUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev/api';

  // ฟังก์ชันยิงเซิร์ฟเวอร์ส่วนกลาง
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

  // 🔹 ดึงข้อมูลวิธีการปรับสภาพดินทั้งหมด (GET /adjust)
  static Future<dynamic> getAdjustments() async {
    return await _fetchAPI('/adjust', method: 'GET');
  }
}