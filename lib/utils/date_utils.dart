import 'package:intl/intl.dart';

class DateUtil {
  /// 格式化日期：2025年7月16日
  static String formatDate(DateTime date) {
    return DateFormat('yyyy年M月d日').format(date);
  }

  /// 格式化时间：14:30
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// 格式化日期时间：2025年7月16日 14:30
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  /// 友好的相对时间（"刚刚"、"5分钟前"、"2小时前"、"3天前"）
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 30) return '${diff.inDays}天前';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}个月前';
    return '${(diff.inDays / 365).floor()}年前';
  }

  /// 今日已写字数（用于统计）
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 格式化数字：1234 → 1,234
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// 获取星期几中文
  static String weekDayName(DateTime date) {
    const weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekDays[date.weekday - 1];
  }

  /// 获取当天日期键（用于存储键值）
  static String todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }
}
