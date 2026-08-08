import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 📌 1. Import FlutterSecureStorage
import 'package:http/http.dart' as http;

class ToolService {
  // 🔹 1. ลิงก์ Ngrok สำหรับเป็นทางผ่านหลัก
  static const String baseUrl = 'https://api-project-production-0935.up.railway.app/api';

  // 📌 2. ประกาศใช้งาน FlutterSecureStorage
  static const _secureStorage = FlutterSecureStorage();

  // 🔒 3. ฟังก์ชันดึง Token จาก Secure Storage ด้วย Key "auth_token"
  static Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  // 4. ฟังก์ชันส่วนกลางสำหรับยิง API
  static Future<dynamic> _fetchAPI(
    String endpoint, {
    String method = 'GET', 
    Map<String, dynamic>? body,
    String? token, // รองรับรับ token จากภายนอก หรือให้ดึงจาก SecureStorage อัตโนมัติ
  }) async {
    final url = Uri.parse('$baseUrl$endpoint'); 
    
    try {
      // 🔒 ดึง token จาก Secure Storage หากไม่ได้ถูกส่งเข้ามาตรงๆ
      final authToken = token ?? await _getToken();

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Unauthenticated: ไม่พบ Token ในระบบ กรุณาเข้าสู่ระบบใหม่');
      }

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $authToken', // 🔒 แนบ Token เข้าไปใน Header
      };

      http.Response response;

      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      } else {
        response = await http.get(url, headers: headers);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        // 🔒 ดักจับเมื่อ Token หมดอายุ หรือไม่ผ่านการตรวจสอบจากหลังบ้าน
        throw Exception('Unauthenticated: Token ไม่ถูกต้องหรือหมดอายุ (401)');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'HTTP error! status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // 🔹 1. ดึงข้อมูลเครื่องมือตาม User ID
  // (ปรับให้ token เป็น optional [String? token] จะส่งมาหรือไม่ส่งมาก็ได้)
  static Future<dynamic> gettoolbyuser(String id, [String? token]) async {
    return await _fetchAPI(
      '/tool/byuser/$id', 
      method: 'GET',
      token: token,
    );
  }

  // 🔹 2. สร้างประวัติบันทึกค่าเซนเซอร์
  static Future<dynamic> createhistory({
    required String userId,
    required String title,
    required String province,
    required String district,
    required String Amphur,
    required String region,

    Map<String, dynamic>? toolData,
    String? token, // สามารถส่ง token มาเพิ่ม หรือปล่อยว่างให้ดึงจาก Storage เองได้
  }) async {
    final Map<String, dynamic> requestBody = {
      'Userid': userId,
      'title': title,
      'Region': region,
      'province': province,
      'Amphur': Amphur,
      'district': district,
      
      if (toolData != null) ...toolData,
    };

    return await _fetchAPI(
      '/history/create', 
      method: 'POST',
      body: requestBody,
      token: token,
    );
  }
  
  // 🔹 3. ดึงประวัติการวัดค่าตาม User ID
  static Future<dynamic> gethistorybyuser(String userId, [String? token]) async {
    return await _fetchAPI(
      '/history/user/$userId',
      method: 'GET',
      token: token,
    );
  }
}