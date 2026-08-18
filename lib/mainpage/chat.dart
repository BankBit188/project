import 'package:flutter/material.dart';
import 'package:project/navbar/navbars.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/service/user_service.dart';
import 'package:project/style/style_chat.dart'; // 🟢 Import ไฟล์ส่วนตกแต่ง UI

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _authToken;
  String? _userId;

  List<Map<String, String>> messages = [];
  bool isLoading = false;

  final int maxDailyLimit = 10;
  int currentUsage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeChat();

    messages.add({
      "role": "ai",
      "text":
          "สวัสดีครับ! ผมคือผู้ช่วย AI ด้านการเกษตร วันนี้มีอะไรให้ผมช่วยไหมครับ?",
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔒 1. ตรวจสอบทั้ง Token และ UserID ก่อนเริ่มต้นโหลดข้อมูล
  Future<void> _initializeChat() async {
    await _loadToken();
    if (_authToken != null && _authToken!.isNotEmpty && _userId != null) {
      await _fetchInitialQuota();
      await _fetchChatHistory();
    } else {
      _showAuthErrorSnackBar("ไม่พบ Token หรือรหัสผู้ใช้ กรุณาเข้าสู่ระบบใหม่");
    }
  }

  // 🔒 2. ฟังก์ชันดึงประวัติแชต
  Future<void> _fetchChatHistory() async {
    if (_authToken == null || _authToken!.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final url = Uri.parse(
        'https://api-project-production-0935.up.railway.app/api/chat/history',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({'Userid': _userId}),
      );

      print("โหลดประวัติแชตจากเซิร์ฟเวอร์ ID ที่ส่งไปคือ: $_userId");

      if (response.statusCode == 200) {
        final List<dynamic> historyData = jsonDecode(response.body);

        setState(() {
          messages.clear();

          messages.add({
            "role": "ai",
            "text":
                "สวัสดีครับ! ผมคือผู้ช่วย AI ด้านการเกษตร วันนี้มีอะไรให้ผมช่วยไหมครับ?",
          });

          if (historyData.isNotEmpty) {
            for (var msg in historyData) {
              messages.add({
                "role": msg['role'].toString(),
                "text": msg['text'].toString(),
              });
            }
          }
        });

        _scrollToBottom();
      } else if (response.statusCode == 401) {
        print("Log Error 401 (ประวัติแชต): Token ไม่ถูกต้องหรือหมดอายุ");
        _showAuthErrorSnackBar("Token หมดอายุหรือไม่มีสิทธิ์ กรุณาเข้าสู่ระบบใหม่");
      } else {
        print("Log Error ${response.statusCode} (ประวัติแชต): ${response.body}");
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการโหลดประวัติแชต: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🟩 ฟังก์ชันสำหรับดึง Token และ User ID ออกจาก Secure Storage
  Future<void> _loadToken() async {
    String? token = await _secureStorage.read(key: "auth_token");
    String? userId = await _secureStorage.read(key: "Userid");
    if (!mounted) return;
    setState(() {
      _authToken = token;
      _userId = userId;
    });
    print("ระบบตรวจสอบพบ Token ปัจจุบัน: $_authToken, UserID: $_userId");
  }

  // 🔒 3. ฟังก์ชันดึงโควตาประจำวัน
  Future<void> _fetchInitialQuota() async {
    if (_userId == null || _authToken == null) return;

    setState(() => isLoading = true);
    try {
      final data = await UserService.getUserById(_userId!, _authToken);

      if (data != null) {
        int remainingQuota = data['chat_quota'] ?? 10;

        setState(() {
          currentUsage = maxDailyLimit - remainingQuota;
        });

        print(
          "ดึงข้อมูลผู้ใช้สำเร็จ! โควตาคงเหลือจริง: $remainingQuota ครั้ง (UI พ่นว่าใช้ไปแล้ว: $currentUsage)",
        );
      }
    } catch (e) {
      print("เกิดข้อผิดพลาดในการดึงข้อมูลโควตา: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔒 4. ฟังก์ชันส่งข้อความ
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (currentUsage >= maxDailyLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "คุณใช้งานโควตาคำถามของวันนี้หมดแล้ว กรุณากลับมาใหม่พรุ่งนี้ครับ",
          ),
        ),
      );
      return;
    }

    if (_authToken == null || _authToken!.isEmpty || _userId == null) {
      _showAuthErrorSnackBar("ไม่พบ Token หรือรหัสผู้ใช้งาน กรุณาล็อกอินใหม่อีกครั้ง");
      return;
    }

    _controller.clear();
    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });
    _scrollToBottom();

    try {
      final url = Uri.parse(
        'https://api-project-production-0935.up.railway.app/api/chat',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
        body: jsonEncode({
          'message': text,
          'Userid': _userId,
        }),
      ).timeout(const Duration(seconds: 120));

      print("ส่งข้อความไปหลังบ้านพร้อม UserID: $_userId, ข้อความ: $text");

      if (response.statusCode == 401) {
        setState(() {
          messages.add({
            "role": "ai",
            "text": "เซสชันของคุณหมดอายุแล้ว กรุณาเข้าสู่ระบบใหม่อีกครั้ง",
          });
          isLoading = false;
        });
        _showAuthErrorSnackBar("Token หมดอายุ กรุณาเข้าสู่ระบบใหม่");
        _scrollToBottom();
        return;
      }

      if (response.statusCode == 403) {
        final data = jsonDecode(response.body);
        setState(() {
          messages.add({
            "role": "ai",
            "text": data['reply'] ?? 'โควตารายวันของคุณหมดแล้ว',
          });
          currentUsage = maxDailyLimit;
          isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        int remainingQuota = data['remaining_quota'] ?? 0;

        setState(() {
          messages.add({
            "role": "ai",
            "text": data['reply'] ?? 'ไม่มีการตอบกลับ',
          });
          currentUsage = maxDailyLimit - remainingQuota;
          isLoading = false;
        });
      } else {
        print("Log Error ${response.statusCode} (ส่งข้อความ): ${response.body}");
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['reply'] ?? 'Server Error : ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        messages.add({
          "role": "ai",
          "text": "ขออภัยครับ ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้ในขณะนี้ ($e)",
        });
        isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _showAuthErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
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
    super.build(context);
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 1. Header Widget
                ChatHeaderWidget(
                  currentUsage: currentUsage,
                  maxDailyLimit: maxDailyLimit,
                ),

                const SizedBox(height: 15),

                // 🟢 2. Chat Window Container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2EDB4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length && isLoading) {
                          return const ChatLoadingWidget();
                        }
                        final msg = messages[index];
                        final isUser = msg["role"] == "user";

                        return ChatMessageBubble(
                          text: msg["text"] ?? "",
                          isUser: isUser,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 🟢 3. Input Bar Widget
                ChatInputBarWidget(
                  controller: _controller,
                  isDisabled: currentUsage >= maxDailyLimit,
                  isLoading: isLoading,
                  onSend: _sendMessage,
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