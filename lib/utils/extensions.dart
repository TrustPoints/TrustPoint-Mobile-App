import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Get initials (first letter of first two words)
  String get initials {
    if (isEmpty) return '';
    final words = trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Get first name
  String get firstName {
    if (isEmpty) return '';
    return split(' ').first;
  }

  /// Check if string is valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Check if string is valid Indonesian phone
  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^(\+62|62|0)8[1-9][0-9]{7,11}$').hasMatch(cleaned);
  }

  /// Mask email (jo***@email.com)
  String get maskedEmail {
    if (!contains('@')) return this;
    final parts = split('@');
    final name = parts[0];
    if (name.length <= 2) return this;
    return '${name.substring(0, 2)}${'*' * (name.length - 2)}@${parts[1]}';
  }

  /// Truncate with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

extension IntExtension on int {
  /// Format as currency (Indonesian Rupiah)
  String toRupiah({bool withSymbol = true}) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    final formatted = formatter.format(this);
    return withSymbol ? 'Rp $formatted' : formatted;
  }

  /// Format as points
  String toPoints() {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(this);
  }

  /// Convert points to rupiah value
  int toRupiahValue({int rate = 100}) => this * rate;

  /// Format as compact number (1K, 1M, etc.)
  String toCompact() {
    if (this < 1000) return toString();
    if (this < 1000000) return '${(this / 1000).toStringAsFixed(1)}K';
    if (this < 1000000000) return '${(this / 1000000).toStringAsFixed(1)}M';
    return '${(this / 1000000000).toStringAsFixed(1)}B';
  }

  /// Format as ordinal (1st, 2nd, 3rd, etc.)
  String toOrdinal() {
    if (this % 100 >= 11 && this % 100 <= 13) return '${this}th';
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }
}

extension DoubleExtension on double {
  /// Format as currency (Indonesian Rupiah)
  String toRupiah({bool withSymbol = true}) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    final formatted = formatter.format(this);
    return withSymbol ? 'Rp $formatted' : formatted;
  }

  /// Format as distance (km or m)
  String toDistance() {
    if (this < 1) {
      return '${(this * 1000).toStringAsFixed(0)} m';
    }
    return '${toStringAsFixed(1)} km';
  }

  /// Format as rating (e.g., 4.5)
  String toRating() => toStringAsFixed(1);
}

extension DateTimeExtension on DateTime {
  /// Format as relative time (e.g., "2 hours ago")
  String toRelative() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} minggu lalu';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    }
  }

  /// Format as date string (e.g., "10 Feb 2026")
  String toDateString() {
    return DateFormat('d MMM yyyy', 'id_ID').format(this);
  }

  /// Format as time string (e.g., "14:30")
  String toTimeString() {
    return DateFormat('HH:mm').format(this);
  }

  /// Format as date and time (e.g., "10 Feb 2026, 14:30")
  String toDateTimeString() {
    return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(this);
  }

  /// Format as full date (e.g., "Senin, 10 Februari 2026")
  String toFullDateString() {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(this);
  }

  /// Check if same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if today
  bool get isToday => isSameDay(DateTime.now());

  /// Check if yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }
}

extension ContextExtension on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Get keyboard height
  double get keyboardHeight => MediaQuery.of(this).viewInsets.bottom;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => keyboardHeight > 0;

  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Show snackbar
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Pop navigation
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  /// Push navigation
  Future<T?> push<T>(Widget page) =>
      Navigator.of(this).push<T>(MaterialPageRoute(builder: (_) => page));

  /// Push replacement
  Future<T?> pushReplacement<T, TO>(Widget page) => Navigator.of(
    this,
  ).pushReplacement<T, TO>(MaterialPageRoute(builder: (_) => page));

  /// Push and remove all
  Future<T?> pushAndRemoveAll<T>(Widget page) =>
      Navigator.of(this).pushAndRemoveUntil<T>(
        MaterialPageRoute(builder: (_) => page),
        (route) => false,
      );
}

extension ListExtension<T> on List<T> {
  /// Get first or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Safe element at index
  T? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Separate with widget (for ListView)
  List<T> separatedBy(T separator) {
    if (length <= 1) return this;
    return [
      for (int i = 0; i < length; i++) ...[
        this[i],
        if (i < length - 1) separator,
      ],
    ];
  }
}

extension NullableStringExtension on String? {
  /// Return empty string if null
  String get orEmpty => this ?? '';

  /// Check if null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Check if not null and not empty
  bool get isNotNullOrEmpty => this != null && this!.isNotEmpty;
}
