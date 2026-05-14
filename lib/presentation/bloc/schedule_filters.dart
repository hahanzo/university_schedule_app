class ActiveFilters {
  final String? teacher;
  final String? group;
  final String? subject;
  final String? time;

  ActiveFilters({this.teacher, this.group, this.subject, this.time});

  ActiveFilters copyWith({String? teacher, String? group, String? subject, String? time}) {
    return ActiveFilters(
      teacher: teacher ?? this.teacher,
      group: group ?? this.group,
      subject: subject ?? this.subject,
      time: time ?? this.time,
    );
  }
}