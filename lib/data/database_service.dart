import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'curriculum_seed.dart';

/// Single access point to the SQLite database (SQL storage for the app).
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  Database get db => _db!;

  Future<void> init() async {
    if (_db != null) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'qlgd_edu.db');

    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) async {
          await _createSchema(db);
          await _seed(db);
        },
        onUpgrade: (db, _, _) async {
          await _dropAll(db);
          await _createSchema(db);
          await _seed(db);
        },
      ),
    );
  }

  Future<void> resetDatabase() async {
    await _dropAll(db);
    await _createSchema(db);
    await _seed(db);
  }

  Future<void> _dropAll(Database db) async {
    for (final t in [
      'change_requests',
      'enrollments',
      'students',
      'courses',
      'users',
      'settings',
      'audit_log'
    ]) {
      await db.execute('DROP TABLE IF EXISTS $t');
    }
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        username      TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        salt          TEXT NOT NULL,
        role          TEXT NOT NULL,
        full_name     TEXT NOT NULL,
        student_code  TEXT,
        active        INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        student_code TEXT UNIQUE NOT NULL,
        full_name    TEXT NOT NULL,
        cohort       TEXT NOT NULL,
        class_name   TEXT NOT NULL,
        major        TEXT NOT NULL,
        enroll_year  INTEGER NOT NULL,
        advisor_id   INTEGER,
        direction    INTEGER,
        status       TEXT NOT NULL DEFAULT 'active',
        phone        TEXT,
        birth_date   TEXT,
        hometown     TEXT,
        email        TEXT,
        FOREIGN KEY (advisor_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE courses (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        code             TEXT UNIQUE NOT NULL,
        name             TEXT NOT NULL,
        credits          INTEGER NOT NULL,
        mandatory        INTEGER NOT NULL,
        planned_semester INTEGER NOT NULL,
        semester_text    TEXT,
        block            TEXT NOT NULL,
        block_name       TEXT NOT NULL,
        direction        INTEGER,
        conditional      INTEGER NOT NULL DEFAULT 0,
        oriented         INTEGER NOT NULL DEFAULT 0,
        prerequisite     TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE enrollments (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id   INTEGER NOT NULL,
        course_id    INTEGER NOT NULL,
        term         TEXT NOT NULL,
        midterm      REAL,
        final_exam   REAL,
        grade10      REAL,
        grade_letter TEXT,
        grade4       REAL,
        status       TEXT NOT NULL,
        approval     TEXT NOT NULL DEFAULT 'approved',
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (course_id) REFERENCES courses(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE change_requests (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id    INTEGER NOT NULL,
        student_code  TEXT NOT NULL,
        field         TEXT NOT NULL,
        field_label   TEXT NOT NULL,
        old_value     TEXT,
        new_value     TEXT,
        requested_by  TEXT NOT NULL,
        requested_role TEXT NOT NULL,
        ts            TEXT NOT NULL,
        status        TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
    await db.execute('''
      CREATE TABLE audit_log (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        ts           TEXT NOT NULL,
        actor_name   TEXT NOT NULL,
        role         TEXT NOT NULL,
        action       TEXT NOT NULL,
        detail       TEXT NOT NULL,
        student_code TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_enroll_student ON enrollments(student_id)');
    await db.execute('CREATE INDEX idx_enroll_course ON enrollments(course_id)');
    await db.execute('CREATE INDEX idx_enroll_approval ON enrollments(approval)');
    await db.execute('CREATE INDEX idx_change_status ON change_requests(status)');
  }

  // ----------------------------------------------------------------------
  static const _salt = 'qlgd_static_salt_2026';
  static const accountSalt = _salt;
  static const defaultPassword = '123456';
  static const currentRegTerm = '20261';

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  Future<void> _seed(Database db) async {
    await db.transaction((txn) async {
      // ---- courses ----
      for (final c in CurriculumSeed.courses) {
        await txn.insert('courses', {
          'code': c[0],
          'name': c[1],
          'credits': c[2],
          'mandatory': c[3],
          'planned_semester': c[4],
          'semester_text': c[5],
          'block': c[6],
          'block_name': CurriculumSeed.blockNames[c[6]] ?? c[6],
          'direction': c[7],
          'conditional': c[8],
          'oriented': c[9],
          'prerequisite': null,
        });
      }

      Future<int> addUser(String username, String role, String name,
          {String? studentCode}) {
        return txn.insert('users', {
          'username': username,
          'password_hash': hashPassword('123456', _salt),
          'salt': _salt,
          'role': role,
          'full_name': name,
          'student_code': studentCode,
          'active': 1,
        });
      }

      await addUser('admin', 'admin', 'TS. Nguyễn Quốc Toàn (Quản trị)');
      await addUser('dean', 'dean', 'PGS.TS. Nguyễn Văn Khoa');
      await addUser('assistant', 'assistant', 'CN. Lê Thị Đào');
      final advisorNames = [
        'TS. Trần Quốc Việt',
        'TS. Phạm Thu Hà',
        'ThS. Hoàng Minh Đức',
        'ThS. Đỗ Thị Lan',
        'TS. Vũ Đình Nam',
      ];
      final advisorIds = <int>[];
      for (var i = 0; i < advisorNames.length; i++) {
        advisorIds.add(await addUser('advisor${i + 1}', 'advisor', advisorNames[i]));
      }

      // ---- course lookup ----
      final courseRows = await txn.query('courses');
      final courses = courseRows
          .map((r) => _CourseLite(
                r['id'] as int,
                r['code'] as String,
                r['credits'] as int,
                (r['mandatory'] as int) == 1,
                (r['conditional'] as int) == 1,
                r['planned_semester'] as int,
                r['block'] as String,
                r['direction'] as int?,
              ))
          .toList();

      final rng = Random(20260912);
      final now = DateTime(2026, 9, 1);
      final cohorts = <int, String>{
        2022: 'K2022',
        2023: 'K2023',
        2024: 'K2024',
        2025: 'K2025',
      };
      const perCohort = 125;

      final activeStudentCodes = <String>[];
      final createdStudents = <_StudentRef>[];

      for (final entry in cohorts.entries) {
        final year = entry.key;
        final cohort = entry.value;
        for (var i = 0; i < perCohort; i++) {
          final code = '$year${(i + 1).toString().padLeft(4, '0')}';
          final className = 'QTTH ${(rng.nextInt(3) + 1).toString().padLeft(2, '0')}';
          final advisor = advisorIds[rng.nextInt(advisorIds.length)];
          final ability = _clamp(0.55 + _gauss(rng) * 0.22, 0.1, 0.98);
          final ref = await _createStudent(
            txn,
            rng: rng,
            courses: courses,
            code: code,
            fullName: _randomName(rng),
            enrollYear: year,
            cohort: cohort,
            className: className,
            advisorId: advisor,
            ability: ability,
            now: now,
          );
          createdStudents.add(ref);
          if (ref.status == 'active') activeStudentCodes.add(code);
        }
      }

      // ---- pick a random demo student login ----
      final demoCode = activeStudentCodes[rng.nextInt(activeStudentCodes.length)];
      final demoRef = createdStudents.firstWhere((s) => s.code == demoCode);
      await addUser(demoCode, 'student', demoRef.name, studentCode: demoCode);

      // ---- seed some current registrations (students register freely) ----
      for (final ref in createdStudents) {
        if (ref.status != 'active') continue;
        final isDemo = ref.code == demoCode;
        if (!isDemo && rng.nextDouble() > 0.12) continue;
        // pick a not-yet-taken course planned around current semester
        final candidates = courses
            .where((c) =>
                !c.conditional &&
                !ref.takenCourseIds.contains(c.id) &&
                c.plannedSemester >= ref.currentSem &&
                c.plannedSemester <= ref.currentSem + 1)
            .toList()
          ..shuffle(rng);
        final take = isDemo ? 2 : 1;
        for (final c in candidates.take(take)) {
          await txn.insert('enrollments', {
            'student_id': ref.id,
            'course_id': c.id,
            'term': currentRegTerm,
            'status': 'studying',
            'approval': 'approved',
          });
        }
      }

      // ---- settings ----
      await txn.insert('settings', {'key': 'current_term', 'value': currentRegTerm});
      await txn.insert('settings', {'key': 'reg_open', 'value': '1'});
      await txn.insert('settings', {'key': 'demo_student_code', 'value': demoCode});

      // ---- a few audit entries so the activity feed isn't empty ----
      final t0 = now;
      Future<void> log(String actor, String role, String action, String detail,
          String? sc, int minsAgo) {
        return txn.insert('audit_log', {
          'ts': t0.subtract(Duration(minutes: minsAgo)).toIso8601String(),
          'actor_name': actor,
          'role': role,
          'action': action,
          'detail': detail,
          'student_code': sc,
        });
      }

      await log('CN. Lê Thị Đào', 'assistant', 'Mở kỳ đăng ký',
          'Mở kỳ đăng ký học phần $currentRegTerm', null, 240);
      await log('TS. Nguyễn Quốc Toàn (Quản trị)', 'admin', 'Cập nhật CTĐT',
          'Ban hành chương trình đào tạo theo ${CurriculumSeed.decision}', null, 300);
      await log(demoRef.name, 'student', 'Đăng ký học phần',
          'Đăng ký học phần kỳ $currentRegTerm', demoCode, 30);
    });
  }

  Future<_StudentRef> _createStudent(
    DatabaseExecutor txn, {
    required Random rng,
    required List<_CourseLite> courses,
    required String code,
    required String fullName,
    required int enrollYear,
    required String cohort,
    required String className,
    required int advisorId,
    required double ability,
    required DateTime now,
  }) async {
    final yearsElapsed = now.year - enrollYear;
    var currentSem = yearsElapsed * 2 + 1;
    final graduated = currentSem > 8;
    if (currentSem > 8) currentSem = 9;
    final status = graduated ? 'graduated' : 'active';

    // choose a direction for V.3
    final direction = rng.nextInt(3) + 1;

    final birthYear = enrollYear - 18;
    final birthMonth = rng.nextInt(12) + 1;
    final birthDay = rng.nextInt(28) + 1;
    final birthDate = '${birthDay.toString().padLeft(2, '0')}/'
        '${birthMonth.toString().padLeft(2, '0')}/$birthYear';
    final phone = '0${(rng.nextInt(3) == 0 ? 9 : 3)}'
        '${(rng.nextInt(90000000) + 10000000)}';
    final hometown = _hometowns[rng.nextInt(_hometowns.length)];

    final studentId = await txn.insert('students', {
      'student_code': code,
      'full_name': fullName,
      'cohort': cohort,
      'class_name': className,
      'major': CurriculumSeed.major,
      'enroll_year': enrollYear,
      'advisor_id': advisorId,
      'direction': direction,
      'status': status,
      'phone': phone,
      'birth_date': birthDate,
      'hometown': hometown,
      'email': 'sv$code@gmail.com',
    });

    // ---- build the set of courses this student follows ----
    final followed = <_CourseLite>[];
    // all mandatory (non-conditional)
    followed.addAll(courses.where((c) => c.mandatory && !c.conditional));
    // electives per block to meet quota
    void fillBlock(String block, int quota) {
      final pool = courses.where((c) => c.block == block).toList()..shuffle(rng);
      var sum = 0;
      for (final c in pool) {
        if (sum >= quota) break;
        followed.add(c);
        sum += c.credits;
      }
    }

    fillBlock('II.2', 3);
    fillBlock('III.2', 7);
    fillBlock('IV.2', 9);
    fillBlock('V.2', 6);
    fillBlock('V.4G', 6);
    // chosen direction courses
    final dirPool =
        courses.where((c) => c.block == 'V.3.$direction').toList()..shuffle(rng);
    var dsum = 0;
    for (final c in dirPool) {
      if (dsum >= 12) break;
      followed.add(c);
      dsum += c.credits;
    }

    final bySem = <int, List<_CourseLite>>{};
    for (final c in followed) {
      bySem.putIfAbsent(c.plannedSemester, () => []).add(c);
    }

    final lastSem = graduated ? 8 : currentSem;
    final takenIds = <int>{};
    for (var s = 1; s <= lastSem; s++) {
      final isCurrent = !graduated && s == currentSem;
      final term = _termCode(enrollYear, s);
      var planned = bySem[s] ?? const <_CourseLite>[];

      // weak students sometimes register fewer credits
      if (ability < 0.4 && rng.nextDouble() < 0.5 && planned.length > 2) {
        planned = planned.sublist(0, planned.length - 1 - rng.nextInt(2));
      }

      for (final c in planned) {
        takenIds.add(c.id);
        if (isCurrent) {
          await txn.insert('enrollments', {
            'student_id': studentId,
            'course_id': c.id,
            'term': term,
            'status': 'studying',
            'approval': 'approved',
          });
        } else {
          final g = _rollGrade(rng, ability);
          final pass = g >= 4.0;
          final midterm = _clamp(g + _gauss(rng) * 1.2, 0, 10);
          await txn.insert('enrollments', {
            'student_id': studentId,
            'course_id': c.id,
            'term': term,
            'midterm': double.parse(midterm.toStringAsFixed(1)),
            'final_exam': double.parse(g.toStringAsFixed(1)),
            'grade10': double.parse(g.toStringAsFixed(1)),
            'grade_letter': _letter(g),
            'grade4': _toFour(g),
            'status': pass ? 'passed' : 'failed',
            'approval': 'approved',
          });
        }
      }
    }

    return _StudentRef(studentId, code, fullName, status, currentSem, takenIds);
  }

  // ---- generation helpers ----
  static String _termCode(int enrollYear, int semester) {
    final academicYear = enrollYear + ((semester - 1) ~/ 2);
    final termInYear = ((semester - 1) % 2) + 1;
    return '$academicYear$termInYear';
  }

  static double _rollGrade(Random rng, double ability) {
    final mean = 3.5 + ability * 5.5;
    var g = mean + _gauss(rng) * 1.6;
    g = _clamp(g, 0, 10);
    if (ability < 0.45 && rng.nextDouble() < (0.45 - ability)) {
      g = _clamp(2 + rng.nextDouble() * 2, 0, 3.9);
    }
    return g;
  }

  static String _letter(double g10) {
    if (g10 >= 9.5) return 'A+';
    if (g10 >= 8.5) return 'A';
    if (g10 >= 8.0) return 'B+';
    if (g10 >= 7.0) return 'B';
    if (g10 >= 6.5) return 'C+';
    if (g10 >= 5.5) return 'C';
    if (g10 >= 5.0) return 'D+';
    if (g10 >= 4.0) return 'D';
    return 'F';
  }

  static double _toFour(double g10) {
    if (g10 >= 8.5) return 4.0;
    if (g10 >= 8.0) return 3.5;
    if (g10 >= 7.0) return 3.0;
    if (g10 >= 6.5) return 2.5;
    if (g10 >= 5.5) return 2.0;
    if (g10 >= 5.0) return 1.5;
    if (g10 >= 4.0) return 1.0;
    return 0.0;
  }

  static double _gauss(Random rng) {
    final u1 = rng.nextDouble().clamp(1e-9, 1.0);
    final u2 = rng.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  static const _surnames = [
    'Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Huỳnh', 'Phan', 'Vũ',
    'Võ', 'Đặng', 'Bùi', 'Đỗ', 'Hồ', 'Ngô', 'Dương', 'Lý',
  ];
  static const _middle = [
    'Văn', 'Thị', 'Minh', 'Hoàng', 'Thu', 'Quang', 'Đình', 'Hữu',
    'Ngọc', 'Thanh', 'Gia', 'Khánh', 'Bảo', 'Phương', 'Anh', 'Hải',
  ];
  static const _given = [
    'An', 'Bình', 'Chi', 'Dũng', 'Duy', 'Giang', 'Hà', 'Hải',
    'Hoa', 'Hùng', 'Huy', 'Khôi', 'Lan', 'Linh', 'Long', 'Mai', 'Nam',
    'Nga', 'Ngân', 'Phong', 'Quân', 'Quỳnh', 'Sơn', 'Tâm', 'Thảo',
    'Trang', 'Trung', 'Tuấn', 'Vân', 'Việt', 'Yến',
  ];

  static const _hometowns = [
    'Hà Nội', 'Hải Phòng', 'Nam Định', 'Thái Bình', 'Thanh Hóa',
    'Nghệ An', 'Hà Tĩnh', 'Bắc Ninh', 'Bắc Giang', 'Hưng Yên',
    'Hải Dương', 'Vĩnh Phúc', 'Phú Thọ', 'Quảng Ninh', 'Ninh Bình',
    'Hòa Bình', 'Sơn La', 'Tuyên Quang', 'Lào Cai', 'Đà Nẵng',
  ];

  static String _randomName(Random rng) =>
      '${_surnames[rng.nextInt(_surnames.length)]} '
      '${_middle[rng.nextInt(_middle.length)]} '
      '${_given[rng.nextInt(_given.length)]}';
}

class _CourseLite {
  final int id;
  final String code;
  final int credits;
  final bool mandatory;
  final bool conditional;
  final int plannedSemester;
  final String block;
  final int? direction;
  _CourseLite(this.id, this.code, this.credits, this.mandatory,
      this.conditional, this.plannedSemester, this.block, this.direction);
}

class _StudentRef {
  final int id;
  final String code;
  final String name;
  final String status;
  final int currentSem;
  final Set<int> takenCourseIds;
  _StudentRef(this.id, this.code, this.name, this.status, this.currentSem,
      this.takenCourseIds);
}
