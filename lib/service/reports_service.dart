import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class ReportsService {
  // 🔹 ใช้ URL ของ Ngrok ตามโครงสร้างเดิม
  static String baseUrl = dotenv.env['API_URL'] ?? '';

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
    Map<String, String>? extraHeaders, // 🟢 รองรับ Headerเพิ่มเติม
    XFile? imageFile,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      // 🔒 ตรวจสอบ Token ก่อนทำการยิง API
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception(
            'Unauthenticated: ไม่พบ Token ในระบบ กรุณาเข้าสู่ระบบใหม่');
      }

      // 🟩 กรณีที่ 1: มีการส่งไฟล์รูปภาพ หรือส่งผ่าน POST แบบอัปโหลดรูป
      if (method == 'POST' && imageFile != null) {
        final request = http.MultipartRequest('POST', url);

        // 🔒 ใส่ Headers รับ JSON และแนบ Bearer Token เข้าไปด้วย
        request.headers['Accept'] = 'application/json';
        request.headers['Authorization'] = 'Bearer $token';

        if (extraHeaders != null) {
          request.headers.addAll(extraHeaders);
        }

        // แนบข้อมูล Text ปกติ (ถ้ามี)
        if (body != null) {
          request.fields.addAll(body);
        }

        // อ่านไฟล์รูปภาพเป็น Bytes
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'img',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        return _handleResponse(response);
      }

      // 🟩 กรณีที่ 2: เป็นการดึงข้อมูล GET, POST หรือ PUT แบบ JSON ธรรมดา
      else {
        final headers = {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          ...?extraHeaders, // 🟢 รวม Header ที่ส่งเสริมเข้ามา (เช่น Userid)
        };

        http.Response response;
        if (method == 'POST') {
          response =
              await http.post(url, headers: headers, body: jsonEncode(body));
        } else if (method == 'PUT') {
          response =
              await http.put(url, headers: headers, body: jsonEncode(body));
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
      throw Exception('Unauthenticated: Token ไม่ถูกต้องหรือหมดอายุ (401)');
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'HTTP error! status: ${response.statusCode}');
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
    XFile? imageFile,
  }) async {
    return await _fetchAPI(
      '/report',
      method: 'POST',
      body: reportData,
      imageFile: imageFile,
    );
  }

  // 🟢 4. ฟังก์ชันอัปเดตสถานะ Feedback (PUT /report/{id})
  static Future<dynamic> updateFeedbackStatus({
    required String reportId,
    required String userId,
  }) async {
    return await _fetchAPI(
      '/reports/update-feedback-status',
      method: 'PUT',
      body: {
        'reportid': reportId,
        'Userid': userId,
      },
    );
  }

  // 🟢 5. ฟังก์ชันดึงจำนวนการตอบกลับที่ยังไม่ได้อ่าน (GET /reports/unread-feedback-count)
  static Future<int> getUnreadFeedbackCount() async {
    final userId = await _secureStorage.read(key: 'Userid');

    final response = await _fetchAPI(
      '/reports/unread-feedback-count',
      method: 'GET',
      extraHeaders: {
        if (userId != null) 'Userid': userId,
      },
    );

    if (response != null && response['unreadCount'] != null) {
      return int.tryParse(response['unreadCount'].toString()) ?? 0;
    }
    return 0;
  }
}