import 'package:flutter_test/flutter_test.dart';

import 'package:qlgd_edu/data/supabase_config.dart';

void main() {
  test('toEmail maps MSSV và username về đúng domain', () {
    expect(SupabaseConfig.toEmail('2023001'), '2023001@sv.qlgd.edu.vn');
    expect(SupabaseConfig.toEmail('admin'), 'admin@qlgd.edu.vn');
    expect(SupabaseConfig.toEmail('a@b.com'), 'a@b.com');
  });
}
