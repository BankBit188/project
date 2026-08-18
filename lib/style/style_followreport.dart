import 'package:flutter/material.dart';

/// -----------------------------------------------------------------
/// 1. FOLLOW REPORT THEME (โทนสีธรรมชาติละมุน ถนอมสายตา)
/// -----------------------------------------------------------------
class FollowReportTheme {
  static const Color bgGradientStart = Color(0xFFDCEAF1);
  static const Color bgGradientEnd = Color(0xFFD2E0C4);

  // สีโทนอุ่นละมุน ถนอมสายตา
  static const Color cardBg = Color(0xFFE3ECE1);        // สีเขียวซอฟต์พาสเทล
  static const Color modalBg = Color(0xFFE8EFE6);       // พื้นหลัง Modal โทนเขียวอุ่นละมุน
  static const Color primaryGreen = Color(0xFF4A7C59);
  static const Color darkGreen = Color(0xFF2E5A39);
  static const Color textColor = Color(0xFF212522);     // สีตัวอักษรเข้มพอดี

  static const BoxDecoration pageDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bgGradientStart, bgGradientEnd],
    ),
  );
}

/// -----------------------------------------------------------------
/// 2. HEADER WIDGET (พร้อมไอคอนข้างๆ ข้อความ "ติดตามปัญหา")
/// -----------------------------------------------------------------
class FollowReportHeaderWidget extends StatelessWidget {
  final VoidCallback onBackPressed;

  const FollowReportHeaderWidget({
    super.key,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 28, color: FollowReportTheme.textColor),
          onPressed: onBackPressed,
        ),
        const SizedBox(width: 8),
        const Text(
          "ติดตามปัญหา",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: FollowReportTheme.textColor,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.find_in_page_rounded, // ไอคอนติดตามปัญหา
          size: 28,
          color: FollowReportTheme.primaryGreen,
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------
/// 3. CARD TILE (พื้นหลังซอฟต์พาสเทล + กรอบสีดำชัดเจน)
/// -----------------------------------------------------------------
class FollowReportCardTile extends StatelessWidget {
  final String title;
  final String dateTimeStr;
  final String statusText;
  final Color statusColor;
  final VoidCallback onTap;

  const FollowReportCardTile({
    super.key,
    required this.title,
    required this.dateTimeStr,
    required this.statusText,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: FollowReportTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black54, // 👈 กรอบสีดำตามต้องการ
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                          color: FollowReportTheme.textColor,
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      "สถานะ: ",
                      style: TextStyle(color: FollowReportTheme.textColor, fontSize: 14),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right,
                      color: FollowReportTheme.textColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 4. PAGINATION BAR WIDGET (ธีมตรงตามแอป)
/// -----------------------------------------------------------------
class FollowReportPaginationBar extends StatelessWidget {
  final int currentPage;
  final int lastPage;
  final Function(int) onPageSelected;

  const FollowReportPaginationBar({
    super.key,
    required this.currentPage,
    required this.lastPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (lastPage <= 1) return const SizedBox.shrink();

    List<Widget> pageButtons = [];

    pageButtons.add(
      _buildPageBtn(
        "<",
        disabled: currentPage == 1,
        onTap: () => onPageSelected(currentPage - 1),
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
            onTap: () => onPageSelected(i),
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
        onTap: () => onPageSelected(currentPage + 1),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: pageButtons,
          ),
        ),
      ),
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
              ? FollowReportTheme.primaryGreen
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
                  : (disabled ? Colors.grey : Colors.black87),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}