import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  // 1. กำหนด Base URL ของ API หลังบ้าน
  static const String baseUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev/api';

  // 2. ฟังก์ชันส่วนกลางสำหรับยิง API
  static Future<dynamic> _fetchAPI(
    String endpoint, {
    String method = 'GET', 
    Map<String, dynamic>? body,
    String? token, 
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      http.Response response;

      if (method == 'POST') {
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'PUT') { 
        response = await http.put(url, headers: headers, body: jsonEncode(body));
      } else if (method == 'DELETE') {
        response = await http.delete(url, headers: headers);
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

  // --------------------------------------------------------------
  // 3. ฟังก์ชันการทำงานของระบบ

  // เข้าสู่ระบบ (Login)
  static Future<dynamic> login(String email, String password) async {
    final Map<String, dynamic> bodyData = {
      'email': email,
      'password': password,
    };
    return await _fetchAPI('/login', method: 'POST', body: bodyData);
  }

  // เพิ่มผู้ใช้ / สมัครสมาชิก (POST /user)
  static Future<dynamic> createUser({
    required String username,
    required String email,
    required String password,
    String? region,
    String? province,
    String? district,
    String? amphur,
    String? toolNumberId,
  }) async {
    final Map<String, dynamic> bodyData = {
      'username': username,
      'email': email,
      'password': password,
      'Region': region,
      'province': province,
      'district': district,
      'Amphur': amphur,
      'Toolnumber_id': toolNumberId,
    };

    return await _fetchAPI('/user', method: 'POST', body: bodyData);
  }
  
  // ดึงข้อมูลผู้ใช้ทั้งหมด (GET /user)
  static Future<dynamic> getUser() async {
    return await _fetchAPI('/user', method: 'GET');
  }

  // ดึงข้อมูลรหัสเครื่องมือ (GET /toolnumber)
  static Future<dynamic> gettoolnumber() async {
    return await _fetchAPI('/toolnumber', method: 'GET');
  }

  // ดึงข้อมูลผู้ใช้ตาม ID
  static Future<dynamic> getUserById(String id, String? token) async {
    return await _fetchAPI('/user/$id', method: 'GET', token: token);
  }

  // ลบข้อมูลผู้ใช้ตาม ID
  static Future<dynamic> deleteUser(int id) async {
    return await _fetchAPI('/user/$id', method: 'DELETE');
  }

  // 🟩 ฟังก์ชันสำหรับเปลี่ยนรหัสผ่านของผู้ใช้ (เรียกผ่าน _fetchAPI)
  static Future<dynamic> updatePassword({
    required String id,
    required String oldPassword,
    required String newPassword,
    String? token,
  }) async {
    final Map<String, dynamic> bodyData = {
      'old_password': oldPassword,
      'new_password': newPassword,
    };

    // ปรับ Endpoint ให้วิ่งไปที่ /user/$id/change-password ตามโครงสร้างหลัก
    return await _fetchAPI('/user/$id/change-password', method: 'PUT', body: bodyData, token: token);
  }

  // 🟩 เพิ่มฟังก์ชันใหม่: สำหรับแก้ไขชื่อผู้ใช้งาน (Username)
  static Future<dynamic> updateUsername({
    required String id,
    required String username,
    String? token,
  }) async {
    final Map<String, dynamic> bodyData = {
      'username': username,
    };

    // ส่งแก้ไขข้อมูลไปที่ Endpoint /user/$id ด้วย method PUT
    return await _fetchAPI('/user/$id', method: 'PUT', body: bodyData, token: token);
  }
}