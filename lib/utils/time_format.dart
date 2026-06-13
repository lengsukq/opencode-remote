String formatRelativeTime(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
  if (diff.inDays < 1) return '${diff.inHours} 小时前';
  return '${diff.inDays} 天前';
}

String formatTime(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
