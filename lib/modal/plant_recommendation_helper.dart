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
        if (plant is! Map) continue;
        Map<String, dynamic> plantMap = Map<String, dynamic>.from(plant);
        bool matchesAll = true;

        activeCriteria.forEach((key, value) {
          final bounds = _getBoundsForFactor(plantMap, key);

          if (!_isInBounds(value, bounds['min'], bounds['max'])) {
            matchesAll = false;
          }
        });

        if (matchesAll) {
          suitablePlants.add({
            'plantData': plantMap,
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
              if (plant is! Map) continue;
              Map<String, dynamic> plantMap = Map<String, dynamic>.from(plant);
              final bounds = _getBoundsForFactor(plantMap, key);

              if (_isInBounds(val, bounds['min'], bounds['max'])) {
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

  /// 🟢 ดึงค่า Min/Max แบบยืดหยุ่น รองรับรูปแบบ Key ใน DB ที่หลากหลาย
  static Map<String, dynamic> _getBoundsForFactor(
    Map<String, dynamic> plant,
    String factorKey,
  ) {
    List<String> minKeys = [];
    List<String> maxKeys = [];

    switch (factorKey) {
      case 'ความชื้น':
        minKeys = ['minhumid', 'min_humid'];
        maxKeys = ['maxhumid', 'max_humid'];
        break;
      case 'อุณหภูมิ':
        minKeys = ['mintemperature', 'min_temp', 'mintemp'];
        maxKeys = ['maxtemperature', 'max_temp', 'maxtemp'];
        break;
      case 'N':
        minKeys = ['minN', 'minn', 'min_n'];
        maxKeys = ['maxN', 'maxn', 'max_n'];
        break;
      case 'P':
        minKeys = ['minP', 'minp', 'min_p'];
        maxKeys = ['maxP', 'maxp', 'max_p'];
        break;
      case 'K':
        minKeys = ['minK', 'mink', 'min_k'];
        maxKeys = ['maxK', 'maxk', 'max_k'];
        break;
      case 'Ca':
        minKeys = ['minCa', 'minca', 'min_ca'];
        maxKeys = ['maxCa', 'maxca', 'max_ca'];
        break;
      case 'Mg':
        minKeys = ['minMg', 'minmg', 'min_mg'];
        maxKeys = ['maxMg', 'maxmg', 'max_mg'];
        break;
      case 'S':
        minKeys = ['minS', 'mins', 'min_s'];
        maxKeys = ['maxS', 'maxs', 'max_s'];
        break;
      case 'pH':
        minKeys = ['minPH', 'minph', 'minPh', 'min_ph'];
        maxKeys = ['maxPH', 'maxph', 'maxPh', 'max_ph'];
        break;
      case 'ความเค็ม':
        minKeys = ['minsalty', 'min_salty'];
        maxKeys = ['maxsalty', 'max_salty'];
        break;
    }

    dynamic minVal;
    dynamic maxVal;

    for (var k in minKeys) {
      if (plant.containsKey(k) && plant[k] != null) {
        minVal = plant[k];
        break;
      }
    }

    for (var k in maxKeys) {
      if (plant.containsKey(k) && plant[k] != null) {
        maxVal = plant[k];
        break;
      }
    }

    return {'min': minVal, 'max': maxVal};
  }

  /// 🟩 เช็คว่าค่าอยู่ในช่วง min-max หรือไม่ (ปรับแก้ให้รองรับค่า null อย่างถูกต้อง)
  static bool _isInBounds(double input, dynamic minVal, dynamic maxVal) {
    double min = minVal != null
        ? (double.tryParse(minVal.toString()) ?? -double.infinity)
        : -double.infinity;

    double max = maxVal != null
        ? (double.tryParse(maxVal.toString()) ?? double.infinity)
        : double.infinity;

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
          backgroundColor: const Color(0xFFE8EFE6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.black38, width: 1),
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
                    color: Color(0xFF212522),
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
                      color: Color(0xFF212522),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E3D4),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.black12),
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
                              ? const Color(0xFF2E6F40)
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
                      color: const Color(0xFF2E6F40),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      "ตกลง",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
    int currentPage = 1;
    const int itemsPerPage = 4;

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
                color: Color(0xFFE8EFE6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E6F40),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
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
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
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
                              color: const Color(0xFF386641),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF1E4B2B), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
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
                                            color: const Color(0xFFE8EFE6),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.black26),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.fact_check_outlined,
                                                size: 16,
                                                color: Color(0xFF212522),
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                "เช็คค่าธาตุอาหาร",
                                                style: TextStyle(
                                                  color: Color(0xFF212522),
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
              ? const Color(0xFF2E6F40)
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
                  : (disabled ? Colors.grey : const Color(0xFF212522)),
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

    final List<String> factors = [
      'N', 'P', 'K', 'Ca', 'Mg', 'S',
      'ความชื้น', 'ความเค็ม', 'อุณหภูมิ', 'pH'
    ];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFFE8EFE6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Colors.black38, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ตรวจสอบค่าธาตุอาหาร",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212522),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                                  color: const Color(0xFFD6E3D4),
                                  child: const Icon(Icons.eco,
                                      color: Color(0xFF2E6F40)),
                                ),
                              )
                            : Container(
                                width: 55,
                                height: 55,
                                color: const Color(0xFFD6E3D4),
                                child:
                                    const Icon(Icons.eco, color: Color(0xFF2E6F40)),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          plantName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212522),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 8),
                  Column(
                    children: factors.map((label) {
                      final bounds = _getBoundsForFactor(plant, label);
                      dynamic minVal = bounds['min'];
                      dynamic maxVal = bounds['max'];

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
                              ? const Color(0xFFCBE3C8)
                              : const Color(0xFFDDE7DA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: hasUserInput
                                ? const Color(0xFF2E6F40)
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
                                color: const Color(0xFF212522),
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
                                      color: Color(0xFF212522),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF2E6F40),
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
                  InkWell(
                    onTap: () => Navigator.pop(dialogContext),
                    child: Container(
                      width: 100,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6F40),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        "ตกลง",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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