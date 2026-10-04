import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/models/bible_verse.dart';

class ScriptureShareSheet extends StatelessWidget {
  final String book;
  final int chapter;
  final List<BibleVerse> selectedVerses;
  final String translation;

  const ScriptureShareSheet({
    super.key,
    required this.book,
    required this.chapter,
    required this.selectedVerses,
    this.translation = 'KJV',
  });

  String get referenceLabel {
    if (selectedVerses.isEmpty) return '$book $chapter';
    final sorted = selectedVerses.map((v) => v.verseNumber).toList()..sort();
    if (sorted.length == 1) {
      return '$book $chapter:${sorted.first} ($translation)';
    }
    final ranges = <String>[];
    int start = sorted.first;
    int end = start;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == end + 1) {
        end = sorted[i];
      } else {
        ranges.add(start == end ? '$start' : '$start-$end');
        start = sorted[i];
        end = start;
      }
    }
    ranges.add(start == end ? '$start' : '$start-$end');
    return '$book $chapter:${ranges.join(', ')} ($translation)';
  }

  String get verseBody {
    return selectedVerses
        .map((v) => selectedVerses.length > 1 ? '${v.verseNumber}. ${v.text}' : v.text)
        .join('\n\n');
  }

  String buildStandardShareText() {
    return '📖 *$referenceLabel*\n\n"$verseBody"\n\nShared via GraceGrid ✝️';
  }

  String buildWhatsAppStatusText() {
    return '✨ *Verse of the Day*\n\n"$verseBody"\n— *$referenceLabel*\n\n#GraceGrid #Scripture #BibleVerse ✝️';
  }

  Future<void> _shareToWhatsApp(BuildContext context, {bool isStatus = false}) async {
    final text = isStatus ? buildWhatsAppStatusText() : buildStandardShareText();
    final encodedText = Uri.encodeComponent(text);
    final whatsappAppUri = Uri.parse('whatsapp://send?text=$encodedText');
    final whatsappWebUri = Uri.parse('https://api.whatsapp.com/send?text=$encodedText');

    try {
      if (await canLaunchUrl(whatsappAppUri)) {
        await launchUrl(whatsappAppUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(whatsappWebUri)) {
        await launchUrl(whatsappWebUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to system share
        // ignore: deprecated_member_use
        await Share.share(text, subject: referenceLabel);
      }
    } catch (_) {
      // Fallback to system share if deep link fails
      // ignore: deprecated_member_use
      await Share.share(text, subject: referenceLabel);
    }
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _shareToSystem(BuildContext context) async {
    final text = buildStandardShareText();
    // ignore: deprecated_member_use
    await Share.share(text, subject: referenceLabel);
    if (context.mounted) Navigator.pop(context);
  }

  void _copyToClipboard(BuildContext context) {
    final text = buildStandardShareText();
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied $referenceLabel to clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final whatsappColor = const Color(0xFF25D366);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
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

            // Title
            Row(
              children: [
                Icon(Icons.share_outlined, size: 20, color: primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Share Scripture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scripture Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryBlue.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.format_quote_rounded, size: 22, color: primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        referenceLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verseBody,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Share Options',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),

            // Share Action Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // WhatsApp Chat Option
                _ShareOptionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  customColor: whatsappColor,
                  label: 'WhatsApp',
                  subtitle: 'Send to Chat',
                  isDark: isDark,
                  onTap: () => _shareToWhatsApp(context, isStatus: false),
                ),

                // WhatsApp Status Option
                _ShareOptionTile(
                  icon: Icons.camera_alt_outlined,
                  customColor: whatsappColor,
                  label: 'WA Status',
                  subtitle: 'Share Story',
                  isDark: isDark,
                  onTap: () => _shareToWhatsApp(context, isStatus: true),
                ),

                // System Share Option
                _ShareOptionTile(
                  icon: Icons.ios_share_rounded,
                  customColor: primaryBlue,
                  label: 'Other Apps',
                  subtitle: 'System Share',
                  isDark: isDark,
                  onTap: () => _shareToSystem(context),
                ),

                // Copy Text Option
                _ShareOptionTile(
                  icon: Icons.copy_rounded,
                  customColor: isDark ? const Color(0xFFA855F7) : const Color(0xFF9333EA),
                  label: 'Copy',
                  subtitle: 'To Clipboard',
                  isDark: isDark,
                  onTap: () => _copyToClipboard(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final Color customColor;
  final String label;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.customColor,
    required this.label,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: customColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: customColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 24, color: customColor),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
