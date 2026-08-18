import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/service/user_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:project/style/style_followreport.dart'; // 👈 นำเข้าไฟล์สไตล์ที่แยกไว้

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
          backgroundColor: FollowReportTheme.modalBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: FollowReportTheme.darkGreen.withOpacity(0.35), width: 1.5),
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
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                          color: FollowReportTheme.textColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: FollowReportTheme.textColor),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  Divider(color: FollowReportTheme.darkGreen.withOpacity(0.3)),
                  const SizedBox(height: 10),
                  Text("หัวข้อ: $title", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FollowReportTheme.textColor)),
                  const SizedBox(height: 8),
                  Text("ผู้แจ้ง: $username", style: const TextStyle(fontSize: 14, color: FollowReportTheme.textColor)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("สถานะ: ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FollowReportTheme.textColor)),
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
                  Text("วันที่แจ้ง: $createdAt", style: const TextStyle(fontSize: 14, color: FollowReportTheme.textColor)),
                  const SizedBox(height: 12),
                  const Text("รายละเอียดปัญหา:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FollowReportTheme.textColor)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FollowReportTheme.primaryGreen.withOpacity(0.2)),
                    ),
                    child: Text(detail, style: const TextStyle(fontSize: 14, color: FollowReportTheme.textColor)),
                  ),
                  if (imageUrl != null && imageUrl.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    const Text("รูปภาพประกอบ:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FollowReportTheme.textColor)),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildFilterChips() {
    final filters = [
      {
        'label': 'ทั้งหมด',
        'value': 'all',
        'color': FollowReportTheme.primaryGreen,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: FollowReportTheme.pageDecoration, // 👈 ใช้ Gradient จาก Theme
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: FollowReportHeaderWidget( // 👈 1. Header พร้อมไอคอน
                  onBackPressed: () => Navigator.pop(context),
                ),
              ),

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
                              style: TextStyle(fontSize: 18, color: FollowReportTheme.textColor),
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

                                return FollowReportCardTile( // 👈 3. Card ไตล์เขียวซอฟต์พาสเทล + กรอบจางๆ
                                  title: title,
                                  dateTimeStr: dateTimeStr,
                                  statusText: statusText,
                                  statusColor: statusColor,
                                  onTap: () => _showReportDetailDialog(report),
                                );
                              },
                            ),
                          ),
              ),
              if (!_isLoading && _filteredReports.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0, top: 5.0),
                  child: FollowReportPaginationBar( // 👈 2. Pagination ปุ่มสีเขียวตามธีม
                    currentPage: _currentPage,
                    lastPage: _lastPage,
                    onPageSelected: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                      _updateDisplayedItems();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}