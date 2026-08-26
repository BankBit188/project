import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ToolService {
  static String baseUrl = dotenv.env['API_URL'] ?? '';
  static const _secureStorage = FlutterSecureStorage();

  static Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  static Future<dynamic> _fetchAPI(
    String endpoint, {
    String method = 'GET', 
    Map<String, dynamic>? body,
    String? token, 
  }) async {
    final url = Uri.parse('$baseUrl$endpoint'); 
    
    try {
      final authToken = token ?? await _getToken();

      if (authToken == null || authToken.isEmpty) {
        throw Exception('Unauthenticated: ไม่พบ Token ในระบบ');
      }

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $authToken', 
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
        throw Exception('401 Unauthorized: Token ไม่ถูกต้องหรือหมดอายุ');
      } else {
        // 🟢 ป้องกัน crash กรณี Server ตอบกลับมาเป็น HTML ( Error 500/502 )
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'HTTP Error: ${response.statusCode}');
        } catch (_) {
          throw Exception('HTTP Error: ${response.statusCode}');
        }
      }
    } catch (e) {
      // 🟢 ใช้ rethrow เพื่อส่ง Exception ดั้งเดิมออกไป โดยไม่ซ้อนคำว่า Exception เพิ่ม
      rethrow;
    }
  }

  static Future<dynamic> gettoolbyuser(String id, [String? token]) async {
    return await _fetchAPI('/tool/byuser/$id', method: 'GET', token: token);
  }

  static Future<dynamic> createhistory({
    required String userId,
    required String title,
    required String province,
    required String district,
    required String Amphur,
    required String region,
    Map<String, dynamic>? toolData,
    String? token,
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

    return await _fetchAPI('/history/create', method: 'POST', body: requestBody, token: token);
  }
  
  static Future<dynamic> gethistorybyuser(String userId, [String? token]) async {
    return await _fetchAPI('/history/user/$userId', method: 'GET', token: token);
  }
}