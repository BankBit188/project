import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project/service/tool_service.dart';
import 'package:project/style/style_history.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _historyList = [];
  List<dynamic> _filteredList = [];
  List<dynamic> _displayedList = [];

  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 1;
  int _lastPage = 1;
  final int _itemsPerPage = 4;

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

  void _showDetailModal(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HistoryDetailModal(
          item: item,
          dateTimeStr: _formatDateTime(item['created_at']),
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
        decoration: HistoryTheme.pageDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 25.0,
              vertical: 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Widget
                HistoryHeaderWidget(
                  onBackPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 25),

                // 2. Search Bar Widget
                HistorySearchBarWidget(
                  controller: _searchController,
                  onChanged: _filterHistory,
                ),
                const SizedBox(height: 20),

                // 3. History Item List
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: HistoryTheme.primaryGreen,
                          ),
                        )
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
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HistoryTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                    ),
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
                                  color: HistoryTheme.primaryGreen,
                                  onRefresh: _fetchHistoryData,
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _displayedList.length,
                                    itemBuilder: (context, index) {
                                      final item = _displayedList[index];
                                      return HistoryCardTile(
                                        item: item,
                                        dateTimeStr: _formatDateTime(
                                          item['created_at'],
                                        ),
                                        onTap: () => _showDetailModal(item),
                                      );
                                    },
                                  ),
                                ),
                ),

                // 4. Pagination Bar Widget (อยู่ตรงกลาง)
                if (!_isLoading && _errorMessage == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: HistoryPaginationBar(
                      currentPage: _currentPage,
                      lastPage: _lastPage,
                      onPageSelected: (page) {
                        setState(() {
                          _currentPage = page;
                          _updateDisplayedItems();
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}