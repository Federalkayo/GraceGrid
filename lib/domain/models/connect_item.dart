class ConnectSummary {
  final int unreadMessagesCount;
  final int activeGroupsCount;
  final int missedCallsCount;
  final String latestMessageSender;
  final String latestMessagePreview;
  final String latestMessageTime;

  const ConnectSummary({
    required this.unreadMessagesCount,
    required this.activeGroupsCount,
    required this.missedCallsCount,
    required this.latestMessageSender,
    required this.latestMessagePreview,
    required this.latestMessageTime,
  });
}
