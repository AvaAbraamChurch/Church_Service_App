import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church/core/models/user/user_model.dart';

class BirthdayNotificationService {
  final FirebaseFirestore _firestore;

  BirthdayNotificationService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all children (students) whose birthday is in the current month
  Stream<List<UserModel>> getBirthdaysThisMonth() {
    final now = DateTime.now();
    final currentMonth = now.month;

    return _firestore
        .collection('users')
        .where('userType', whereIn: ['SS', 'CH']) // Sunday School or Child
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .where((user) {
        if (user.birthday == null) return false;
        return user.birthday!.month == currentMonth;
      }).toList();

      // Sort by day of month
      users.sort((a, b) => a.birthday!.day.compareTo(b.birthday!.day));
      return users;
    });
  }

  /// Get all children (students) whose birthday is in a specific month
  Stream<List<UserModel>> getBirthdaysByMonth(int month) {
    return _firestore
        .collection('users')
        .where('userType', whereIn: ['SS', 'CH']) // Sunday School or Child
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .where((user) {
        if (user.birthday == null) return false;
        return user.birthday!.month == month;
      }).toList();

      // Sort by day of month
      users.sort((a, b) => a.birthday!.day.compareTo(b.birthday!.day));
      return users;
    });
  }

  /// Get children with birthdays today
  Stream<List<UserModel>> getBirthdaysToday() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentDay = now.day;

    return _firestore
        .collection('users')
        .where('userType', whereIn: ['SS', 'CH'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .where((user) {
        if (user.birthday == null) return false;
        return user.birthday!.month == currentMonth &&
            user.birthday!.day == currentDay;
      }).toList();
    });
  }

  /// Get children with birthdays in the next N days
  Stream<List<UserModel>> getUpcomingBirthdays({int daysAhead = 7}) {
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: daysAhead));

    return _firestore
        .collection('users')
        .where('userType', whereIn: ['SS', 'CH'])
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), id: doc.id))
          .where((user) {
        if (user.birthday == null) return false;

        // Get birthday in current year
        final birthdayThisYear = DateTime(
          now.year,
          user.birthday!.month,
          user.birthday!.day,
        );

        // Check if birthday falls within the range
        return birthdayThisYear.isAfter(now.subtract(const Duration(days: 1))) &&
            birthdayThisYear.isBefore(futureDate.add(const Duration(days: 1)));
      }).toList();

      // Sort by date
      users.sort((a, b) {
        final dateA = DateTime(now.year, a.birthday!.month, a.birthday!.day);
        final dateB = DateTime(now.year, b.birthday!.month, b.birthday!.day);
        return dateA.compareTo(dateB);
      });

      return users;
    });
  }

  /// Calculate age from birthday
  int calculateAge(DateTime birthday) {
    final now = DateTime.now();
    int age = now.year - birthday.year;
    if (now.month < birthday.month ||
        (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  /// Get days until birthday
  int daysUntilBirthday(DateTime birthday) {
    final now = DateTime.now();
    final birthdayThisYear = DateTime(now.year, birthday.month, birthday.day);

    if (birthdayThisYear.isBefore(now)) {
      // Birthday already passed this year, calculate for next year
      final birthdayNextYear = DateTime(now.year + 1, birthday.month, birthday.day);
      return birthdayNextYear.difference(now).inDays;
    } else {
      return birthdayThisYear.difference(now).inDays;
    }
  }

  /// Check if birthday is today
  bool isBirthdayToday(DateTime birthday) {
    final now = DateTime.now();
    return birthday.month == now.month && birthday.day == now.day;
  }

  /// Format birthday for display (e.g., "15 يناير")
  String formatBirthdayArabic(DateTime birthday) {
    const arabicMonths = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${birthday.day} ${arabicMonths[birthday.month - 1]}';
  }
}

