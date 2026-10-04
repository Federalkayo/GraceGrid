class LiveStream {
  final String id;
  final String title;
  final String hostName;
  final String hostAvatarUrl;
  final String thumbnailUrl;
  final int viewerCount;
  final bool isLive;
  final String category;
  final String startedTime;

  const LiveStream({
    required this.id,
    required this.title,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.thumbnailUrl,
    required this.viewerCount,
    required this.isLive,
    required this.category,
    required this.startedTime,
  });
}
