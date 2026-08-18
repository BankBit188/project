import 'package:flutter/material.dart';
import 'package:project/modal/plant_detail.dart';

// -----------------------------------------------------------------
// 1. HEADER WIDGET (ส่วนหัวข้อ + ปุ่มย้อนกลับ)
// -----------------------------------------------------------------
class SoilHeaderWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const SoilHeaderWidget({super.key, required this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.1)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.black87,
            ),
            onPressed: onBackPressed,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            "แนะนำพืชปลูกตามธาตุอาหาร",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.science_rounded, color: Color(0xFF4A7C59), size: 26),
      ],
    );
  }
}

// -----------------------------------------------------------------
// 2. SEARCH WIDGET (ช่องค้นหาพืชพร้อมปุ่มล้างข้อความ)
// -----------------------------------------------------------------
class SoilSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  const SoilSearchWidget({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EAE1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF6B7280),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              decoration: const InputDecoration(
                hintText: 'ค้นหา เช่น ชื่อพืช',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: onClearSearch,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// 3. FILTER SECTION (แถบเลือกธาตุอาหาร + ปุ่มกรองประเภทพืช)
// -----------------------------------------------------------------
class SoilFilterSection extends StatelessWidget {
  final String selectedNutrient;
  final int selectedPlantType;
  final ValueChanged<String> onNutrientSelected;
  final ValueChanged<int> onPlantTypeSelected;

  const SoilFilterSection({
    super.key,
    required this.selectedNutrient,
    required this.selectedPlantType,
    required this.onNutrientSelected,
    required this.onPlantTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> nutrients = [
      "ไนโตรเจน",
      "ฟอสฟอรัส",
      "โพแทสเซียม",
      "แคลเซียม",
      "แมกนีเซียม",
      "กำมะถัน"
    ];

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: nutrients.map((nutrient) {
                return _buildFilterChip(nutrient);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 6),
        PopupMenuButton<int>(
          initialValue: selectedPlantType,
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: selectedPlantType == 0
                  ? Colors.white.withOpacity(0.8)
                  : const Color(0xFF4A7C59),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withOpacity(0.1)),
            ),
            child: Icon(
              selectedPlantType == 0
                  ? Icons.filter_alt_outlined
                  : Icons.filter_alt_rounded,
              size: 20,
              color: selectedPlantType == 0 ? Colors.black87 : Colors.white,
            ),
          ),
          tooltip: "กรองประเภทพืช",
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onSelected: onPlantTypeSelected,
          itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
            const PopupMenuItem<int>(value: 0, child: Text('พืชทั้งหมด')),
            const PopupMenuItem<int>(value: 1, child: Text('พืชไร่')),
            const PopupMenuItem<int>(value: 2, child: Text('พืชสวน')),
            const PopupMenuItem<int>(value: 3, child: Text('พืชเศรษฐกิจ')),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    bool isActive = selectedNutrient == label;
    return GestureDetector(
      onTap: () => onNutrientSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4A7C59) : const Color(0xFFE2EAD2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A7C59).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// 4. ITEM CARD (การ์ดแสดงรายการพืช + ค่าธาตุอาหาร 3 แถว)
// -----------------------------------------------------------------
class SoilItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const SoilItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  String _formatVal(dynamic minV, dynamic maxV) {
    if (minV == null && maxV == null) return "-";
    if (minV != null && maxV != null) {
      if (minV.toString() == maxV.toString()) return "$minV";
      return "$minV-$maxV";
    }
    return "${minV ?? maxV}";
  }

  @override
  Widget build(BuildContext context) {
    String title = item['normal_name'] ?? 'ไม่มีชื่อพืช';
    String imgUrl = item['img_cloudinary'] ?? item['img'] ?? '';
    String formattedImgUrl = PlantDetailDialog.formatImgUrl(imgUrl);

    String nVal = _formatVal(item['minN'], item['maxN']);
    String pVal = _formatVal(item['minP'], item['maxP']);
    String kVal = _formatVal(item['minK'], item['maxK']);
    String caVal = _formatVal(item['minCa'], item['maxCa']);
    String mgVal = _formatVal(item['minMg'], item['maxMg']);
    String sVal = _formatVal(item['minS'], item['maxS']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF2EDB4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 1.2),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: formattedImgUrl.isNotEmpty
                  ? Image.network(
                      formattedImgUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      cacheHeight: 300,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 110,
                          height: 110,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 110,
                        height: 110,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "N: $nVal  |  P: $pVal",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "K: $kVal  |  Ca: $caVal",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Mg: $mgVal  |  S: $sVal",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------
// 5. PAGINATION WIDGET (ส่วนปุ่มเปลี่ยนหน้า)
// -----------------------------------------------------------------
class SoilPaginationWidget extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPageChanged;

  const SoilPaginationWidget({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    pageButtons.add(
      _buildPageBtn(
        icon: Icons.chevron_left_rounded,
        disabled: currentPage == 1,
        onTap: () {
          if (currentPage > 1) onPageChanged(currentPage - 1);
        },
      ),
    );

    int range = 1;

    if (lastPage <= 5) {
      for (int i = 1; i <= lastPage; i++) {
        pageButtons.add(
          _buildPageBtn(
            text: i.toString(),
            isActive: currentPage == i,
            onTap: () {
              if (currentPage != i) onPageChanged(i);
            },
          ),
        );
      }
    } else {
      pageButtons.add(
        _buildPageBtn(
          text: "1",
          isActive: currentPage == 1,
          onTap: () {
            if (currentPage != 1) onPageChanged(1);
          },
        ),
      );

      if (currentPage > range + 2) {
        pageButtons.add(_buildDotsBtn());
      }

      int startPage = currentPage - range;
      int endPage = currentPage + range;

      if (startPage <= 1) startPage = 2;
      if (endPage >= lastPage) endPage = lastPage - 1;

      for (int i = startPage; i <= endPage; i++) {
        pageButtons.add(
          _buildPageBtn(
            text: i.toString(),
            isActive: currentPage == i,
            onTap: () {
              if (currentPage != i) onPageChanged(i);
            },
          ),
        );
      }

      if (currentPage < lastPage - range - 1) {
        pageButtons.add(_buildDotsBtn());
      }

      pageButtons.add(
        _buildPageBtn(
          text: lastPage.toString(),
          isActive: currentPage == lastPage,
          onTap: () {
            if (currentPage != lastPage) onPageChanged(lastPage);
          },
        ),
      );
    }

    pageButtons.add(
      _buildPageBtn(
        icon: Icons.chevron_right_rounded,
        disabled: currentPage == lastPage,
        onTap: () {
          if (currentPage < lastPage) onPageChanged(currentPage + 1);
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 28,
      height: 36,
      child: const Center(
        child: Text(
          "...",
          style: TextStyle(
            color: Colors.black45,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPageBtn({
    String? text,
    IconData? icon,
    bool isActive = false,
    bool disabled = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4A7C59)
              : (disabled ? Colors.black.withOpacity(0.04) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF4A7C59)
                : Colors.black.withOpacity(0.12),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A7C59).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: disabled ? Colors.black26 : Colors.black87,
                )
              : Text(
                  text!,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (disabled ? Colors.black26 : Colors.black87),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}