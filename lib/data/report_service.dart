import '../models/academic.dart';
import 'repository.dart';

/// Lọc theo tiến độ đào tạo.
enum ProgressFilter { all, onTrack, behind }

/// Lọc theo tình trạng nợ tín chỉ.
enum DebtFilter { all, hasDebt, noDebt }

/// Tiêu chí tổng hợp danh sách sinh viên. Tập rỗng = không lọc theo tiêu chí đó.
class ReportFilter {
  final Set<String> cohorts;
  final Set<int> years; // sinh viên năm thứ
  final Set<String> classes;
  final String? advisorId;

  /// Mức cảnh báo học vụ chính thức; [WarnLevel.none] = không bị cảnh báo.
  final Set<WarnLevel> academicLevels;
  final ProgressFilter progress;
  final DebtFilter debt;

  /// Chỉ lấy sinh viên có CPA nhỏ hơn giá trị này.
  final double? cpaBelow;

  /// Chỉ lấy sinh viên đã tích lũy đủ tín chỉ chương trình.
  final bool enoughCredits;

  const ReportFilter({
    this.cohorts = const {},
    this.years = const {},
    this.classes = const {},
    this.advisorId,
    this.academicLevels = const {},
    this.progress = ProgressFilter.all,
    this.debt = DebtFilter.all,
    this.cpaBelow,
    this.enoughCredits = false,
  });

  bool matches(StudentWithProgress d) {
    final s = d.student;
    final p = d.progress;
    if (cohorts.isNotEmpty && !cohorts.contains(s.cohort)) return false;
    if (years.isNotEmpty && !years.contains(p.yearOfStudy)) return false;
    if (classes.isNotEmpty && !classes.contains(s.className)) return false;
    if (advisorId != null && s.advisorId != advisorId) return false;
    if (academicLevels.isNotEmpty &&
        !academicLevels.contains(p.academicLevel)) {
      return false;
    }
    switch (progress) {
      case ProgressFilter.onTrack:
        if (p.behindSchedule) return false;
      case ProgressFilter.behind:
        if (!p.behindSchedule) return false;
      case ProgressFilter.all:
        break;
    }
    switch (debt) {
      case DebtFilter.hasDebt:
        if (p.debtCredits == 0) return false;
      case DebtFilter.noDebt:
        if (p.debtCredits > 0) return false;
      case DebtFilter.all:
        break;
    }
    if (cpaBelow != null && p.cpa >= cpaBelow!) return false;
    if (enoughCredits && p.remainingCredits > 0) return false;
    return true;
  }

  /// Mô tả tiêu chí bằng lời, dùng cho tiêu đề và phần "Tiêu chí" của file.
  /// [advisorName] tra tên cố vấn từ id.
  List<String> describe({String? Function(String id)? advisorName}) {
    String join<T>(Iterable<T> xs) => xs.join(', ');
    final out = <String>[];
    if (academicLevels.isNotEmpty) {
      final lv = academicLevels.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      final onlyNone = lv.length == 1 && lv.first == WarnLevel.none;
      out.add(onlyNone
          ? 'Không bị cảnh báo học vụ'
          : 'Cảnh báo học vụ: ${join(lv.map(levelText))}');
    }
    if (years.isNotEmpty) {
      out.add('Năm thứ ${join(years.toList()..sort())}');
    }
    if (cohorts.isNotEmpty) out.add('Khóa ${join(cohorts.toList()..sort())}');
    if (classes.isNotEmpty) out.add('Lớp ${join(classes.toList()..sort())}');
    if (advisorId != null) {
      out.add('CVHT: ${advisorName?.call(advisorId!) ?? advisorId}');
    }
    switch (progress) {
      case ProgressFilter.onTrack:
        out.add('Đúng tiến độ đào tạo');
      case ProgressFilter.behind:
        out.add('Chậm tiến độ đào tạo');
      case ProgressFilter.all:
        break;
    }
    switch (debt) {
      case DebtFilter.hasDebt:
        out.add('Đang nợ tín chỉ');
      case DebtFilter.noDebt:
        out.add('Không nợ tín chỉ');
      case DebtFilter.all:
        break;
    }
    if (cpaBelow != null) out.add('CPA < ${cpaBelow!.toStringAsFixed(2)}');
    if (enoughCredits) out.add('Đã tích lũy đủ tín chỉ chương trình');
    return out;
  }

