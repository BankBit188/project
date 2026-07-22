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
  bool _isLoading = true;
  String? _errorMessage;

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

      setState(() {
        _historyList = fetchedData;
        _filteredList = fetchedData;
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
      setState(() {
        _filteredList = _historyList;
      });
    } else {
      final searchLower = query.toLowerCase();
      setState(() {
        _filteredList = _historyList.where((item) {
          final title = (item['title'] ?? '').toString().toLowerCase();
          final province = (item['province'] ?? '').toString().toLowerCase();
          final amphur = (item['Amphur'] ?? '').toString().toLowerCase();
          final district = (item['district'] ?? '').toString().toLowerCase();

          return title.contains(searchLower) ||
              province.contains(searchLower) ||
              amphur.contains(searchLower) ||
              district.contains(searchLower);
        }).toList();
      });
    }
  }

  // 🔹 3. แปลงวันที่ (ปรับให้เป็นชื่อเดือนเต็มแบบรูปที่ 1 และ 2 เช่น 15มกราคม)
  String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      List<String> thaiMonths = [
        "มกราคม",
        "กุมภาพันธ์",
        "มีนาคม",
        "เมษายน",
        "พฤษภาคม",
        "มิถุนายน",
        "กรกฎาคม",
        "สิงหาคม",
        "กันยายน",
        "ตุลาคม",
        "พฤศจิกายน",
        "ธันวาคม",
      ];
      return "${dt.day}${thaiMonths[dt.month - 1]}";
    } catch (_) {
      return dateTimeStr;
    }
  }

  // 🔹 4. แปลงเวลา (เช่น 12.00)
  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return "-";
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      String hour = dt.hour.toString().padLeft(2, '0');
      String minute = dt.minute.toString().padLeft(2, '0');
      return "$hour.$minute";
    } catch (_) {
      return dateTimeStr;
    }
  }

  // 🔹 5. ฟังก์ชันเปิด Modal แสดงข้อมูลแบบเต็ม (ตามรูปที่ 2)
  // 🔹 5. ฟังก์ชันเปิด Modal แสดงข้อมูลแบบเต็ม (ปรับแก้ล้นขอบเรียบร้อย)
  void _showDetailModal(Map<String, dynamic> item) {
    final String gardenName = item['title'] ?? 'ไม่ระบุชื่อ';
    final String createdAt = item['created_at'] ?? '';
    final String dateStr = _formatDate(createdAt);
    final String timeStr = _formatTime(createdAt);

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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          // 🟢 1. ขยายขนาด Modal ให้กว้างขึ้นชิดขอบซ้าย-ขวามากขึ้น
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
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
                  // Head: ชื่อสวน + ปุ่มปิด X
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          gardenName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 28,
                          color: Colors.black,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // วันที่ และ เวลา
                  Row(
                    children: [
                      const Icon(Icons.history, size: 24, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(
                        "$dateStr    $timeStr",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // N P K
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "N: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: "$n"),
                          ],
                        ),
                        style: const TextStyle(fontSize: 17),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "P: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: "$p"),
                          ],
                        ),
                        style: const TextStyle(fontSize: 17),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "K: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: "$k"),
                          ],
                        ),
                        style: const TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ca Mg S
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Ca: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: "$ca"),
                          ],
                        ),
                        style: const TextStyle(fontSize: 17),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "Mg: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: "$mg"),
                          ],
                        ),
                        style: const TextStyle(fontSize: 17),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "S: ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: "$s"),
                          ],
                        ),
                        style: const TextStyle(fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🟢 2. แยก "ความชื้น" และ "pH" ออกจากกันคนละแถว
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        color: Color(0xFF62B4E6),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "ความชื้น : $humid %",
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.science, color: Colors.purple, size: 28),
                      const SizedBox(width: 10),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: "pH ",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            TextSpan(
                              text: ": $ph",
                              style: const TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // อุณหภูมิ
                  Row(
                    children: [
                      const Icon(
                        Icons.thermostat,
                        color: Colors.black,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "อุณหภูมิ : $temp C°",
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ความเค็ม
                  Row(
                    children: [
                      const Icon(
                        Icons.opacity,
                        color: Colors.black54,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "ความเค็ม : $salty mS/cm",
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // สถานที่
                  const Text(
                    "สถานที่",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ตำบล: $district",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "อำเภอ: $amphur",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "จังหวัด: $province",
                          style: const TextStyle(fontSize: 16),
                        ),
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
                // 1. ส่วนหัว
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.reply,
                        size: 40,
                        color: Colors.black,
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
                      : _filteredList.isEmpty
                      ? const Center(
                          child: Text(
                            "ไม่พบประวัติการบันทึกข้อมูล",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchHistoryData,
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filteredList.length,
                            itemBuilder: (context, index) {
                              final item = _filteredList[index];
                              return _buildHistoryCard(item);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔹 6. ฟังก์ชันสร้างการ์ดพรีวิวแบบย่อ (ตามรูปที่ 1)
  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final String gardenName = item['title'] ?? 'ไม่ระบุชื่อ';
    final String createdAt = item['created_at'] ?? '';
    final String dateStr = _formatDate(createdAt);
    final String timeStr = _formatTime(createdAt);

    final n = item['N'] ?? 0;
    final p = item['P'] ?? 0;
    final k = item['K'] ?? 0;

    return InkWell(
      onTap: () => _showDetailModal(item), // กดเพื่อเปิด Modal รูปที่ 2
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5D6), // สีครีมสว่างตามรูปที่ 1
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
                  "$dateStr   $timeStr",
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
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
