import 'package:flutter/material.dart';
import '../../../../domain/models/bible_book.dart';
import '../../../../data/services/bible_data_service.dart';

class ScriptureSelectorPage extends StatefulWidget {
  final String initialBook;
  final int initialChapter;
  final int initialVerse;
  final String selectedTranslation;
  final Function(String book, int chapter, int verse) onSelectLocation;

  const ScriptureSelectorPage({
    super.key,
    required this.initialBook,
    required this.initialChapter,
    required this.initialVerse,
    this.selectedTranslation = 'KJV',
    required this.onSelectLocation,
  });

  @override
  State<ScriptureSelectorPage> createState() => _ScriptureSelectorPageState();
}

class _ScriptureSelectorPageState extends State<ScriptureSelectorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedBookName;
  late int _selectedChapter;
  late int _selectedVerse;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Async verse count cache.
  int? _verseCount;
  bool _isLoadingVerseCount = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedBookName = widget.initialBook;
    _selectedChapter = widget.initialChapter;
    _selectedVerse = widget.initialVerse;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  BibleBook get _currentBook => BibleDataService.findBook(_selectedBookName);

  Future<void> _loadVerseCount() async {
    if (_isLoadingVerseCount) return;
    setState(() => _isLoadingVerseCount = true);
    final count = await BibleDataService.getVerseCount(
      _selectedBookName,
      _selectedChapter,
      translation: widget.selectedTranslation,
    );
    if (mounted) {
      setState(() {
        _verseCount = count;
        _isLoadingVerseCount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFFFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header title & close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Scripture Navigation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // 3-Segment Tab Bar (Books | Chapter | Verse)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'Books'),
                Tab(text: 'Chapter'),
                Tab(text: 'Verse'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Segment Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBooksSegment(context, isDark, primaryBlue),
                _buildChaptersSegment(context, isDark, primaryBlue),
                _buildVersesSegment(context, isDark, primaryBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. BOOKS SEGMENT
  Widget _buildBooksSegment(BuildContext context, bool isDark, Color primaryBlue) {
    final allOtBooks = BibleDataService.oldTestamentBooks;
    final allNtBooks = BibleDataService.newTestamentBooks;

    final otBooks = _searchQuery.isEmpty
        ? allOtBooks
        : allOtBooks.where((b) => b.name.toLowerCase().contains(_searchQuery)).toList();
    final ntBooks = _searchQuery.isEmpty
        ? allNtBooks
        : allNtBooks.where((b) => b.name.toLowerCase().contains(_searchQuery)).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'Search books...',
              hintStyle: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),

        // Old Testament Section
        if (otBooks.isNotEmpty) ...[
          _buildTestamentBanner(
            title: 'OLD TESTAMENT',
            subtitle: '39 Books • Law, History, Psalms & Prophets',
            icon: Icons.auto_stories_rounded,
            gradientColors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E3A8A),
            ],
            accentColor: const Color(0xFFFDE047),
            isDark: isDark,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: otBooks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              final book = otBooks[index];
              final isSelected = book.name == _selectedBookName;
              return _buildBookTile(book, isSelected, isDark, primaryBlue);
            },
          ),
          const SizedBox(height: 24),
        ],

        // New Testament Section
        if (ntBooks.isNotEmpty) ...[
          _buildTestamentBanner(
            title: 'NEW TESTAMENT',
            subtitle: '27 Books • Gospels, Acts, Epistles & Revelation',
            icon: Icons.menu_book_rounded,
            gradientColors: [
              const Color(0xFF1E3A8A),
              const Color(0xFF2563EB),
            ],
            accentColor: const Color(0xFF38BDF8),
            isDark: isDark,
            primaryBlue: primaryBlue,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ntBooks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (context, index) {
              final book = ntBooks[index];
              final isSelected = book.name == _selectedBookName;
              return _buildBookTile(book, isSelected, isDark, primaryBlue);
            },
          ),
        ],

        // Empty state when no results
        if (otBooks.isEmpty && ntBooks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 12),
                Text(
                  'No books found for "${_searchController.text}"',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTestamentBanner({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required Color accentColor,
    required bool isDark,
    required Color primaryBlue,
  }) {
    return Container(
      height: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Icon(icon, size: 22, color: accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookTile(BibleBook book, bool isSelected, bool isDark, Color primaryBlue) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBookName = book.name;
          _selectedChapter = 1;
          _selectedVerse = 1;
          _verseCount = null; // reset verse count cache
        });
        _tabController.animateTo(1); // Auto-advance to Chapter segment
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryBlue
              : (isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryBlue
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              book.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${book.chapterCount} Chapters • ${book.category}',
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white70
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // 2. CHAPTER SEGMENT
  Widget _buildChaptersSegment(BuildContext context, bool isDark, Color primaryBlue) {
    final book = _currentBook;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text(
              '${book.name} • Select Chapter',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Text(
              '${book.chapterCount} Total Chapters',
              style: TextStyle(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: book.chapterCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final chNum = index + 1;
            final isSelected = chNum == _selectedChapter;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedChapter = chNum;
                  _selectedVerse = 1;
                  _verseCount = null; // reset for new chapter
                });
                _loadVerseCount();
                _tabController.animateTo(2); // Auto-advance to Verse segment
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryBlue
                      : (isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? primaryBlue
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Center(
                  child: Text(
                    chNum < 10 ? '0$chNum' : '$chNum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // 3. VERSE SEGMENT
  Widget _buildVersesSegment(BuildContext context, bool isDark, Color primaryBlue) {
    // Load verse count lazily when this tab is shown.
    if (_verseCount == null && !_isLoadingVerseCount) {
      // Schedule after build to avoid setState-in-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVerseCount();
      });
    }

    final count = _verseCount ?? 0;

    if (_isLoadingVerseCount && _verseCount == null) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text(
              '$_selectedBookName $_selectedChapter • Select Verse',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Text(
              '$count Total Verses',
              style: TextStyle(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final vNum = index + 1;
            final isSelected = vNum == _selectedVerse;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedVerse = vNum);
                Navigator.of(context).pop();
                widget.onSelectLocation(_selectedBookName, _selectedChapter, vNum);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryBlue
                      : (isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? primaryBlue
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Center(
                  child: Text(
                    vNum < 10 ? '0$vNum' : '$vNum',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