  /// Tên mức cảnh báo học vụ dùng trong báo cáo.
  static String levelText(WarnLevel l) =>
      l == WarnLevel.none ? 'Không' : l.label;
}

/// Mẫu báo cáo có sẵn để người dùng chọn nhanh.
class ReportPreset {
  final String title;
  final ReportFilter filter;
  const ReportPreset(this.title, this.filter);

  static const all = ReportPreset('Tất cả sinh viên', ReportFilter());

  static const list = <ReportPreset>[
    all,
    ReportPreset('Cảnh báo học vụ lần 1',
        ReportFilter(academicLevels: {WarnLevel.low})),
    ReportPreset('Cảnh báo học vụ lần 2 liên tiếp',
        ReportFilter(academicLevels: {WarnLevel.medium})),
    ReportPreset('Thuộc diện buộc thôi học',
        ReportFilter(academicLevels: {WarnLevel.high})),
    ReportPreset(
        'Tất cả SV bị cảnh báo học vụ',
        ReportFilter(
            academicLevels: {WarnLevel.low, WarnLevel.medium, WarnLevel.high})),
    ReportPreset('Sinh viên năm 1', ReportFilter(years: {1})),
    ReportPreset('Sinh viên năm 2', ReportFilter(years: {2})),
    ReportPreset('Sinh viên năm 3', ReportFilter(years: {3})),
    ReportPreset('Sinh viên năm 4', ReportFilter(years: {4})),
    ReportPreset('Sinh viên năm 2 và 3', ReportFilter(years: {2, 3})),
    ReportPreset('Đúng tiến độ đào tạo',
        ReportFilter(progress: ProgressFilter.onTrack)),
    ReportPreset('Chậm tiến độ đào tạo',
        ReportFilter(progress: ProgressFilter.behind)),
    ReportPreset('Đang nợ tín chỉ', ReportFilter(debt: DebtFilter.hasDebt)),
    ReportPreset('CPA dưới 2.0', ReportFilter(cpaBelow: 2.0)),
    ReportPreset('Đủ tín chỉ xét tốt nghiệp',
        ReportFilter(enoughCredits: true)),
  ];
}

/// So sánh chuỗi theo bảng chữ cái tiếng Việt (a ă â b c d đ e ê …), không
/// phân biệt hoa thường; dấu thanh chỉ xét khi phần chữ giống nhau.
int vnCompare(String a, String b) {
  final ka = _vnKey(a), kb = _vnKey(b);
  final c = ka.$1.compareTo(kb.$1);
  return c != 0 ? c : ka.$2.compareTo(kb.$2);
}

const _vnAlphabet = 'aăâbcdđeêfghijklmnoôơpqrstuưvwxyz';

/// Mỗi nguyên âm gốc kèm 6 dạng thanh: ngang, huyền, hỏi, ngã, sắc, nặng.
const _vnToneForms = [
  'aàảãáạ', 'ăằẳẵắặ', 'âầẩẫấậ', 'eèẻẽéẹ', 'êềểễếệ', 'iìỉĩíị', //
  'oòỏõóọ', 'ôồổỗốộ', 'ơờởỡớợ', 'uùủũúụ', 'ưừửữứự', 'yỳỷỹýỵ',
];

final Map<String, (String, int)> _vnChars = () {
  final m = <String, (String, int)>{};
  for (final forms in _vnToneForms) {
    final base = forms[0];
    for (var t = 0; t < forms.length; t++) {
      m[forms[t]] = (base, t);
    }
  }
  return m;
}();

final _vnKeyCache = <String, (String, String)>{};

/// (khóa chữ cái, khóa dấu thanh) dùng để so sánh.
(String, String) _vnKey(String s) => _vnKeyCache.putIfAbsent(s, () {
      final letters = StringBuffer();
      final tones = StringBuffer();
      for (final ch in s.toLowerCase().split('')) {
        final (base, tone) = _vnChars[ch] ?? (ch, 0);
        final idx = _vnAlphabet.indexOf(base);
        // Chữ cái → mã theo thứ tự tiếng Việt, sau mọi chữ số/ký tự khác.
        letters.writeCharCode(idx >= 0 ? 0x1000 + idx : base.codeUnitAt(0));
        tones.write(tone);
      }
      return (letters.toString(), tones.toString());
    });

