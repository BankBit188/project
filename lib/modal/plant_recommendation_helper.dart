import 'package:flutter/material.dart';
import 'package:project/service/plants_service.dart';
import 'plant_detail.dart';

class PlantRecommendationHelper {
  /// 🟢 ฟังก์ชันหลักสำหรับประมวลผลและเปิดพืชแนะนำ
  static Future<void> showRecommendations({
    required BuildContext context,
    List<dynamic>? cachedPlants,
    String? customTitle,
    double? temp,
    double? humidity,
    double? n,
    double? p,
    double? k,
    double? ca,
    double? mg,
    double? s,
    double? ph,
    double? salty,
  }) async {
    try {
      // 1. ดึงข้อมูลพืชทั้งหมด
      List<dynamic> plantsToUse = cachedPlants ?? [];
      if (plantsToUse.isEmpty) {
        plantsToUse = await PlantsService.getplants();
      }

      // 2. รวบรวมเฉพาะค่าที่มีการกรอกเข้ามา (Non-null)
      Map<String, double> activeCriteria = {};
      if (humidity != null) activeCriteria['ความชื้น'] = humidity;
      if (temp != null) activeCriteria['อุณหภูมิ'] = temp;
      if (n != null) activeCriteria['N'] = n;
      if (p != null) activeCriteria['P'] = p;
      if (k != null) activeCriteria['K'] = k;
      if (ca != null) activeCriteria['Ca'] = ca;
      if (mg != null) activeCriteria['Mg'] = mg;
      if (s != null) activeCriteria['S'] = s;
      if (ph != null) activeCriteria['pH'] = ph;
      if (salty != null) activeCriteria['ความเค็ม'] = salty;

      if (activeCriteria.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ไม่มีข้อมูลสภาพดินที่จะนำไปประมวลผล"),
            ),
          );
        }
        return;
      }

      // 3. กรองพืชอย่างเข้มงวด (ต้องผ่านเกณฑ์ที่กรอกเข้ามาทั้งหมด 100%)
      List<Map<String, dynamic>> suitablePlants = [];

      for (var plant in plantsToUse) {
        bool matchesAll = true;

        activeCriteria.forEach((key, value) {
          dynamic minVal;
          dynamic maxVal;

          switch (key) {
            case 'ความชื้น':
              minVal = plant['minhumid'];
              maxVal = plant['maxhumid'];
              break;
            case 'อุณหภูมิ':
              minVal = plant['mintemperature'];
              maxVal = plant['maxtemperature'];
              break;
            case 'N':
              minVal = plant['minN'];
              maxVal = plant['maxN'];
              break;
            case 'P':
              minVal = plant['minP'];
              maxVal = plant['maxP'];
              break;
            case 'K':
              minVal = plant['minK'];
              maxVal = plant['maxK'];
              break;
            case 'Ca':
              minVal = plant['minCa'];
              maxVal = plant['maxCa'];
              break;
            case 'Mg':
              minVal = plant['minMg'];
              maxVal = plant['maxMg'];
              break;
            case 'S':
              minVal = plant['minS'];
              maxVal = plant['maxS'];
              break;
            case 'pH':
              minVal = plant['minPH'];
              maxVal = plant['maxPH'];
              break;
            case 'ความเค็ม':
              minVal = plant['minsalty'];
              maxVal = plant['maxsalty'];
              break;
          }

          if (!_isInBounds(value, minVal, maxVal)) {
            matchesAll = false;
          }
        });

        if (matchesAll) {
          suitablePlants.add({
            'plantData': plant,
          });
        }
      }

      // 4. แสดงผลลัพธ์
      if (context.mounted) {
        if (suitablePlants.isNotEmpty) {
          _showResultsBottomSheet(
            context,
            suitablePlants,
            activeCriteria,
            customTitle ?? "พืชปลูกที่เหมาะสมกับสภาพดินปัจจุบัน",
          );
        } else {
          // 🔴 กรณีไม่มีพืชที่ตรงทุกค่า
          Map<String, bool> criteriaValidationResults = {};

          activeCriteria.forEach((key, val) {
            bool hasMatchingPlantForThisKey = false;

            for (var plant in plantsToUse) {
              dynamic minVal;
              dynamic maxVal;

              switch (key) {
                case 'ความชื้น':
                  minVal = plant['minhumid'];
                  maxVal = plant['maxhumid'];
                  break;
                case 'อุณหภูมิ':
                  minVal = plant['mintemperature'];
                  maxVal = plant['maxtemperature'];
                  break;
                case 'N':
                  minVal = plant['minN'];
                  maxVal = plant['maxN'];
                  break;
                case 'P':
                  minVal = plant['minP'];
                  maxVal = plant['maxP'];
                  break;
                case 'K':
                  minVal = plant['minK'];
                  maxVal = plant['maxK'];
                  break;
                case 'Ca':
                  minVal = plant['minCa'];
                  maxVal = plant['maxCa'];
                  break;
                case 'Mg':
                  minVal = plant['minMg'];
                  maxVal = plant['maxMg'];
                  break;
                case 'S':
                  minVal = plant['minS'];
                  maxVal = plant['maxS'];
                  break;
                case 'pH':
                  minVal = plant['minPH'];
                  maxVal = plant['maxPH'];
                  break;
                case 'ความเค็ม':
                  minVal = plant['minsalty'];
                  maxVal = plant['maxsalty'];
                  break;
              }

              if (_isInBounds(val, minVal, maxVal)) {
                hasMatchingPlantForThisKey = true;
                break;
              }
            }

            criteriaValidationResults[key] = hasMatchingPlantForThisKey;
          });

          _showNoMatchingDialog(
            context,
            activeCriteria,
            criteriaValidationResults,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาดในการประมวลผล: $e")),
        );
      }
    }
  }

  /// 🟩 เช็คว่าค่าอยู่ในช่วง min-max หรือไม่
  static bool _isInBounds(double input, dynamic minVal, dynamic maxVal) {
    if (minVal == null || maxVal == null) return false;
    double min = double.tryParse(minVal.toString()) ?? 0.0;
    double max = double.tryParse(maxVal.toString()) ?? double.infinity;
    return input >= min && input <= max;
  }

  /// 🔴 แสดง Dialog กรณีไม่มีพืชที่ตรงตามเกณฑ์ทั้งหมด
  static void _showNoMatchingDialog(
    BuildContext context,
    Map<String, double> activeCriteria,
    Map<String, bool> validationResults,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFFF5EFCB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.black87, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 55,
                ),
                const SizedBox(height: 10),
                const Text(
                  "ไม่มีพืชที่เหมาะสม",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "ไม่พบพืชที่ตรงตามเกณฑ์ทั้งหมดในเวลาเดียวกัน",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 15),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "ตรวจสอบเกณฑ์รายค่าที่กรอกมา:",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE8C8),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black26),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: activeCriteria.entries.map((entry) {
                      bool isSupported = validationResults[entry.key] ?? false;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSupported
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${isSupported ? '✓' : '✕'} ${entry.key}: ${entry.value % 1 == 0 ? entry.value.toInt() : entry.value}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 25),
                InkWell(
                  onTap: () => Navigator.pop(dialogContext),
                  child: Container(
                    width: 110,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6BBA90),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black87, width: 1.2),
                    ),
                    child: const Text(
                      "ตกลง",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 🟢 แสดง Bottom Sheet รายชื่อพืชเหมาะสม (หน้าละ 4 รายการ)
  static void _showResultsBottomSheet(
    BuildContext context,
    List<Map<String, dynamic>> items,
    Map<String, double> activeCriteria,
    String title,
  ) {
    int currentPage = 1; // เริ่มต้นที่หน้า 1
    const int itemsPerPage = 4; // แสดงหน้าละ 4 รายการ

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int totalPages = (items.length / itemsPerPage).ceil();
            int startIndex = (currentPage - 1) * itemsPerPage;
            int endIndex = (startIndex + itemsPerPage < items.length)
                ? startIndex + itemsPerPage
                : items.length;

            List<Map<String, dynamic>> pageItems =
                items.sublist(startIndex, endIndex);

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Color(0xFFF1E6C9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E5A36),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "$title (พบ ${items.length} ชนิด)",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // List รายการพืช
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) {
                        var plant = pageItems[index]['plantData'];

                        String plantName =
                            plant['normal_name'] ?? 'ไม่ระบุชื่อ';
                        String rawImageUrl =
                            plant['img_cloudinary'] ?? plant['img'] ?? '';
                        String formattedImgUrl =
                            PlantDetailDialog.formatImgUrl(rawImageUrl);

                        return GestureDetector(
                          onTap: () => PlantDetailDialog.show(
                              context, Map<String, dynamic>.from(plant)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6F8E5F),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF2E5A36), width: 1.5),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 🖼️ รูปภาพอยู่ฝั่งซ้าย
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: formattedImgUrl.isNotEmpty
                                      ? Image.network(
                                          formattedImgUrl,
                                          width: 95,
                                          height: 95,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            width: 95,
                                            height: 95,
                                            color: Colors.white24,
                                            child: const Icon(Icons.eco,
                                                color: Colors.white, size: 40),
                                          ),
                                        )
                                      : Container(
                                          width: 95,
                                          height: 95,
                                          color: Colors.white24,
                                          child: const Icon(Icons.eco,
                                              color: Colors.white, size: 40),
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // 📝 ข้อความและปุ่มอยู่ฝั่งขวา
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${startIndex + index + 1}. $plantName",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 10),

                                      // 🔘 ปุ่มเช็คค่าธาตุอาหาร
                                      InkWell(
                                        onTap: () {
                                          _showNutrientCheckDialog(
                                            context,
                                            Map<String, dynamic>.from(plant),
                                            activeCriteria,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFCF4D9),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.black54),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.fact_check_outlined,
                                                size: 16,
                                                color: Colors.black87,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                "เช็คค่าธาตุอาหาร",
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 📄 dynamic Pagination ด้านล่าง
                  _buildDynamicPagination(
                    currentPage: currentPage,
                    lastPage: totalPages,
                    onPageChanged: (newPage) {
                      setModalState(() {
                        currentPage = newPage;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 🔘 ฟังก์ชันสร้าง Dynamic Pagination
  static Widget _buildDynamicPagination({
    required int currentPage,
    required int lastPage,
    required Function(int) onPageChanged,
  }) {
    if (lastPage <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    // ปุ่มย้อนกลับ <
    pageButtons.add(
      _buildPageBtn(
        "<",
        disabled: currentPage == 1,
        onTap: () {
          if (currentPage > 1) {
            onPageChanged(currentPage - 1);
          }
        },
      ),
    );

    bool showLeftDots = false;
    bool showRightDots = false;

    for (int i = 1; i <= lastPage; i++) {
      if (i == 1 || i == lastPage || (i - currentPage).abs() <= 1) {
        pageButtons.add(
          _buildPageBtn(
            i.toString(),
            isActive: currentPage == i,
            onTap: () {
              if (currentPage != i) {
                onPageChanged(i);
              }
            },
          ),
        );
      } else if (i < currentPage && !showLeftDots) {
        showLeftDots = true;
        pageButtons.add(_buildDotsBtn());
      } else if (i > currentPage && !showRightDots) {
        showRightDots = true;
        pageButtons.add(_buildDotsBtn());
      }
    }

    // ปุ่มถัดไป >
    pageButtons.add(
      _buildPageBtn(
        ">",
        disabled: currentPage == lastPage,
        onTap: () {
          if (currentPage < lastPage) {
            onPageChanged(currentPage + 1);
          }
        },
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pageButtons,
    );
  }

  /// 🔘 ฟังก์ชันสร้างปุ่มจุดไข่ปลา (...)
  static Widget _buildDotsBtn() {
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

  /// 🔘 ฟังก์ชันสร้างปุ่มตัวเลขหน้า
  static Widget _buildPageBtn(
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

  /// 🔍 Dialog แสดงการเปรียบเทียบค่าธาตุอาหารของพืชตัวนั้นๆ กับค่าที่กรอกเข้ามา
  static void _showNutrientCheckDialog(
    BuildContext context,
    Map<String, dynamic> plant,
    Map<String, double> activeCriteria,
  ) {
    String plantName = plant['normal_name'] ?? 'ไม่ระบุชื่อ';
    String rawImageUrl = plant['img_cloudinary'] ?? plant['img'] ?? '';
    String formattedImgUrl = PlantDetailDialog.formatImgUrl(rawImageUrl);

    final List<Map<String, String>> factors = [
      {'label': 'N', 'min': 'minN', 'max': 'maxN'},
      {'label': 'P', 'min': 'minP', 'max': 'maxP'},
      {'label': 'K', 'min': 'minK', 'max': 'maxK'},
      {'label': 'Ca', 'min': 'minCa', 'max': 'maxCa'},
      {'label': 'Mg', 'min': 'minMg', 'max': 'maxMg'},
      {'label': 'S', 'min': 'minS', 'max': 'maxS'},
      {'label': 'ความชื้น', 'min': 'minhumid', 'max': 'maxhumid'},
      {'label': 'ความเค็ม', 'min': 'minsalty', 'max': 'maxsalty'},
      {'label': 'อุณหภูมิ', 'min': 'mintemperature', 'max': 'maxtemperature'},
      {'label': 'pH', 'min': 'minPH', 'max': 'maxPH'},
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFFF5EFCB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.black87, width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ตรวจสอบค่าธาตุอาหาร",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // รูปภาพและชื่อพืช
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: formattedImgUrl.isNotEmpty
                            ? Image.network(
                                formattedImgUrl,
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  width: 55,
                                  height: 55,
                                  color: Colors.white30,
                                  child: const Icon(Icons.eco,
                                      color: Colors.green),
                                ),
                              )
                            : Container(
                                width: 55,
                                height: 55,
                                color: Colors.white30,
                                child:
                                    const Icon(Icons.eco, color: Colors.green),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          plantName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.black26),
                  const SizedBox(height: 8),

                  // แสดงรายการ Min - Max และ ค่าของผู้ใช้
                  Column(
                    children: factors.map((factor) {
                      String label = factor['label']!;
                      dynamic minVal = plant[factor['min']!];
                      dynamic maxVal = plant[factor['max']!];

                      String minStr = minVal?.toString() ?? '-';
                      String maxStr = maxVal?.toString() ?? '-';

                      bool hasUserInput = activeCriteria.containsKey(label);
                      double? userVal = activeCriteria[label];

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: hasUserInput
                              ? const Color(0xFFD8EAD3)
                              : const Color(0xFFEFE8C8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasUserInput
                                ? Colors.green.shade700
                                : Colors.black12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "$label : $minStr - $maxStr",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: hasUserInput
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                            if (hasUserInput) ...[
                              Row(
                                children: [
                                  Text(
                                    ": ${userVal != null && userVal % 1 == 0 ? userVal.toInt() : userVal}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ปุ่มปิด
                  InkWell(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      width: 100,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6BBA90),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.black87),
                      ),
                      child: const Text(
                        "ตกลง",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}