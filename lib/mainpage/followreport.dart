import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/service/user_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class FollowReportPage extends StatefulWidget {
  const FollowReportPage({super.key});

  @override
  State<FollowReportPage> createState() => _FollowReportPageState();
}

class _FollowReportPageState extends State<FollowReportPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // ข้อมูลรายงาน
  List<dynamic> _reports = [];
  List<dynamic> _displayedReports = [];
  bool _isLoading = true;

  // ตัวแปรสำหรับตัวกรองสถานะ ('all', '1', '2', '3')
  String _selectedStatus = 'all';

  // ตัวแปร Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th', null);
    _fetchUserReports();
  }

  // ดึงรายการรายงานที่ผ่านการกรองสถานะ
  List<dynamic> get _filteredReports {
    if (_selectedStatus == 'all') {
      return _reports;
    }
    return _reports.where((report) {
      final statusInt = int.tryParse(report['status'].toString()) ?? 1;
      return statusInt.toString() == _selectedStatus;
    }).toList();
  }

  Future<void> _fetchUserReports() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String? userId = await _secureStorage.read(key: "Userid");
      String? token = await _secureStorage.read(key: "auth_token");

      if (userId != null && token != null) {
        final response = await UserService.getreportbyuser(userId, token);
        
        if (!mounted) return;
        if (response != null) {
          List<dynamic> loadedData = [];
          if (response is Map && response['data'] != null) {
            loadedData = response['data'];
          } else if (response is Map && response['reports'] != null) {
            loadedData = response['reports'];
          } else if (response is List) {
            loadedData = response;
          }

          _reports = loadedData;
          _currentPage = 1;
          _updateDisplayedItems();
        }
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการโหลดรายงาน: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // คำนวณตัดแบ่งข้อมูลตามหน้า
  void _updateDisplayedItems() {
    final filtered = _filteredReports;
    if (filtered.isEmpty) {
      setState(() {
        _displayedReports = [];
        _lastPage = 1;
        _currentPage = 1;
      });
      return;
    }

    final int totalItems = filtered.length;
    _lastPage = (totalItems / _itemsPerPage).ceil();

    if (_currentPage > _lastPage) {
      _currentPage = _lastPage;
    }
    if (_currentPage < 1) {
      _currentPage = 1;
    }

    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > totalItems) {
      endIndex = totalItems;
    }

    setState(() {
      _displayedReports = filtered.sublist(startIndex, endIndex);
    });
  }

  String _getStatusText(dynamic status) {
    final statusInt = int.tryParse(status.toString()) ?? 1;
    switch (statusInt) {
      case 1:
        return 'ยังไม่ได้อ่าน';
      case 2:
        return 'รอดำเนินการ';
      case 3:
        return 'ดำเนินการเสร็จสิ้น';
      default:
        return 'ยังไม่ได้อ่าน';
    }
  }

  Color _getStatusColor(dynamic status) {
    final statusInt = int.tryParse(status.toString()) ?? 1;
    switch (statusInt) {
      case 1:
        return Colors.orange.shade800;
      case 2:
        return Colors.blue.shade800;
      case 3:
        return Colors.green.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatThaiDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "-";
    try {
      DateTime dateTime = DateTime.parse(dateStr).toLocal();
      String dayMonth = DateFormat('d MMMM', 'th').format(dateTime);
      int thaiYear = dateTime.year + 543;
      String time = DateFormat('HH:mm').format(dateTime);
      return "$dayMonth $thaiYear เวลา $time น.";
    } catch (e) {
      return dateStr;
    }
  }

  String _formatThaiDateTimeShort(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      DateTime dateTime = DateTime.parse(dateStr).toLocal();
      String dayMonth = DateFormat('d MMM', 'th').format(dateTime);
      int thaiYear = (dateTime.year + 543) % 100;
      String time = DateFormat('HH:mm').format(dateTime);
      return "$dayMonth $thaiYear  $time น.";
    } catch (e) {
      return dateStr;
    }
  }

  void _showReportDetailDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final String title = report['reporttitle'] ?? '-';
        final String detail = report['reportdetail'] ?? '-';
        final String status = _getStatusText(report['status']);
        final Color statusColor = _getStatusColor(report['status']);
        final String? imageUrl = report['img_cloudinary'];
        final String createdAt = _formatThaiDateTime(report['created_at']);
        final String username = report['username'] ?? 'ไม่ระบุผู้ใช้';

        return Dialog(
          backgroundColor: const Color(0xFFFCEEBA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black87, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "รายละเอียดรายงาน",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black54),
                  const SizedBox(height: 10),
                  Text("หัวข้อ: $title", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("ผู้แจ้ง: $username", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("สถานะ: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("วันที่แจ้ง: $createdAt", style: const TextStyle(fontSize: 14, color: Colors.black87)),
                  const SizedBox(height: 12),
                  const Text("รายละเอียดปัญหา:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Text(detail, style: const TextStyle(fontSize: 14)),
                  ),
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Text("รูปภาพประกอบ:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Text("ไม่สามารถโหลดรูปภาพได้"),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 🎨 Widget ตัวกรองสถานะปัญหา (ปรับแต่งใหม่ให้อ่านง่าย สบายตา)
  Widget _buildFilterChips() {
    final filters = [
      {
        'label': 'ทั้งหมด',
        'value': 'all',
        'color': const Color(0xFF374151),
        'icon': Icons.grid_view_rounded,
      },
      {
        'label': 'ยังไม่ได้อ่าน',
        'value': '1',
        'color': Colors.orange.shade800,
        'icon': Icons.mark_email_unread_outlined,
      },
      {
        'label': 'รอดำเนินการ',
        'value': '2',
        'color': Colors.blue.shade800,
        'icon': Icons.pending_actions_rounded,
      },
      {
        'label': 'ดำเนินการเสร็จสิ้น',
        'value': '3',
        'color': Colors.green.shade800,
        'icon': Icons.check_circle_outline_rounded,
      },
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final String value = f['value'] as String;
          final String label = f['label'] as String;
          final Color themeColor = f['color'] as Color;
          final IconData icon = f['icon'] as IconData;
          final bool isSelected = _selectedStatus == value;

          return Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  if (!isSelected) {
                    setState(() {
                      _selectedStatus = value;
                      _currentPage = 1;
                    });
                    _updateDisplayedItems();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? themeColor : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isSelected ? themeColor : themeColor.withOpacity(0.4),
                      width: isSelected ? 1.8 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeColor.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected ? Colors.white : themeColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : themeColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget สำหรับสร้างปุ่มเปลี่ยนหน้า Dynamic Pagination
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
              ? const Color(0xFF374151)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "ติดตามปัญหา",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // 🔹 แถบปุ่มกรองข้อมูล (Filter Chips)
              if (!_isLoading && _reports.isNotEmpty) ...[
                _buildFilterChips(),
                const SizedBox(height: 6),
              ],

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredReports.isEmpty
                        ? const Center(
                            child: Text(
                              "ไม่พบรายการปัญหาตามที่กรอง",
                              style: TextStyle(fontSize: 18, color: Colors.black54),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchUserReports,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _displayedReports.length,
                              itemBuilder: (context, index) {
                                final report = _displayedReports[index];
                                final String title = report['reporttitle'] ?? 'ไม่มีหัวข้อ';
                                final String statusText = _getStatusText(report['status']);
                                final Color statusColor = _getStatusColor(report['status']);
                                final String dateTimeStr = _formatThaiDateTimeShort(report['created_at']);

                                return Card(
                                  color: const Color(0xFFFCF4D9),
                                  margin: const EdgeInsets.only(bottom: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: const BorderSide(color: Colors.black54),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (dateTimeStr.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            dateTimeStr,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          const Text("สถานะ: ", style: TextStyle(color: Colors.black87)),
                                          Text(
                                            statusText,
                                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: const Icon(Icons.chevron_right, color: Colors.black87),
                                    onTap: () => _showReportDetailDialog(report),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
              if (!_isLoading && _filteredReports.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0, top: 5.0),
                  child: _buildDynamicPagination(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}