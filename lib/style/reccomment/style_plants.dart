import 'package:flutter/material.dart';
import 'package:project/modal/plant_detail.dart';

// -----------------------------------------------------------------
// 1. HEADER WIDGET (ส่วนหัวข้อ + ปุ่มย้อนกลับ)
// -----------------------------------------------------------------
class PlantHeaderWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const PlantHeaderWidget({super.key, required this.onBackPressed});

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
        const SizedBox(width: 14),
        const Text(
          "พืชปลูก",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.eco_rounded, color: Color(0xFF4A7C59), size: 28),
      ],
    );
  }
}

// -----------------------------------------------------------------
// 2. SEARCH & FILTER ROW (ช่องค้นหา + ปุ่มฟิลเตอร์สไตล์โมเดิร์น)
// -----------------------------------------------------------------
class PlantSearchFilterWidget extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onFilterSelected;

  const PlantSearchFilterWidget({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
  });

  String _getFilterLabel(String value) {
    switch (value) {
      case '1':
        return 'พืชไร่';
      case '2':
        return 'พืชสวน';
      case '3':
        return 'พืชเศรษฐกิจ';
      default:
        return 'ทั้งหมด';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFiltered = selectedFilter != 'all';

    return Row(
      children: [
        // ช่องค้นหาแบบ Neumorphic Glass
        Expanded(
          child: Container(
            height: 52,
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
                      hintText: 'ค้นหาชื่อพืช หรือชื่ออื่นๆ...',
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
          ),
        ),

        const SizedBox(width: 10),

        // ปุ่มฟิลเตอร์ พร้อม Badge ตัวกรอง
        PopupMenuButton<String>(
          onSelected: onFilterSelected,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          elevation: 6,
          tooltip: 'กรองประเภทพืช',
          itemBuilder: (context) => [
            _buildMenuItem('all', 'พืชทั้งหมด', Icons.grid_view_rounded),
            _buildMenuItem('1', 'พืชไร่', Icons.agriculture_rounded),
            _buildMenuItem('2', 'พืชสวน', Icons.park_rounded),
            _buildMenuItem('3', 'พืชเศรษฐกิจ', Icons.monetization_on_rounded),
          ],
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isFiltered ? const Color(0xFF4A7C59) : const Color(0xFFF0EAE1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFiltered ? const Color(0xFF386144) : Colors.black.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isFiltered
                      ? const Color(0xFF4A7C59).withOpacity(0.3)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  isFiltered ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                  size: 22,
                  color: isFiltered ? Colors.white : Colors.black87,
                ),
                if (isFiltered) ...[
                  const SizedBox(width: 6),
                  Text(
                    _getFilterLabel(selectedFilter),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, String title, IconData icon) {
    final bool isSelected = selectedFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? const Color(0xFF4A7C59) : Colors.grey.shade700,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF4A7C59) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// 3. ITEM CARD (คงรูปแบบตามเดิม)
// -----------------------------------------------------------------
class PlantItemCard extends StatelessWidget {
  final String title;
  final String? otherName;
  final String imgUrl;
  final VoidCallback onTap;

  const PlantItemCard({
    super.key,
    required this.title,
    this.otherName,
    required this.imgUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formattedImgUrl = PlantDetailDialog.formatImgUrl(imgUrl);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                      cacheHeight: 300,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 100,
                          height: 100,
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 100,
                      height: 100,
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
                    'ชื่อพืช : $title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 💡 แก้ไขจาก otherName.trim() เป็น otherName?.trim().isNotEmpty ?? false
                  if (otherName?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text(
                      'ชื่ออื่นๆ : $otherName',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
// 4. PAGINATION WIDGET (ปรับสไตล์ปุ่มเปลี่ยนหน้าให้ดูพรีเมียม)
// -----------------------------------------------------------------
class PlantPaginationWidget extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final ValueChanged<int> onPageChanged;

  const PlantPaginationWidget({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    // ปุ่ม ย้อนกลับ (<)
    pageButtons.add(
      _buildPageBtn(
        icon: Icons.chevron_left_rounded,
        disabled: currentPage == 1,
        onTap: () {
          if (currentPage > 1) onPageChanged(currentPage - 1);
        },
      ),
    );

    bool showLeftDots = false;
    bool showRightDots = false;

    for (int i = 1; i <= lastPage; i++) {
      if (i == 1 || i == lastPage || (i - currentPage).abs() <= 1) {
        pageButtons.add(
          _buildPageBtn(
            text: i.toString(),
            isActive: currentPage == i,
            onTap: () {
              if (currentPage != i) onPageChanged(i);
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

    // ปุ่ม ถัดไป (>)
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
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