import 'package:flutter/material.dart';

class ScriptureHeaderBar extends StatelessWidget {
  final String book;
  final int chapter;
  final int verse;
  final String translation;
  final List<String> translations;
  final VoidCallback onTapSelector;
  final ValueChanged<String> onChangeTranslation;
  final VoidCallback onPreviousChapter;
  final VoidCallback onNextChapter;
  final VoidCallback? onTapSavedVerses;
  final VoidCallback? onTapFontSize;

  const ScriptureHeaderBar({
    super.key,
    required this.book,
    required this.chapter,
    required this.verse,
    required this.translation,
    required this.translations,
    required this.onTapSelector,
    required this.onChangeTranslation,
    required this.onPreviousChapter,
    required this.onNextChapter,
    this.onTapSavedVerses,
    this.onTapFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    final effectiveValue =
        translations.contains(translation) ? translation : translations.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous Chapter Button
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            onPressed: onPreviousChapter,
            tooltip: 'Previous Chapter',
          ),

          const SizedBox(width: 2),

          // Tappable Scripture Location Pill
          Expanded(
            child: GestureDetector(
              onTap: onTapSelector,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '$book $chapter:$verse',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 2),

          // Next Chapter Button
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            onPressed: onNextChapter,
            tooltip: 'Next Chapter',
          ),

          // Font Size Button
          if (onTapFontSize != null)
            IconButton(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.format_size_rounded, size: 19),
              color: primaryBlue,
              onPressed: onTapFontSize,
              tooltip: 'Adjust Text Size',
            ),

          // Saved / Bookmarks Button
          if (onTapSavedVerses != null)
            IconButton(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.collections_bookmark_outlined, size: 19),
              color: primaryBlue,
              onPressed: onTapSavedVerses,
              tooltip: 'Saved Bookmarks & Highlights',
            ),

          const SizedBox(width: 2),

          // Translation Selector Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              value: effectiveValue,
              icon: Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Icon(Icons.tune_rounded, size: 15, color: primaryBlue),
              ),
              dropdownColor: isDark ? const Color(0xFF111827) : Colors.white,
              items: translations.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(
                    _translationLabel(t),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChangeTranslation(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _translationLabel(String code) {
    switch (code) {
      case 'KJV':
        return 'KJV';
      case 'ASV':
        return 'ASV';
      case 'YOR':
        return 'YOR';
      default:
        return code;
    }
  }
}
