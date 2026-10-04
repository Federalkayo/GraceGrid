import 'package:flutter/material.dart';

class ReaderSettingsSheet extends StatefulWidget {
  final double currentFontSize;
  final ValueChanged<double> onFontSizeChanged;

  const ReaderSettingsSheet({
    super.key,
    required this.currentFontSize,
    required this.onFontSizeChanged,
  });

  @override
  State<ReaderSettingsSheet> createState() => _ReaderSettingsSheetState();
}

class _ReaderSettingsSheetState extends State<ReaderSettingsSheet> {
  late double _fontSize;

  @override
  void initState() {
    super.initState();
    _fontSize = widget.currentFontSize;
  }

  void _updateFontSize(double val) {
    final clamped = val.clamp(13.0, 26.0);
    setState(() => _fontSize = clamped);
    widget.onFontSizeChanged(clamped);
  }

  String _getPresetLabel(double size) {
    if (size <= 14.0) return 'Small';
    if (size <= 17.0) return 'Medium';
    if (size <= 20.0) return 'Large';
    return 'Extra Large';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue =
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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

            // Header Title
            Row(
              children: [
                Icon(Icons.format_size_rounded, size: 22, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Reader Text Size',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_fontSize.toInt()} px (${_getPresetLabel(_fontSize)})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Font Size Slider with A- / A+ Step Buttons
            Row(
              children: [
                IconButton(
                  onPressed: () => _updateFontSize(_fontSize - 1.0),
                  icon: const Text('A-',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  tooltip: 'Decrease Font Size',
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: primaryBlue,
                      inactiveTrackColor: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                      thumbColor: primaryBlue,
                      overlayColor: primaryBlue.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _fontSize,
                      min: 13.0,
                      max: 26.0,
                      divisions: 13,
                      onChanged: _updateFontSize,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _updateFontSize(_fontSize + 1.0),
                  icon: const Text('A+',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  color: primaryBlue,
                  tooltip: 'Increase Font Size',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Preset Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PresetPill(
                  label: 'Small',
                  size: 14.0,
                  currentSize: _fontSize,
                  isDark: isDark,
                  primaryColor: primaryBlue,
                  onTap: () => _updateFontSize(14.0),
                ),
                _PresetPill(
                  label: 'Medium',
                  size: 16.0,
                  currentSize: _fontSize,
                  isDark: isDark,
                  primaryColor: primaryBlue,
                  onTap: () => _updateFontSize(16.0),
                ),
                _PresetPill(
                  label: 'Large',
                  size: 19.0,
                  currentSize: _fontSize,
                  isDark: isDark,
                  primaryColor: primaryBlue,
                  onTap: () => _updateFontSize(19.0),
                ),
                _PresetPill(
                  label: 'X-Large',
                  size: 22.0,
                  currentSize: _fontSize,
                  isDark: isDark,
                  primaryColor: primaryBlue,
                  onTap: () => _updateFontSize(22.0),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Text Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'For God so loved the world, that he gave his only begotten Son...',
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.6,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PresetPill extends StatelessWidget {
  final String label;
  final double size;
  final double currentSize;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const _PresetPill({
    required this.label,
    required this.size,
    required this.currentSize,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = (currentSize - size).abs() < 0.8;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: primaryColor, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
