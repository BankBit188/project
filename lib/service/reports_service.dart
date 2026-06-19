import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // อย่าลืมเช็กแพ็กเกจนี้ (มาพร้อมกับ http อยู่แล้ว)

class ReportsService {
  // 🔹 ใช้ URL ของ Ngrok ตามแบบฉบับโครงสร้างเดิมที่จำไว้
  static const String baseUrl = 'https://uselessly-disclose-stingray.ngrok-free.dev/api';

  // ฟังก์ชันส่วนกลางสำหรับดึงหรือส่งข้อมูล API (ปรับปรุงให้รองรับ Multipart เพื่ออัปโหลดรูป R. นามสกุล)
  static Future<dynamic> _fetchAPI(
    String endpoint, {
    String method = 'GET', 
    Map<String, String>? body, // ปรับเป็น String สำหรับส่งคู่ไปกับ Form-Data
    File? imageFile, // แนบไฟล์รูปภาพเสริมเข้าสู่ระบบ
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    
    try {
      // 🟩 กรณีที่ 1: มีการส่งไฟล์รูปภาพ หรือส่งผ่าน POST แบบอัปโหลดรูป
      if (method == 'POST' && imageFile != null) {
        final request = http.MultipartRequest('POST', url);
        
        // ใส่ Headers ตัว Accept ไว้รับ Response สไตล์ JSON
        request.headers['Accept'] = 'application/json';

        // แนบข้อมูล Text ปกติ (ถ้ามี)
        if (body != null) {
          request.fields.addAll(body);
        }

        // แนบไฟล์รูปภาพเข้าสู่ Key ชื่อ 'img' ให้ตรงกับ Laravel Controller
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();
        final multipartFile = http.MultipartFile(
          'img',
          stream,
          length,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'), // สามารถเปลี่ยนประเภทได้ตามนามสกุลไฟล์
        );
        request.files.add(multipartFile);

        // ส่งข้อมูลแบบ Multipart ไปที่หลังบ้าน
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        return _handleResponse(response);
      } 
      
      // 🟩 กรณีที่ 2: เป็นการดึงข้อมูล GET หรือ POST แบบ JSON ธรรมดา
      else {
        final headers = {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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

  // ฟังก์ชันแยกจัดการ Response เพื่อความเป็นระเบียบ
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'HTTP error! status: ${response.statusCode}');
    }
  }

  // --------------------------------------------------------------
  // 🔹 1. ฟังก์ชันดึงข้อมูลรายงานทั้งหมด (GET /reports)
  static Future<dynamic> getReports() async {
    return await _fetchAPI('/report', method: 'GET');
  }

  // 🔹 2. ฟังก์ชันดึงข้อมูลรายงานระบุเจาะจงราย ID (GET /reports/{id})
  static Future<dynamic> getReportById(String reportId) async {
    return await _fetchAPI('/report/$reportId', method: 'GET');
  }

  // 🔹 3. ฟังก์ชันเพิ่มข้อมูลรายงานใหม่พร้อมไฟล์รูปภาพ (POST /reports)
  static Future<dynamic> createReport({
    required Map<String, String> reportData, // ข้อมูล text เช่น title, description, details
    File? imageFile, // ใส่ไฟล์รูปภาพที่ได้มาจาก ImagePicker ของ Flutter
  }) async {
    return await _fetchAPI(
      '/report', 
      method: 'POST', 
      body: reportData, 
      imageFile: imageFile,
    );
  }
}