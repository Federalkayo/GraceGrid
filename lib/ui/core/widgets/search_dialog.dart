import 'package:flutter/material.dart';

class SearchDialog extends StatefulWidget {
  final Function(String query, String category) onSelectResult;

  const SearchDialog({
    super.key,
    required this.onSelectResult,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Bible', 'Sermons', 'Community', 'Prayer'];

  final List<Map<String, String>> _mockResults = [
    {
      'title': 'John 3:16 - For God so loved the world...',
      'category': 'Bible',
      'subtitle': 'New International Version',
      'icon': '📖',
    },
    {
      'title': 'Walking in Grace & Unshakable Purpose',
      'category': 'Sermons',
      'subtitle': 'Pastor Michael Carter • Renewed Strength',
      'icon': '🎤',
    },
    {
      'title': 'Morning Prayer & Fellowship Live Broadcast',
      'category': 'Live Streams',
      'subtitle': 'Grace Cathedral Worship • 1.4k watching',
      'icon': '📹',
    },
    {
      'title': 'Reflecting on Psalm 46:1 today: God is our refuge...',
      'category': 'Community',
      'subtitle': 'Sarah Jenkins • 15m ago',
      'icon': '🏠',
    },
    {
      'title': 'Healing for my grandmother',
      'category': 'Prayer',
      'subtitle': 'Hannah Lee • 56 praying',
      'icon': '🙏',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final filteredResults = _mockResults.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      final matchesQuery = query.isEmpty || 
          item['title']!.toLowerCase().contains(query) || 
          item['subtitle']!.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 550, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                const Text(
                  'Search GraceGrid',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search scriptures, sermons, posts, prayers...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFFF59E0B),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFFF59E0B) : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick Results',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredResults.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching content found.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredResults.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filteredResults[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['icon']!,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          title: Text(
                            item['title']!,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${item['category']} • ${item['subtitle']}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onSelectResult(item['title']!, item['category']!);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
