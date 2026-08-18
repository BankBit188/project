import 'package:flutter/material.dart';

// -----------------------------------------------------------------
// 1. HEADER WIDGET (แก้ Right Overflowed ด้วย Expanded + Ellipsis)
// -----------------------------------------------------------------
class ChatHeaderWidget extends StatelessWidget {
  final int currentUsage;
  final int maxDailyLimit;

  const ChatHeaderWidget({
    super.key,
    required this.currentUsage,
    required this.maxDailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    bool isQuotaExhausted = currentUsage >= maxDailyLimit;

    return Row(
      children: [
        // 🟢 ใช้ Expanded ฝั่งซ้ายเพื่อบีบข้อความให้อยู่ในพื้นที่ที่เหลือ ไม่ดันฝั่งขวาจนล้น
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A7C59).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF4A7C59),
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              // 🟢 ตัดข้อความถ้ายาวเกินไปป้องกัน Overflow
              const Expanded(
                child: Text(
                  "แชตบอตเกษตร",
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
            ],
          ),
        ),
        const SizedBox(width: 8),
        // ปุ่มแสดงโควตา
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isQuotaExhausted
                ? Colors.red.shade50
                : const Color(0xFF4A7C59).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isQuotaExhausted
                  ? Colors.red.shade300
                  : const Color(0xFF4A7C59).withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isQuotaExhausted
                    ? Icons.error_outline_rounded
                    : Icons.bolt_rounded,
                size: 15,
                color: isQuotaExhausted
                    ? Colors.red.shade700
                    : const Color(0xFF2E5A39),
              ),
              const SizedBox(width: 4),
              Text(
                "โควตา: $currentUsage / $maxDailyLimit",
                style: TextStyle(
                  fontSize: 12,
                  color: isQuotaExhausted
                      ? Colors.red.shade800
                      : const Color(0xFF2E5A39),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// 2. MESSAGE BUBBLE WIDGET (แก้ Overflow โดยให้ Flexible จัดการพื้นที่)
// -----------------------------------------------------------------
class ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4A7C59),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
          // 🟢 Flexible ยืดหยุ่นตามความยาวข้อความและไม่ล้นขอบจอแน่นอน
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF4A7C59)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.black.withOpacity(0.08),
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(left: 8, top: 2),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF915C22),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// 3. LOADING INDICATOR WIDGET
// -----------------------------------------------------------------
class ChatLoadingWidget extends StatelessWidget {
  const ChatLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF4A7C59),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4A7C59),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "ผู้ช่วยกำลังคิดคำตอบ...",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// 4. INPUT BAR WIDGET
// -----------------------------------------------------------------
class ChatInputBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool isDisabled;
  final bool isLoading;
  final VoidCallback onSend;

  const ChatInputBarWidget({
    super.key,
    required this.controller,
    required this.isDisabled,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    bool canSend = !isDisabled && !isLoading;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.black.withOpacity(0.12),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              enabled: canSend,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                hintText: isDisabled
                    ? "โควตาการถามของวันนี้หมดแล้ว"
                    : "พิมพ์คำถามเกี่ยวกับการเกษตร...",
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
              onSubmitted: canSend ? (_) => onSend() : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: canSend
                ? const Color(0xFF4A7C59)
                : Colors.grey.shade400,
            shape: BoxShape.circle,
            boxShadow: canSend
                ? [
                    BoxShadow(
                      color: const Color(0xFF4A7C59).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: canSend ? onSend : null,
          ),
        ),
      ],
    );
  }
}