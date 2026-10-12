import 'package:flutter_test/flutter_test.dart';
import 'package:qlgd_edu/widgets/user_avatar.dart';

void main() {
  test('chữ cái đại diện lấy từ tên, bỏ phần trong ngoặc', () {
    expect(UserAvatar.initialOf('TS. Nguyễn Quốc Toàn (Quản trị)'), 'T');
    expect(UserAvatar.initialOf('Trần Minh Hiếu'), 'H');
    expect(UserAvatar.initialOf('nguyễn văn ánh'), 'Á');
    expect(UserAvatar.initialOf('  '), '?');
  });
}
