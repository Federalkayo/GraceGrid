import 'package:flutter/material.dart';
import '../auth/auth_notifier.dart';
import '../../core/auth_gate.dart';
import '../../../data/services/prayer_service.dart';
import '../../../domain/models/prayer.dart';

class PrayerView extends StatefulWidget {
  final AuthNotifier authNotifier;

  const PrayerView({super.key, required this.authNotifier});

  @override
  State<PrayerView> createState() => _PrayerViewState();
}

class _PrayerViewState extends State<PrayerView> {
  final PrayerService _prayerService = PrayerService.instance;

  List<PrayerRequest> _wallPrayers = [];
  List<PrayerRequest> _myPrayers = [];
  bool _loadingWall = true;
  bool _loadingMy = true;
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = widget.authNotifier.userId;
    widget.authNotifier.addListener(_onAuthChanged);
    _loadWall();
    _loadMyRequests();
  }

  @override
  void dispose() {
    widget.authNotifier.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final currentUserId = widget.authNotifier.userId;
    if (currentUserId != _lastUserId) {
      _lastUserId = currentUserId;
      _loadWall();
      _loadMyRequests();
    }
  }

  Future<void> _loadWall() async {
    setState(() => _loadingWall = true);
    final prayers = await _prayerService.fetchPrayerWall();
    if (!mounted) return;
    setState(() {
      _wallPrayers = prayers;
      _loadingWall = false;
    });
  }

  Future<void> _loadMyRequests() async {
    setState(() => _loadingMy = true);
    final prayers = await _prayerService.fetchMyRequests();
    if (!mounted) return;
    setState(() {
      _myPrayers = prayers;
      _loadingMy = false;
    });
  }

  Future<void> _onTogglePray(int index) async {
    if (!await requireAuth(context, widget.authNotifier)) return;
    if (!mounted) return;

    final prayer = _wallPrayers[index];
    // Optimistic update
    setState(() {
      _wallPrayers[index] = prayer.copyWith(
        isPrayedByMe: !prayer.isPrayedByMe,
        prayingCount: prayer.isPrayedByMe
            ? prayer.prayingCount - 1
            : prayer.prayingCount + 1,
      );
    });

    final newCount = await _prayerService.togglePray(
      prayer.id,
      currentlyPrayed: prayer.isPrayedByMe,
    );

    if (!mounted) return;
    if (newCount != null) {
      setState(() {
        _wallPrayers[index] = _wallPrayers[index].copyWith(prayingCount: newCount);
      });
    } else {
      // Revert on failure
      setState(() => _wallPrayers[index] = prayer);
    }
  }

  Future<void> _onCreateRequest() async {
    if (!await requireAuth(context, widget.authNotifier)) return;
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePrayerSheet(isDark: isDark),
    );

    if (result == null) return;

    final newPrayer = await _prayerService.createRequest(
      title: result['title']!,
      requestText: result['text']!,
    );

    if (!mounted) return;
    if (newPrayer != null) {
      setState(() {
        _wallPrayers.insert(0, newPrayer);
        _myPrayers.insert(0, newPrayer);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit prayer request.')),
      );
    }
  }

  Future<void> _onDeleteRequest(int index, {required bool fromMyTab}) async {
    final prayer = fromMyTab ? _myPrayers[index] : _wallPrayers[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Prayer Request?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _prayerService.deleteRequest(prayer.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _wallPrayers.removeWhere((p) => p.id == prayer.id);
        _myPrayers.removeWhere((p) => p.id == prayer.id);
      });
    }
  }

  Future<void> _onMarkAnswered(int index) async {
    final prayer = _myPrayers[index];
    final ok = await _prayerService.markAnswered(prayer.id);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _myPrayers[index] = prayer.copyWith(isAnswered: true);
        final wallIdx = _wallPrayers.indexWhere((p) => p.id == prayer.id);
        if (wallIdx >= 0) {
          _wallPrayers[wallIdx] = _wallPrayers[wallIdx].copyWith(isAnswered: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prayer Center', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: primaryBlue,
            labelColor: primaryBlue,
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            tabs: const [
              Tab(text: 'Prayer Wall'),
              Tab(text: 'My Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Prayer Wall
            _loadingWall
                ? const Center(child: CircularProgressIndicator())
                : _wallPrayers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volunteer_activism, size: 48,
                                color: Colors.grey.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No prayer requests yet',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Be the first to share a prayer request',
                                style: TextStyle(fontSize: 13,
                                    color: Colors.grey.withValues(alpha: 0.7))),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWall,
                        color: primaryBlue,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _wallPrayers.length,
                          itemBuilder: (context, index) {
                            return _PrayerCard(
                              prayer: _wallPrayers[index],
                              primaryBlue: primaryBlue,
                              isDark: isDark,
                              isOwner: _wallPrayers[index].isOwnRequest(
                                  widget.authNotifier.userId),
                              onPray: () => _onTogglePray(index),
                              onDelete: () => _onDeleteRequest(index, fromMyTab: false),
                            );
                          },
                        ),
                      ),

            // My Requests
            !widget.authNotifier.isAuthenticated
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sign in to view your prayer requests'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            await requireAuth(context, widget.authNotifier);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  )
                : _loadingMy
                    ? const Center(child: CircularProgressIndicator())
                    : _myPrayers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('You have no prayer requests',
                                    style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _onCreateRequest,
                                  child: Text('Submit one now',
                                      style: TextStyle(color: primaryBlue,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMyRequests,
                            color: primaryBlue,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _myPrayers.length,
                              itemBuilder: (context, index) {
                                final prayer = _myPrayers[index];
                                return _MyPrayerCard(
                                  prayer: prayer,
                                  primaryBlue: primaryBlue,
                                  isDark: isDark,
                                  onDelete: () => _onDeleteRequest(index, fromMyTab: true),
                                  onMarkAnswered: () => _onMarkAnswered(index),
                                );
                              },
                            ),
                          ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _onCreateRequest,
          backgroundColor: primaryBlue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Request Prayer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Prayer Card (Wall) — same visual design as original
// ──────────────────────────────────────────────

class _PrayerCard extends StatelessWidget {
  final PrayerRequest prayer;
  final Color primaryBlue;
  final bool isDark;
  final bool isOwner;
  final VoidCallback onPray;
  final VoidCallback onDelete;

  const _PrayerCard({
    required this.prayer,
    required this.primaryBlue,
    required this.isDark,
    required this.isOwner,
    required this.onPray,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: primaryBlue.withValues(alpha: 0.15),
                backgroundImage: prayer.authorAvatar.isNotEmpty
                    ? NetworkImage(prayer.authorAvatar)
                    : null,
                child: prayer.authorAvatar.isEmpty
                    ? Text(
                        prayer.authorName.isNotEmpty
                            ? prayer.authorName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: primaryBlue, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(prayer.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text(prayer.timeAgo,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if (isOwner) ...[
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Color(0xFFEF4444))),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(prayer.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(prayer.requestText),
          if (prayer.isAnswered) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('🙏 Answered',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onPray,
                style: ElevatedButton.styleFrom(
                  backgroundColor: prayer.isPrayedByMe
                      ? primaryBlue
                      : primaryBlue.withValues(alpha: 0.15),
                  foregroundColor:
                      prayer.isPrayedByMe ? Colors.white : primaryBlue,
                  elevation: 0,
                ),
                icon: Icon(
                  prayer.isPrayedByMe
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 16,
                ),
                label: Text(
                  'Pray (${prayer.prayingCount})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// My Prayer Card (My Requests tab)
// ──────────────────────────────────────────────

class _MyPrayerCard extends StatelessWidget {
  final PrayerRequest prayer;
  final Color primaryBlue;
  final bool isDark;
  final VoidCallback onDelete;
  final VoidCallback onMarkAnswered;

  const _MyPrayerCard({
    required this.prayer,
    required this.primaryBlue,
    required this.isDark,
    required this.onDelete,
    required this.onMarkAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(prayer.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              if (prayer.isAnswered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Answered',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(prayer.requestText,
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.favorite, size: 14, color: primaryBlue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${prayer.prayingCount} people praying • ${prayer.timeAgo}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (!prayer.isAnswered)
                TextButton(
                  onPressed: onMarkAnswered,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mark Answered',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                padding: const EdgeInsets.only(left: 4),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFEF4444)),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Create Prayer Request Sheet
// ──────────────────────────────────────────────

class _CreatePrayerSheet extends StatefulWidget {
  final bool isDark;
  const _CreatePrayerSheet({required this.isDark});

  @override
  State<_CreatePrayerSheet> createState() => _CreatePrayerSheetState();
}

class _CreatePrayerSheetState extends State<_CreatePrayerSheet> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    void checkValid() {
      final canSubmit = _titleController.text.trim().isNotEmpty &&
          _textController.text.trim().isNotEmpty;
      if (canSubmit != _canSubmit) setState(() => _canSubmit = canSubmit);
    }
    _titleController.addListener(checkValid);
    _textController.addListener(checkValid);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Request Prayer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton(
                  onPressed: _canSubmit
                      ? () => Navigator.pop(context, {
                            'title': _titleController.text,
                            'text': _textController.text,
                          })
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Submit',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title field
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _titleController,
                autofocus: true,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Prayer title (e.g. "Healing for my family")',
                  hintStyle: TextStyle(
                      color: textSecondary.withValues(alpha: 0.6),
                      fontWeight: FontWeight.normal),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Request text field
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _textController,
                maxLines: 4,
                maxLength: 500,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Share your prayer request with the community...',
                  hintStyle:
                      TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                  counterStyle: TextStyle(color: textSecondary, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
