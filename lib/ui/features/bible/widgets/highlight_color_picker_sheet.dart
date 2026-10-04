import 'package:flutter/material.dart';
import '../../../../domain/models/bible_highlight_color.dart';

class HighlightColorPickerSheet extends StatelessWidget {
  final String? currentColor;
  final ValueChanged<String?> onColorSelected;

  const HighlightColorPickerSheet({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.palette_outlined, size: 20, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Highlight Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    onColorSelected(null);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.format_color_reset_rounded,
                      size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Color Swatches Row (Includes explicit "Remove Highlight" button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // "Remove / None" option
                GestureDetector(
                  onTap: () {
                    onColorSelected(null);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: currentColor == null
                                ? Colors.redAccent
                                : (isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFFCBD5E1)),
                            width: currentColor == null ? 2.5 : 1.5,
                          ),
                        ),
                        child: const Icon(Icons.format_color_reset_rounded,
                            size: 20, color: Colors.redAccent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'None',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: currentColor == null
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Preset Colors
                ...BibleHighlightColor.allColors.map((colorKey) {
                  final accentColor =
                      BibleHighlightColor.getAccentColor(colorKey);
                  final label = BibleHighlightColor.getLabel(colorKey);
                  final isSelected = currentColor?.toLowerCase() == colorKey;

                  return GestureDetector(
                    onTap: () {
                      // Toggle off if clicking the currently selected color!
                      if (isSelected) {
                        onColorSelected(null);
                      } else {
                        onColorSelected(colorKey);
                      }
                      Navigator.pop(context);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 48 : 42,
                          height: isSelected ? 48 : 42,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    width: 3)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.4),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? primaryBlue
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