/// Người Việt sắp theo tên (từ cuối), rồi tới họ đệm.
int vnNameCompare(String a, String b) {
  String given(String n) => n.trim().split(RegExp(r'\s+')).last;
  final c = vnCompare(given(a), given(b));
  return c != 0 ? c : vnCompare(a, b);
}

/// Thứ tự sắp xếp danh sách: theo một cột, tăng hoặc giảm dần (như Excel).
class ReportOrder {
  final ReportColumn column;
  final bool ascending;
  const ReportOrder(this.column, {this.ascending = true});

  static const byCode = ReportOrder(ReportColumn.code);

  ReportOrder get reversed => ReportOrder(column, ascending: !ascending);

  int compare(StudentWithProgress a, StudentWithProgress b) {
    final c = column.compare(a, b);
    final byCode = a.student.studentCode.compareTo(b.student.studentCode);
    if (c != 0) return ascending ? c : -c;
    // Cùng giá trị thì giữ thứ tự MSSV tăng dần cho ổn định.
    return byCode;
  }

  String get label =>
      '${column.label} ${ascending ? column.ascLabel : column.descLabel}';
}

/// Một cột có thể đưa vào file xuất.
enum ReportColumn {
  stt('STT', 1, true),
  code('MSSV', 2, true),
  name('Họ và tên', 4.4, true),
  birthDate('Ngày sinh', 2, false),
  className('Lớp', 2, true),
  cohort('Khóa', 1.6, true),
  year('Năm thứ', 1.1, true),
  advisor('CVHT', 4, true),
  phone('Điện thoại', 2.2, false),
  email('Email', 3.5, false),
  cpa('CPA', 1.1, true),
  gpa('GPA kỳ gần nhất', 1.6, false),
  passed('TC tích lũy', 1.6, true),
  remaining('TC còn thiếu', 1.6, false),
  debt('TC nợ', 1.1, true),
  academicLevel('Cảnh báo HV', 1.6, true),
  progress('Tiến độ', 1.4, true),
  graduation('Xét tốt nghiệp', 1.8, false),
  graduationMissing('Còn thiếu để tốt nghiệp', 5, false),
  notes('Ghi chú', 4.4, true);

  const ReportColumn(this.label, this.weight, this.defaultOn);
  final String label;

  /// Độ rộng tương đối (dùng cho PDF và độ rộng cột Excel).
  final double weight;
  final bool defaultOn;

  static Set<ReportColumn> get defaults =>
      {for (final c in values) if (c.defaultOn) c};

  static List<ReportColumn> get defaultList =>
      [for (final c in values) if (c.defaultOn) c];

  /// Giá trị của ô: `int`, `double`, `String` hoặc `null` (ô trống).
  Object? valueOf(StudentWithProgress d, int index) {
    final s = d.student;
    final p = d.progress;
    switch (this) {
      case ReportColumn.stt:
        return index + 1;
      case ReportColumn.code:
        return s.studentCode;
      case ReportColumn.name:
        return s.fullName;
      case ReportColumn.birthDate:
        return s.birthDate;
      case ReportColumn.className:
        return s.className;
      case ReportColumn.cohort:
        return s.cohort;
      case ReportColumn.year:
        return p.yearOfStudy;
      case ReportColumn.advisor:
        return s.advisorName;
      case ReportColumn.phone:
        return s.phone;
      case ReportColumn.email:
        return s.email;
      case ReportColumn.cpa:
        return _round2(p.cpa);
      case ReportColumn.gpa:
        return _round2(p.latestGpa);
      case ReportColumn.passed:
        return p.passedCredits;
      case ReportColumn.remaining:
        return p.remainingCredits;
      case ReportColumn.debt:
        return p.debtCredits;
      case ReportColumn.academicLevel:
        return ReportFilter.levelText(p.academicLevel);
      case ReportColumn.progress:
        return p.behindSchedule ? 'Chậm' : 'Đúng';
      case ReportColumn.graduation:
        return d.graduation.eligible ? 'Đủ điều kiện' : 'Chưa đủ';
      case ReportColumn.graduationMissing:
        final m = d.graduation.missingSummary;
        return m.isEmpty ? null : m;
      case ReportColumn.notes:
        // Các cảnh báo khác ngoài cảnh báo học vụ chính thức (đã có cột riêng).
        final notes = [
          for (final w in p.warnings)
            if (!w.official) w.title,
        ];
        return notes.isEmpty ? null : notes.join('; ');
    }
  }

