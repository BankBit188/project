import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 📌 1. เปลี่ยนมาใช้ FlutterSecureStorage
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ReportsService {
  // 🔹 ใช้ URL ของ Ngrok ตามโครงสร้างเดิม
  static const String baseUrl = 'https://api-project-production-0935.up.railway.app/api';

  // 📌 2. ประกาศใช้งาน FlutterSecureStorage
  static const _secureStorage = FlutterSecureStorage();

  // 🔒 3. ปรับฟังก์ชันดึง Token จาก Secure Storage ด้วย Key "auth_token"
  static Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'auth_token'); 
  }

  // ฟังก์ชันส่วนกลางสำหรับดึงหรือส่งข้อมูล API
  static Future<dynamic> _fetchAPI(
    String endpoint, {
    String method = 'GET', 
    Map<String, String>? body, 
    File? imageFile, 
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      // 🔒 ตรวจสอบ Token ก่อนทำการยิง API
      final token = await _getToken();  
      if (token == null || token.isEmpty) {
        throw Exception('Unauthenticated: ไม่พบ Token ในระบบ กรุณาเข้าสู่ระบบใหม่');
      }

      // 🟩 กรณีที่ 1: มีการส่งไฟล์รูปภาพ หรือส่งผ่าน POST แบบอัปโหลดรูป
      if (method == 'POST' && imageFile != null) {
        final request = http.MultipartRequest('POST', url);
        
        // 🔒 ใส่ Headers รับ JSON และแนบ Bearer Token เข้าไปด้วย
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';

        // แนบข้อมูล Text ปกติ (ถ้ามี)
        if (body != null) {
          request.fields.addAll(body);
        }

        // แนบไฟล์รูปภาพ
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'img',
          stream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);

        // ส่งข้อมูลแบบ Multipart ไปที่หลังบ้าน
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        return _handleResponse(response);
      } 
      
      // 🟩 กรณีที่ 2: เป็นการดึงข้อมูล GET หรือ POST แบบ JSON ธรรมดา
      else {
        // 🔒 แนบ Bearer Token ลงใน Header
        final headers = {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };

        http.Response response;
        if (method == 'POST') {
          response = await http.post(url, headers: headers, body: jsonEncode(body));
        } else {
          response = await http.get(url, headers: headers);
        }

        return _handleResponse(response);
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ฟังก์ชันจัดการ Response
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // 🔒 ดักจับเมื่อ Token หมดอายุ หรือไม่ผ่านการตรวจสอบจาก Laravel Sanctum
      throw Exception('Unauthenticated: Token ไม่ถูกต้องหรือหมดอายุ (401)');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'HTTP error! status: ${response.statusCode}');
    }
  }

  // --------------------------------------------------------------
  // 🔹 1. ฟังก์ชันดึงข้อมูลรายงานทั้งหมด (GET /report)
  static Future<dynamic> getReports() async {
    return await _fetchAPI('/report', method: 'GET');
  }

  // 🔹 2. ฟังก์ชันดึงข้อมูลรายงานระบุเจาะจงราย ID (GET /report/{id})
  static Future<dynamic> getReportById(String reportId) async {
    return await _fetchAPI('/report/$reportId', method: 'GET');
  }

  // 🔹 3. ฟังก์ชันเพิ่มข้อมูลรายงานใหม่พร้อมไฟล์รูปภาพ (POST /report)
  static Future<dynamic> createReport({
    required Map<String, String> reportData,
    File? imageFile,
  }) async {
    return await _fetchAPI(
      '/report', 
      method: 'POST', 
      body: reportData, 
      imageFile: imageFile,
    );
  }
}