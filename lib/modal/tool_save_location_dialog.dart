import 'package:flutter/material.dart';
import 'package:project/mainpage/history.dart';
import 'package:project/service/tool_service.dart';

class SaveLocationDialog extends StatefulWidget {
  final String? userId;
  final String? authToken;
  final Map<String, dynamic>? toolData;
  final List<dynamic> thailandData;

  const SaveLocationDialog({
    super.key,
    required this.userId,
    required this.authToken,
    required this.toolData,
    required this.thailandData,
  });

  @override
  State<SaveLocationDialog> createState() => _SaveLocationDialogState();
}

class _SaveLocationDialogState extends State<SaveLocationDialog> {
  final TextEditingController _titleController = TextEditingController();

  final List<Map<String, dynamic>> _regions = const [
    {'id': 1, 'name': 'ภาคเหนือ'},
    {'id': 2, 'name': 'ภาคกลาง'},
    {'id': 3, 'name': 'ภาคตะวันออกเฉียงเหนือ'},
    {'id': 4, 'name': 'ภาคตะวันตก'},
    {'id': 5, 'name': 'ภาคตะวันออก'},
    {'id': 6, 'name': 'ภาคใต้'},
  ];

  String? _selectedRegion;
  String? _selectedProvince;
  String? _selectedAmphur;
  String? _selectedDistrict;

  List<dynamic> _provinceList = [];
  List<dynamic> _amphurList = [];
  List<dynamic> _districtList = [];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _getName(dynamic item) {
    if (item is Map) {
      return item['name_th'] ?? item['name'] ?? item['name_en'] ?? '';
    }
    return item.toString();
  }

  List<dynamic> _getAmphures(dynamic provinceObj) {
    if (provinceObj is Map) {
      return provinceObj['amphure'] ??
          provinceObj['amphur'] ??
          provinceObj['districts'] ??
          [];
    }
    return [];
  }

  List<dynamic> _getTambons(dynamic amphurObj) {
    if (amphurObj is Map) {
      return amphurObj['tambon'] ??
          amphurObj['district'] ??
          amphurObj['subdistricts'] ??
          [];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final isSmallScreen = screenWidth < 360;
    final dialogMaxWidth = screenWidth > 600 ? 480.0 : screenWidth * 0.90;

    return Dialog(
      backgroundColor: const Color(0xFFF5EFCB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: const BorderSide(color: Colors.black87, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: screenHeight * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 14.0 : 20.0,
            vertical: isSmallScreen ? 16.0 : 20.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "ระบุสถานที่และที่ตั้ง",
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLocationInputRow(
                        label: "สถานที่ :",
                        isSmallScreen: isSmallScreen,
                        child: TextField(
                          controller: _titleController,
                          style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            border: InputBorder.none,
                            hintText: "เช่น แปลงนาที่ 1",
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildLocationInputRow(
                        label: "ภาค :",
                        isSmallScreen: isSmallScreen,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRegion,
                            hint: Text("เลือกภาค", style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                            items: _regions.map<DropdownMenuItem<String>>((reg) {
                              return DropdownMenuItem<String>(
                                value: reg['name'].toString(),
                                child: Text(reg['name'].toString(), style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedRegion = val;
                                _selectedProvince = null;
                                _selectedAmphur = null;
                                _selectedDistrict = null;
                                _amphurList = [];
                                _districtList = [];

                                var regObj = _regions.firstWhere(
                                  (r) => r['name'] == val,
                                  orElse: () => {},
                                );
                                if (regObj.isNotEmpty) {
                                  _provinceList = widget.thailandData
                                      .where((p) => p['geography_id'] == regObj['id'])
                                      .toList();
                                } else {
                                  _provinceList = [];
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildLocationInputRow(
                        label: "จังหวัด :",
                        isSmallScreen: isSmallScreen,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProvince,
                            hint: Text("เลือกจังหวัด", style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                            items: _provinceList.map<DropdownMenuItem<String>>((prov) {
                              String name = _getName(prov);
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedProvince = val;
                                _selectedAmphur = null;
                                _selectedDistrict = null;
                                _districtList = [];

                                var provObj = _provinceList.firstWhere(
                                  (element) => _getName(element) == val,
                                  orElse: () => null,
                                );
                                _amphurList = provObj != null ? _getAmphures(provObj) : [];
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildLocationInputRow(
                        label: "อำเภอ :",
                        isSmallScreen: isSmallScreen,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAmphur,
                            hint: Text("เลือกอำเภอ", style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                            items: _amphurList.map<DropdownMenuItem<String>>((amp) {
                              String name = _getName(amp);
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedAmphur = val;
                                _selectedDistrict = null;

                                var ampObj = _amphurList.firstWhere(
                                  (element) => _getName(element) == val,
                                  orElse: () => null,
                                );
                                _districtList = ampObj != null ? _getTambons(ampObj) : [];
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildLocationInputRow(
                        label: "ตำบล :",
                        isSmallScreen: isSmallScreen,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDistrict,
                            hint: Text("เลือกตำบล", style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                            items: _districtList.map<DropdownMenuItem<String>>((dt) {
                              String name = _getName(dt);
                              return DropdownMenuItem<String>(
                                value: name,
                                child: Text(name, style: TextStyle(fontSize: isSmallScreen ? 13 : 14)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDistrict = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: _submitData,
                    child: Container(
                      width: isSmallScreen ? 90 : 110,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6BBA90),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black87, width: 1.2),
                      ),
                      child: Text(
                        "ยืนยัน",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: isSmallScreen ? 90 : 110,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE26A6A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black87, width: 1.2),
                      ),
                      child: Text(
                        "ยกเลิก",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitData() async {
    if (widget.authToken == null || widget.userId == null || widget.authToken!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบข้อมูลการเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่อีกครั้ง")),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _selectedRegion == null ||
        _selectedProvince == null ||
        _selectedAmphur == null ||
        _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลสถานที่และเลือกที่ตั้งให้ครบถ้วน")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String formattedRegion = _selectedRegion!.replaceAll('ภาค', '');

      await ToolService.createhistory(
        userId: widget.userId!,
        token: widget.authToken!,
        title: _titleController.text.trim(),
        region: formattedRegion,
        province: _selectedProvince!,
        Amphur: _selectedAmphur!,
        district: _selectedDistrict!,
        toolData: widget.toolData,
      );

      if (mounted) {
        Navigator.pop(context); // ปิด Loading
        Navigator.pop(context); // ปิด Dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อยแล้ว")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิด Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("บันทึกข้อมูลไม่สำเร็จ: $e")),
        );
      }
    }
  }

  Widget _buildLocationInputRow({
    required String label,
    required Widget child,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        SizedBox(
          width: isSmallScreen ? 70 : 85,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE8C8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black87, width: 1),
            ),
            child: Center(child: child),
          ),
        ),
      ],
    );
  }
}