  /// Giá trị dạng chuỗi để hiển thị (PDF, bảng xem trước).
  String textOf(StudentWithProgress d, int index) {
    final v = valueOf(d, index);
    if (v == null) return '';
    if (v is double) return v.toStringAsFixed(2);
    return '$v';
  }

  /// So sánh hai sinh viên theo cột này (tăng dần).
  int compare(StudentWithProgress a, StudentWithProgress b) {
    switch (this) {
      case ReportColumn.stt:
      case ReportColumn.code:
        return a.student.studentCode.compareTo(b.student.studentCode);
      case ReportColumn.name:
        return vnNameCompare(a.student.fullName, b.student.fullName);
      case ReportColumn.academicLevel:
        return a.progress.academicLevel.index
            .compareTo(b.progress.academicLevel.index);
      case ReportColumn.birthDate:
        return _dateKey(a.student.birthDate)
            .compareTo(_dateKey(b.student.birthDate));
      default:
        final va = valueOf(a, 0), vb = valueOf(b, 0);
        if (va == null || vb == null) {
          return va == null ? (vb == null ? 0 : 1) : -1; // ô trống xếp cuối
        }
        if (va is num && vb is num) return va.compareTo(vb);
        return vnCompare('$va', '$vb');
    }
  }

  /// Nhãn chiều sắp xếp kiểu Excel.
  String get ascLabel => numeric || this == ReportColumn.birthDate
      ? 'nhỏ → lớn'
      : this == ReportColumn.academicLevel
          ? 'nhẹ → nặng'
          : 'A → Z';
  String get descLabel => numeric || this == ReportColumn.birthDate
      ? 'lớn → nhỏ'
      : this == ReportColumn.academicLevel
          ? 'nặng → nhẹ'
          : 'Z → A';

  /// Ngày dạng dd/MM/yyyy → yyyyMMdd để so sánh; trống xếp cuối.
  static String _dateKey(String? d) {
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(d ?? '');
    if (m == null) return '~${d ?? ''}';
    return '${m[3]}${m[2]!.padLeft(2, '0')}${m[1]!.padLeft(2, '0')}';
  }

  /// Cột số căn phải.
  bool get numeric => const {
        ReportColumn.stt,
        ReportColumn.year,
        ReportColumn.cpa,
        ReportColumn.gpa,
        ReportColumn.passed,
        ReportColumn.remaining,
        ReportColumn.debt,
      }.contains(this);

  static double _round2(double v) => (v * 100).roundToDouble() / 100;
}

/// Toàn bộ nội dung một báo cáo sẵn sàng để xuất ra Excel / PDF.
class ReportData {
  final String title;
  final List<String> criteria;
  final List<ReportColumn> columns;
  final List<StudentWithProgress> rows;
  final String generatedBy;
  final DateTime generatedAt;

  ReportData({
    required this.title,
    required this.criteria,
    required this.columns,
    required this.rows,
    required this.generatedBy,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  /// Số sinh viên theo từng nhóm, dùng cho phần thống kê của báo cáo.
  Map<String, int> countBy(String Function(StudentWithProgress d) key) {
    final m = <String, int>{};
    for (final d in rows) {
      final k = key(d);
      m[k] = (m[k] ?? 0) + 1;
    }
    return Map.fromEntries(
        m.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}

/// Áp dụng bộ lọc + sắp xếp lên dữ liệu đã tải.
List<StudentWithProgress> applyReport(List<StudentWithProgress> data,
        ReportFilter filter, ReportOrder order) =>
    data.where(filter.matches).toList()..sort(order.compare);
