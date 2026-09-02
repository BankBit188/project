import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:project/navbar/navbars.dart';
import 'package:project/mainpage/history.dart';
import 'package:project/mainpage/menu.dart';
import 'package:project/mainpage/profile.dart';
import 'package:project/mainpage/followreport.dart';

//import service
import 'package:project/service/reports_service.dart';
import 'package:project/service/tool_service.dart';

import 'package:project/modal/tool_save_location_dialog.dart';
import 'package:project/modal/tool_report_dialog.dart';
import 'package:project/modal/plant_select_recommention.dart';

import 'package:project/style/style_tool.dart';

// 🟢 Import LoginPage เข้ามาใช้งาน
import 'package:project/login/login.dart';

class ToolPage extends StatefulWidget {
  const ToolPage({super.key});

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _authToken;
  String? _userId;

  Map<String, dynamic>? _toolData;
  bool _isLoadingTool = false;

  // 🟢 ตัวแปรเก็บจำนวนข้อความแจ้งเตือนที่ยังไม่ได้อ่าน
  int _unreadFeedbackCount = 0;

  String _currentDateTimeString = "";
  List<dynamic> _thailandData = [];

  // 🟢 ปรับปรุงตรรกะเช็คสถานะออฟไลน์ให้ครอบคลุมและแม่นยำขึ้น
  bool get _isOffline {
    if (_toolData == null) return true;

    final createdAtStr =
        _toolData!['created_at']?.toString() ??
        _toolData!['createdAt']?.toString();

    if (createdAtStr == null || createdAtStr.trim().isEmpty) return true;

    try {
      DateTime? createdAt = DateTime.tryParse(createdAtStr);

      if (createdAt == null) {
        String formattedStr = createdAtStr.trim().replaceAll(' ', 'T');
        if (!formattedStr.contains('Z') &&
            !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(formattedStr)) {
          formattedStr += 'Z';
        }
        createdAt = DateTime.tryParse(formattedStr);
      }

      if (createdAt == null) return true;

      final nowUtc = DateTime.now().toUtc();
      final diffInSeconds =
          nowUtc.difference(createdAt.toUtc()).inSeconds.abs();

      debugPrint(
        "🕒 เวลา DB (UTC): ${createdAt.toUtc()} | เวลาเครื่อง (UTC): $nowUtc | ต่างกัน: $diffInSeconds วินาที",
      );

      return diffInSeconds >= 60;
    } catch (e) {
      debugPrint("❌ Parse Timestamp Failure ($createdAtStr): $e");
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    _initThaiDateTime();
    _loadToken();
    _loadAddressData();
  }

  Future<void> _loadAddressData() async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/data/thailand_data.json',
      );
      if (!mounted) return;
      setState(() {
        _thailandData = jsonDecode(jsonString);
      });
    } catch (e) {
      debugPrint("Error loading JSON: $e");
    }
  }

  void _initThaiDateTime() {
    initializeDateFormatting('th', null).then((_) {
      final now = DateTime.now();
      final dateNew = DateFormat('d MMMM', 'th').format(now);
      final thaiYear = now.year + 543;
      final timeNew = DateFormat('HH.mm').format(now);

      if (!mounted) return;
      setState(() {
        _currentDateTimeString = "$dateNew $thaiYear   $timeNew";
      });
    });
  }

  Future<void> _loadToken() async {
    String? token = await _secureStorage.read(key: "auth_token");
    String? userId = await _secureStorage.read(key: "Userid");

    if (!mounted) return;

    if (token == null || userId == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    setState(() {
      _authToken = token;
      _userId = userId;
    });

    _fetchToolData();
    _fetchUnreadFeedbackCount();
  }

  Future<void> _fetchUnreadFeedbackCount() async {
    try {
      final count = await ReportsService.getUnreadFeedbackCount();
      if (mounted) {
        setState(() {
          _unreadFeedbackCount = count;
        });
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  Future<void> _fetchToolData() async {
    if (!mounted) return;
    setState(() => _isLoadingTool = true);
    try {
      final response = await ToolService.gettoolbyuser(_userId!, _authToken!);
      if (mounted) {
        setState(() {
          if (response != null && response['status'] == 'success') {
            _toolData = response['data'];
          } else if (response != null &&
              (response['statusCode'] == 401 ||
                  response['message']?.contains('expired') == true)) {
            _handleTokenExpired();
          }
          _isLoadingTool = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTool = false);
    }
  }

  Future<void> _handleTokenExpired() async {
    await _secureStorage.delete(key: "auth_token");
    await _secureStorage.delete(key: "Userid");
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่")),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _recommendPlants() async {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("อุปกรณ์ออฟไลน์อยู่")),
      );
      return;
    }

    if (_toolData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ยังไม่มีข้อมูลสภาพดิน กรุณารอโหลดข้อมูลสักครู่"),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => PlantSelectRecommendationDialog(
        toolData: _toolData,
      ),
    );
  }

  void _showSaveLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SaveLocationDialog(
        userId: _userId,
        authToken: _authToken,
        toolData: _toolData,
        thailandData: _thailandData,
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ReportDialog(userId: _userId),
    );
  }

  Future<void> _showTopMenu(BuildContext buttonContext) async {
    final String? value = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 55,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 210,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EFE6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 20,
                          spreadRadius: 1,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMenuItem(
                              dialogContext,
                              'profile',
                              'โปรไฟล์',
                              Icons.person_outline_rounded,
                            ),
                            const Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: Colors.black12,
                            ),
                            _buildMenuItem(
                              dialogContext,
                              'history',
                              'ประวัติการบันทึก',
                              Icons.history_rounded,
                            ),
                            const Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: Colors.black12,
                            ),
                            _buildMenuItem(
                              dialogContext,
                              'report',
                              'รายงานปัญหา',
                              Icons.report_problem_outlined,
                            ),
                            const Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: Colors.black12,
                            ),
                            _buildMenuItem(
                              dialogContext,
                              'follow_report',
                              'ติดตามปัญหา',
                              Icons.assignment_outlined,
                              badgeCount: _unreadFeedbackCount,
                            ),
                            const Divider(
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                              color: Colors.black12,
                            ),
                            _buildMenuItem(
                              dialogContext,
                              'logout',
                              'ออกจากระบบ',
                              Icons.logout_rounded,
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (value != null && mounted) {
      _handleMenuSelection(value);
    }
  }

  Widget _buildMenuItem(
    BuildContext dialogContext,
    String value,
    String text,
    IconData icon, {
    bool isDestructive = false,
    int badgeCount = 0,
  }) {
    final color = isDestructive ? Colors.red.shade700 : const Color(0xFF212522);
    return InkWell(
      onTap: () => Navigator.pop(dialogContext, value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == 'profile') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else if (value == 'report') {
      _showReportDialog(context);
    } else if (value == 'follow_report') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FollowReportPage()),
      );
      if (mounted) _fetchUnreadFeedbackCount();
    } else if (value == 'history') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HistoryPage()),
      );
    } else if (value == 'logout') {
      await _secureStorage.delete(key: "auth_token");
      await _secureStorage.delete(key: "Userid");

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MenuPage(isLoggedIn: false),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: ToolTheme.pageDecoration,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "อุปกรณ์",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF212522),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            ToolStatusBadge(isOffline: _isOffline),
                            const SizedBox(width: 4),
                            _isLoadingTool
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF4A7C59),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      Icons.refresh,
                                      size: 26,
                                      color: Color(0xFF212522),
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      _fetchToolData();
                                      _fetchUnreadFeedbackCount();
                                      _initThaiDateTime();
                                    },
                                  ),
                          ],
                        ),
                      ),
                      Builder(
                        builder: (menuContext) {
                          return IconButton(
                            icon: const Icon(
                              Icons.menu,
                              size: 35,
                              color: Color(0xFF212522),
                            ),
                            onPressed: () => _showTopMenu(menuContext),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentDateTimeString.isNotEmpty
                              ? _currentDateTimeString
                              : "กำลังโหลดเวลา...",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "(หน่วย: mg/kg)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Expanded(
                        child: NutrientCardTile(
                          label: "N",
                          value: _isOffline
                              ? "-"
                              : (_toolData?['N']?.toString() ?? "-"),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: NutrientCardTile(
                          label: "P",
                          value: _isOffline
                              ? "-"
                              : (_toolData?['P']?.toString() ?? "-"),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: NutrientCardTile(
                          label: "K",
                          value: _isOffline
                              ? "-"
                              : (_toolData?['K']?.toString() ?? "-"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: NutrientCardTile(
                          label: "Ca",
                          value: _isOffline
                              ? "-"
                              : (_toolData?['Ca']?.toString() ?? "-"),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: NutrientCardTile(
                          label: "Mg",
                          value: _isOffline
                              ? "-"
                              : (_toolData?['Mg']?.toString() ?? "-"),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: NutrientCardTile(
                          label: "S",
                          value: _isOffline
                              ? "-"
                              : (_toolData?['S']?.toString() ?? "-"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  EnvironmentMetricTile(
                    icon: Icons.water_drop_rounded,
                    label: "ความชื้น",
                    value: _isOffline
                        ? "-"
                        : (_toolData?['humid'] != null
                              ? "${_toolData!['humid']} %"
                              : "-"),
                    iconColor: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 10),
                  EnvironmentMetricTile(
                    icon: Icons.science_rounded,
                    label: "ค่า pH",
                    value: _isOffline
                        ? "-"
                        : (_toolData != null
                              ? "${_toolData!['PH'] ?? _toolData!['ph'] ?? '-'}"
                              : "-"),
                    iconColor: Colors.purple.shade600,
                  ),
                  const SizedBox(height: 10),
                  EnvironmentMetricTile(
                    icon: Icons.thermostat_rounded,
                    label: "อุณหภูมิ",
                    value: _isOffline
                        ? "-"
                        : (_toolData?['temperature'] != null
                              ? "${_toolData!['temperature']} C°"
                              : "-"),
                    iconColor: Colors.orange.shade700,
                  ),
                  const SizedBox(height: 10),
                  EnvironmentMetricTile(
                    icon: Icons.waves_rounded,
                    label: "ความเค็ม",
                    value: _isOffline
                        ? "-"
                        : (_toolData?['salty'] != null
                              ? "${_toolData!['salty']} us/cm"
                              : "-"),
                    iconColor: Colors.teal.shade700,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ToolActionButton(
                          text: "บันทึกข้อมูล",
                          icon: Icons.bookmark_add_rounded,
                          onTap: () {
                            if (_isOffline) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("อุปกรณ์ออฟไลน์อยู่"),
                                ),
                              );
                              return;
                            }
                            _showSaveLocationDialog(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ToolActionButton(
                          text: "พืชปลูกที่เหมาะสม",
                          icon: Icons.eco_rounded,
                          onTap: _recommendPlants,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AuthNavBar(currentIndex: 4),
    );
  }
}