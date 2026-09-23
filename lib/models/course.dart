/// A course belonging to the training program (chương trình đào tạo).
class Course {
  final int id;
  final String code;
  final String name;
  final int credits;
  final bool mandatory; // true = bắt buộc, false = tự chọn
  final int plannedSemester; // kỳ dự kiến (kỳ đầu tiên nếu tổ chức nhiều kỳ)
  final String semesterText; // hiển thị gốc, vd "2-4", "1-8"
  final String block; // mã khối: I, II.1, II.2, ... V.3.1, V.4
  final String blockName; // tên khối kiến thức
  final int? direction; // 1/2/3 nếu thuộc hướng ngành V.3.x
  final bool conditional; // GDTC/GDQP/kỹ năng bổ trợ – không tính vào GPA/TC
  final bool oriented; // học phần tự chọn định hướng (đánh dấu *)
  final String? prerequisite;

  const Course({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.mandatory,
    required this.plannedSemester,
    required this.semesterText,
    required this.block,
    required this.blockName,
    this.direction,
    this.conditional = false,
    this.oriented = false,
    this.prerequisite,
  });

  String get typeLabel => mandatory ? 'Bắt buộc' : 'Tự chọn';

  factory Course.fromMap(Map<String, Object?> m) => Course(
        id: (m['id'] as num).toInt(),
        code: m['code'] as String,
        name: m['name'] as String,
        credits: (m['credits'] as num).toInt(),
        mandatory: _asBool(m['mandatory']),
        plannedSemester: (m['planned_semester'] as num).toInt(),
        semesterText: (m['semester_text'] as String?) ?? '',
        block: (m['block'] as String?) ?? '',
        blockName: (m['block_name'] as String?) ?? '',
        direction: (m['direction'] as num?)?.toInt(),
        conditional: _asBool(m['conditional']),
        oriented: _asBool(m['oriented']),
        prerequisite: m['prerequisite'] as String?,
      );

  static bool _asBool(Object? v) => v == true || v == 1 || v == '1' || v == 't';

  Map<String, Object?> toMap() => {
        'code': code,
        'name': name,
        'credits': credits,
        'mandatory': mandatory,
        'planned_semester': plannedSemester,
        'semester_text': semesterText,
        'block': block,
        'block_name': blockName,
        'direction': direction,
        'conditional': conditional,
        'oriented': oriented,
        'prerequisite': prerequisite,
      };
}
