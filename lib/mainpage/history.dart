import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/service/tool_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _historyList = []; // ข้อมูลทั้งหมดจาก API
  List<dynamic> _filteredList = []; // ข้อมูลหลังผ่านการกรองคำค้นหา
  List<dynamic> _displayedList = []; // ข้อมูลที่จะแสดงในหน้าปัจจุบัน (5 รายการ)

  bool _isLoading = true;
  String? _errorMessage;

  // 🔹 ตัวแปรสำหรับ Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🔹 คำนวณหน้าทั้งหมดและอัปเดตข้อมูลที่จะแสดงผล
  void _updateDisplayedItems() {
    setState(() {
      _lastPage = (_filteredList.isEmpty)
          ? 1
          : (_filteredList.length / _itemsPerPage).ceil();

      if (_currentPage > _lastPage) {
        _currentPage = _lastPage;
      }
      if (_currentPage < 1) {
        _currentPage = 1;
      }

      int startIndex = (_currentPage - 1) * _itemsPerPage;
      int endIndex = min(startIndex + _itemsPerPage, _filteredList.length);

      if (_filteredList.isEmpty || startIndex >= _filteredList.length) {
        _displayedList = [];
      } else {
        _displayedList = _filteredList.sublist(startIndex, endIndex);
      }
    });
  }

  // 🔹 1. ดึงข้อมูลประวัติจาก API
  Future<void> _fetchHistoryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? token = await _secureStorage.read(key: "auth_token");
      String? userId = await _secureStorage.read(key: "Userid");

      if (token == null || userId == null) {
        throw Exception("ไม่พบ Token หรือ Userid ใน Secure Storage");
      }

      final response = await ToolService.gethistorybyuser(userId, token);

      List<dynamic> fetchedData = [];
      if (response is List) {
        fetchedData = response;
      } else if (response is Map && response.containsKey('data')) {
        fetchedData = response['data'] ?? [];
      }

      _historyList = fetchedData;
      _filteredList = fetchedData;
      _currentPage = 1;
      _updateDisplayedItems();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // 🔹 2. ฟังก์ชันกรองข้อมูลตามคำค้นหา
  void _filterHistory(String query) {
    if (query.isEmpty) {
      _filteredList = _historyList;
    } else {
      final searchLower = query.toLowerCase();
      _filteredList = _historyList.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        return title.contains(searchLower);
      }).toList();
    }
    _currentPage = 1;
    _updateDisplayedItems();
  }

  // 🔹 3. แปลงวันที่และเวลาเป็น Timezone ไทย (UTC+7)
  String _formatDateTime(dynamic dateTimeVal) {
    if (dateTimeVal == null || dateTimeVal.toString().isEmpty) return "-";

    try {
      DateTime dt;
      String valStr = dateTimeVal.toString().trim();

      if (RegExp(r'^\d+$').hasMatch(valStr)) {
        int timestamp = int.parse(valStr);
        if (valStr.length == 10) {
          timestamp *= 1000;
        }
        dt = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true)
            .add(const Duration(hours: 7));
      } else {
        DateTime parsed = DateTime.parse(valStr);
        if (!parsed.isUtc && !valStr.contains('Z') && !valStr.contains('+')) {
          dt = DateTime.parse("${valStr.replaceAll(' ', 'T')}Z")
              .toUtc()
              .add(const Duration(hours: 7));
        } else {
          dt = parsed.toUtc().add(const Duration(hours: 7));
        }
      }

      List<String> thaiMonths = [
        "มกราคม", "กุมภาพันธ์", "มีนาคม", "เมษายน", "พฤษภาคม", "มิถุนายน",
        "กรกฎาคม", "สิงหาคม", "กันยายน", "ตุลาคม", "พฤศจิกายน", "ธันวาคม",
      ];

      int thaiYear = dt.year + 543;
      String hour = dt.hour.toString().padLeft(2, '0');
      String minute = dt.minute.toString().padLeft(2, '0');

      return "${dt.day} ${thaiMonths[dt.month - 1]} $thaiYear $hour.$minute";
    } catch (_) {
      return dateTimeVal.toString();
    }
  }

  // 🔹 4. ฟังก์ชันเปิด Modal แสดงข้อมูลแบบเต็ม
  void _showDetailModal(Map<String, dynamic> item) {
    final String gardenName = item['title'] ?? 'ไม่ระบุชื่อ';
    final String dateTimeStr = _formatDateTime(item['created_at']);

    final n = item['N'] ?? 0;
    final p = item['P'] ?? 0;
    final k = item['K'] ?? 0;
    final ca = item['Ca'] ?? 0;
    final mg = item['Mg'] ?? 0;
    final s = item['S'] ?? 0;
    final humid = item['humid'] ?? 0;
    final salty = item['salty'] ?? 0;
    final temp = item['temperature'] ?? 0;
    final ph = item['PH'] ?? 0;

    final province = item['province'] ?? '-';
    final amphur = item['Amphur'] ?? '-';
    final district = item['district'] ?? '-';
    final region = item['Region'] ?? '-';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          backgroundColor: const Color(0xFFF9F3D5),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F3D5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black87, width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          gardenName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 28, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.history, size: 24, color: Colors.black),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateTimeStr,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text.rich(TextSpan(children: [const TextSpan(text: "N: ", style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "$n")]), style: const TextStyle(fontSize: 17)),
                      Text.rich(TextSpan(children: [const TextSpan(text: "P: ", style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "$p")]), style: const TextStyle(fontSize: 17)),
                      Text.rich(TextSpan(children: [const TextSpan(text: "K: ", style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "$k")]), style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text.rich(TextSpan(children: [const TextSpan(text: "Ca: ", style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "$ca")]), style: const TextStyle(fontSize: 17)),
                      Text.rich(TextSpan(children: [const TextSpan(text: "Mg: ", style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "$mg")]), style: const TextStyle(fontSize: 17)),
                      Text.rich(TextSpan(children: [const TextSpan(text: "S: ", style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: "$s")]), style: const TextStyle(fontSize: 17)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.water_drop, color: Color(0xFF62B4E6), size: 28),
                      const SizedBox(width: 10),
                      Text("ความชื้น : $humid %", style: const TextStyle(fontSize: 17, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.science, color: Colors.purple, size: 28),
                      const SizedBox(width: 10),
                      Text.rich(TextSpan(children: [const TextSpan(text: "pH ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), TextSpan(text: ": $ph", style: const TextStyle(fontSize: 17))])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.thermostat, color: Colors.black, size: 28),
                      const SizedBox(width: 10),
                      Text("อุณหภูมิ : $temp C°", style: const TextStyle(fontSize: 17, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.opacity, color: Colors.black54, size: 28),
                      const SizedBox(width: 10),
                      Text("ความเค็ม : $salty mS/cm", style: const TextStyle(fontSize: 17, color: Colors.black)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("สถานที่", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ภาค: $region", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("ตำบล: $district", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("อำเภอ: $amphur", style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text("จังหวัด: $province", style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🔹 5. ฟังก์ชัน Pagination Widget จากผู้ใช้
  Widget _buildDynamicPagination() {
    if (_lastPage <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    pageButtons.add(
      _buildPageBtn(
        "<",
        disabled: _currentPage == 1,
        onTap: () {
          if (_currentPage > 1) {
            _currentPage--;
            _updateDisplayedItems();
          }
        },
      ),
    );

    bool showLeftDots = false;
    bool showRightDots = false;

    for (int i = 1; i <= _lastPage; i++) {
      if (i == 1 || i == _lastPage || (i - _currentPage).abs() <= 1) {
        pageButtons.add(
          _buildPageBtn(
            i.toString(),
            isActive: _currentPage == i,
            onTap: () {
              if (_currentPage != i) {
                _currentPage = i;
                _updateDisplayedItems();
              }
            },
          ),
        );
      } else if (i < _currentPage && !showLeftDots) {
        showLeftDots = true;
        pageButtons.add(_buildDotsBtn());
      } else if (i > _currentPage && !showRightDots) {
        showRightDots = true;
        pageButtons.add(_buildDotsBtn());
      }
    }

    pageButtons.add(
      _buildPageBtn(
        ">",
        disabled: _currentPage == _lastPage,
        onTap: () {
          if (_currentPage < _lastPage) {
            _currentPage++;
            _updateDisplayedItems();
          }
        },
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pageButtons,
    );
  }

  Widget _buildDotsBtn() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 32,
      height: 32,
      child: const Center(
        child: Text(
          "...",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPageBtn(
    String text, {
    bool isActive = false,
    bool disabled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF5A45FF)
              : (disabled ? Colors.grey.shade300 : Colors.white),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (disabled ? Colors.grey : Colors.black),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. ปุ่ม ย้อนกลับ (assets/images/backpage.png)
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Image.asset(
                        'assets/images/backpage.png',
                        width: 35,
                        height: 35,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Text(
                      "ประวัติการบันทึก",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // 2. ช่องค้นหา
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEBEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterHistory,
                    decoration: InputDecoration(
                      hintText: "ค้นหา เช่น ชื่อสวน",
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(left: 15, top: 10),
                      suffixIcon: const Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. รายการประวัติ
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _fetchHistoryData,
                                    child: const Text("ลองใหม่อีกครั้ง"),
                                  ),
                                ],
                              ),
                            )
                          : _displayedList.isEmpty
                              ? const Center(
                                  child: Text(
                                    "ไม่พบประวัติการบันทึกข้อมูล",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _fetchHistoryData,
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _displayedList.length,
                                    itemBuilder: (context, index) {
                                      final item = _displayedList[index];
                                      return _buildHistoryCard(item);
                                    },
                                  ),
                                ),
                ),

                // 4. แถบ Pagination
                if (!_isLoading && _errorMessage == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: _buildDynamicPagination(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 6. ฟังก์ชันสร้างการ์ดพรีวิวแบบย่อ
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final String gardenName = item['title'] ?? 'ไม่ระบุชื่อ';
    final String dateTimeStr = _formatDateTime(item['created_at']);

    final n = item['N'] ?? 0;
    final p = item['P'] ?? 0;
    final k = item['K'] ?? 0;

    return InkWell(
      onTap: () => _showDetailModal(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black87, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    gardenName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateTimeStr,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "ไนโตรเจน ( N ) : $n ฟอสฟอรัส ( P ) : $p",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              "โพแทสเซียม ( K ) : $k ......",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}