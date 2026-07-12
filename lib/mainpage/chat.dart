import 'package:flutter/material.dart';
import 'package:project/navbar/navbars.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// 🟢 อย่าลืมตรวจสอบว่าโปรเจกต์ของคุณติดตั้งและนำเข้าตัวนี้แล้วหรือยังนะครับ
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 

import 'package:project/service/user_service.dart'; // นำเข้า UserService เพื่อใช้ฟังก์ชัน login และอื่นๆ

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 🟢 1. ประกาศตัวแปรใช้งาน FlutterSecureStorage และตัวแปรเก็บ Token/UserID
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _authToken;
  String? _userId;

  List<Map<String, String>> messages = [];
  bool isLoading = false;
  
  final int maxDailyLimit = 10;
  int currentUsage = 0; // ค่านับใช้งานเริ่มต้น

  @override
  void initState() {
    super.initState();
    // 🟢 2. เรียกฟังก์ชันเตรียมโหลด Token และโควตาเริ่มต้น
    _initializeChat();
    
    messages.add({
      "role": "ai",
      "text": "สวัสดีครับ! ผมคือผู้ช่วย AI ด้านการเกษตร วันนี้มีอะไรให้ผมช่วยไหมครับ?"
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🟢 3. มัดรวมการดึง Token และไปดึงข้อมูลโควตาล่าสุดต่อจากเซิร์ฟเวอร์
  Future<void> _initializeChat() async {
    await _loadToken(); // ดึงค่าจาก Secure Storage
    if (_userId != null) {
      await _fetchInitialQuota(); // ส่ง User ID ไปเช็กโควตาเริ่มต้นที่หลังบ้าน
    }
  }

  // 🟩 ฟังก์ชันสำหรับดึง Token และ User ID ออกจากหน่วยความจำ (ตามที่คุณเขียนเป๊ะๆ)
  Future<void> _loadToken() async {
    String? token = await _secureStorage.read(key: "auth_token");
    String? userId = await _secureStorage.read(key: "user_id");
    if (!mounted) return;
    setState(() {
      _authToken = token;
      _userId = userId;
    });
    // เทสพิมพ์พ่นดูใน Debug Console ว่า ข้อมูลมาจริงไหม
    print("ระบบตรวจสอบพบ Token ปัจจุบัน: $_authToken, UserID: $_userId");
  }

  // 🟢 4. ฟังก์ชันดึงโควตารายวันปัจจุบันจากฝั่ง Laravel หลังบ้าน
  Future<void> _fetchInitialQuota() async {
    if (_userId == null) return;

    setState(() => isLoading = true);
    try {
      // 🟩 เรียกใช้งานผ่าน UserService ตามที่คุณกำหนด
      final data = await UserService.getUserById(_userId!, _authToken);

      if (data != null) {
        // ดึงค่าจากคีย์ 'chat_quota' ตรงๆ ตามโครงสร้าง JSON (ถ้าไม่มีค่าให้ default เป็น 10)
        int remainingQuota = data['chat_quota'] ?? 10;
        
        setState(() {
          // แปลงโควตาที่เหลือกลับมาเป็นค่านับสะสม (currentUsage) ให้ UI แบนเนอร์ทำงานถูกต้อง
          // ตัวอย่าง: ถ้าเหลือ 10 -> currentUsage จะได้ 10 - 10 = 0 (แปลว่าใช้ไปแล้ว 0 ครั้ง)
          currentUsage = maxDailyLimit - remainingQuota; 
        });
        
        print("ดึงข้อมูลผู้ใช้สำเร็จ! โควตาคงเหลือจริง: $remainingQuota ครั้ง (UI พ่นว่าใช้ไปแล้ว: $currentUsage)");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูลโควตา: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🟢 5. ฟังก์ชันส่งข้อความ ปรับมาเช็กเงื่อนไขกับ _userId และแนบค่าส่งไปหลังบ้าน
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // เช็กโควตาเบื้องต้นจากหน้าจอแอปก่อน
    if (currentUsage >= maxDailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("คุณใช้งานโควตาคำถามของวันนี้หมดแล้ว กรุณากลับมาใหม่พรุ่งนี้ครับ")),
      );
      return;
    }

    // ป้องกันกรณีที่อ่าน Secure Storage แล้วไม่เจอ ID
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบรหัสผู้ใช้งาน กรุณาล็อกอินใหม่อีกครั้ง")),
      );
      return;
    }

    _controller.clear();
    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });
    _scrollToBottom();

    try {
      final url = Uri.parse('https://uselessly-disclose-stingray.ngrok-free.dev/api/chat');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken', // 🔒 ส่ง Token ยืนยันสิทธิ์กับ Laravel
        },
        body: jsonEncode({
          'message': text,
          'user_id': _userId // 🟩 ส่ง ID ที่ดึงมาจาก Secure Storage ไปให้หลังบ้านเช็กหักโควตา
        }),
      );

      // กรณีที่หลังบ้านตอบกลับว่าโควตาหมดจริง (Status 403)
      if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add({"role": "ai", "text": data['reply'] ?? 'โควตารายวันของคุณหมดแล้ว'});
          currentUsage = maxDailyLimit; // ล็อก UI ทันที
          isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // กรณีคุยผ่านสำเร็จและตัดโควตาแล้ว (Status 200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int remainingQuota = data['remaining_quota'] ?? 0;

        setState(() {
          messages.add({"role": "ai", "text": data['reply'] ?? 'ไม่มีการตอบกลับ'});
          currentUsage = maxDailyLimit - remainingQuota; // ปรับโควตาที่เหลือโชว์บนแบนเนอร์
          isLoading = false;
        });
      } else {
        throw Exception("Server Error : ${response.statusCode}");
      }

    } catch (e) {
      setState(() {
        messages.add({"role": "ai", "text": "ขออภัยครับ ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ในขณะนี้ ($e)"});
        isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🟩 ส่วน UI โครงสร้างความสวยงามคงเดิมทุกประการ ไม่จำเป็นต้องแก้โค้ดด้านล่างนี้ครับ
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDCEAF1), Color(0xFFD2E0C4)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("แชตบอต", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: currentUsage >= maxDailyLimit ? Colors.red.shade100 : Colors.green.shade200,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: currentUsage >= maxDailyLimit ? Colors.red : Colors.green.shade800,
                        ),
                      ),
                      child: Text(
                        "โควตา: $currentUsage / $maxDailyLimit",
                        style: TextStyle(
                          color: currentUsage >= maxDailyLimit ? Colors.red.shade800 : Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EBB8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black87),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isUser = msg["role"] == "user";
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.7,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF915C22) : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              border: isUser ? null : Border.all(color: Colors.grey.shade400),
                            ),
                            child: Text(
                              msg["text"]!,
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF915C22)),
                    ),
                  ),
                Row(
                  children: [
                    const Icon(Icons.person, size: 40, color: Color(0xFF915C22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFF424242),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            hintText: currentUsage >= maxDailyLimit ? "โควตาหมดแล้ว" : "พิมพ์ข้อความ...",
                            hintStyle: const TextStyle(color: Colors.white54),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: currentUsage < maxDailyLimit && !isLoading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: (currentUsage >= maxDailyLimit || isLoading) ? null : _sendMessage,
                      child: Icon(
                        Icons.send, 
                        size: 35, 
                        color: (currentUsage >= maxDailyLimit || isLoading) ? Colors.grey : const Color(0xFF915C22)
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AuthNavBar(currentIndex: 3),
    );
  }
}