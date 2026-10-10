/// The three semesters in the school's academic year. Students must re-submit
/// enrollment proof at the start of each one.
enum Semester { first, second, third }

extension SemesterX on Semester {
  String get label {
    switch (this) {
      case Semester.first:
        return '1st Semester';
      case Semester.second:
        return '2nd Semester';
      case Semester.third:
        return '3rd Semester';
    }
  }
}

/// An admin-published drive requiring all students to re-submit their
/// enrollment proof for a given semester.
class VerificationDrive {
  final String id;
  final Semester semester;
  final String schoolYear;
  final String message;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;

  VerificationDrive({
    required this.id,
    required this.semester,
    required this.schoolYear,
    required this.message,
    required this.createdById,
    required this.createdByName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get title => '$schoolYear · ${semester.label} enrollment verification';
}
