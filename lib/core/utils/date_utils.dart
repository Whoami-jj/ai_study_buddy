/// Small date helpers used across the app.
class AppDateUtils {
  AppDateUtils._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// The date with the time removed.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// A sortable key for one calendar day, e.g. `2026-03-09`.
  static String dayKey(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  /// Whole calendar days from [from] to [to] (negative if [to] is earlier).
  static int daysBetween(DateTime from, DateTime to) =>
      dateOnly(to).difference(dateOnly(from)).inDays;

  /// "Good morning", "Good afternoon" or "Good evening".
  static String greeting(DateTime now) {
    if (now.hour < 12) return 'Good morning';
    if (now.hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  /// One letter for the weekday: M T W T F S S.
  static String weekdayLetter(DateTime d) => _weekdayLetters[d.weekday - 1];

  /// e.g. `9 Mar` or `9 Mar 2025` when the year differs from this year.
  static String shortDate(DateTime d) {
    final sameYear = d.year == DateTime.now().year;
    final base = '${d.day} ${_months[d.month - 1]}';
    return sameYear ? base : '$base ${d.year}';
  }

  /// When a card is next due: "Due now", "Due tomorrow", "Due in 5 days".
  static String dueLabel(DateTime due) {
    final days = daysBetween(DateTime.now(), due);
    if (!due.isAfter(DateTime.now())) return 'Due now';
    if (days <= 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days < 30) return 'Due in $days days';
    return 'Due ${shortDate(due)}';
  }

  /// How long ago something happened: "today", "yesterday", "3 days ago".
  static String relativeDay(DateTime d) {
    final days = daysBetween(d, DateTime.now());
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    return 'on ${shortDate(d)}';
  }
}
