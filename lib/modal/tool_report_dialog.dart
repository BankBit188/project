import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project/service/reports_service.dart';

class ReportDialog extends StatefulWidget {
  final String? userId;

  const ReportDialog({
    super.key,
    required this.userId,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImageFile;

  // 🎨 กำหนดชุดสีธีมของแอป
  static const Color modalBg = Color(0xFFE8EFE6);      // พื้นหลัง Modal เขียวอุ่นละมุน
  static const Color primaryGreen = Color(0xFF4A7C59); // สีเขียวหลัก
  static const Color textColor = Color(0xFF212522);    // สีตัวอักษรเข้มอ่านง่าย

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final isSmallScreen = screenWidth < 360;
    final dialogMaxWidth = screenWidth > 600 ? 460.0 : screenWidth * 0.90;

    return Dialog(
      backgroundColor: modalBg, // 👈 ปรับพื้นหลังเป็นสีเขียวพาสเทล ถนอมสายตา
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.black54, width: 1), // 👈 กรอบสีดำชัดเจน
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: screenHeight * 0.85,
        ),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 14.0 : 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 ส่วนหัว Dialog
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      "แจ้งปัญหา",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.close,
                          color: textColor, // 👈 ไอคอนปิดโทนสีเข้มละมุน
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 📌 เนื้อหาที่ Scroll ได้
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "หัวข้อ : ",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white, // 👈 กล่องข้อความสีขาว คมชัด
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black54, width: 1),
                              ),
                              child: TextField(
                                controller: _titleController,
                                textAlignVertical: TextAlignVertical.center,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: textColor,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        "รายละเอียด",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black54, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: _detailController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: textColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "รูปภาพ : ",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: primaryGreen, // 👈 ปุ่มเลือกรูปโทนสีเขียวประจำธีม
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black54, width: 1),
                            ),
                            child: TextButton(
                              onPressed: () async {
                                final XFile? image = await _picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (image != null) {
                                  setState(() {
                                    _selectedImageFile = image;
                                  });
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                minimumSize: Size.zero,
                              ),
                              child: Text(
                                _selectedImageFile == null ? "เลือกรูปภาพ" : "เปลี่ยนรูปภาพ",
                                style: const TextStyle(
                                  color: Colors.white, // 👈 ข้อความสีขาวอ่านง่าย
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_selectedImageFile != null)
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black54, width: 1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.file(
                                  File(_selectedImageFile!.path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImageFile = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Text(
                            "ยังไม่ได้เลือกรูปภาพ",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  height: 42,
                  width: 100,
                  decoration: BoxDecoration(
                    color: primaryGreen, // 👈 ปุ่มส่งรายงานสีเขียวธีมหลัก
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black54, width: 1),
                  ),
                  child: TextButton(
                    onPressed: _sendReport,
                    child: const Text(
                      "ส่ง",
                      style: TextStyle(
                        color: Colors.white, // 👈 ตัวอักษรสีขาวเน้นความคมชัด
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendReport() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกหัวข้อแจ้งปัญหา')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Map<String, String> reportData = {
        'Userid': widget.userId ?? '',
        'reporttitle': _titleController.text.trim(),
        'reportdetail': _detailController.text.trim(),
      };

      final response = await ReportsService.createReport(
        reportData: reportData,
        imageFile: _selectedImageFile,
      );

      if (mounted) {
        Navigator.pop(context); // ปิด Loading
        Navigator.pop(context); // ปิด Dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'ส่งรายงานสำเร็จ'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // ปิด Loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งข้อมูลล้มเหลวเนื่องจาก: $e')),
        );
      }
    }
  }
}