import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Thông tin bản phát hành mới hơn trên GitHub Releases.
class UpdateInfo {
  final String version; // vd 1.1.0
  final String notes;
  final String? installerUrl; // .exe (Windows) hoặc -macos.zip (macOS)
  final String pageUrl; // trang release
  UpdateInfo({
    required this.version,
    required this.notes,
    required this.installerUrl,
    required this.pageUrl,
  });
}

/// Không kiểm tra được cập nhật (mất mạng, repo private/không tồn tại, ...).
class UpdateCheckException implements Exception {
  final String message;
  UpdateCheckException(this.message);
  @override
  String toString() => message;
}

/// Kiểm tra & tải cập nhật qua GitHub Releases (phương án A).
/// Repo phải để public: API GitHub trả 404 cho repo private khi không đăng nhập.
class UpdateService {
  static const _owner = 'tranminhieu1202';
  static const _repo = 'QLSV';
  static const releasesUrl = 'https://github.com/$_owner/$_repo/releases';

  /// Bản phát hành qua Mac App Store (build với `--dart-define=APP_STORE=true`).
  /// Apple không cho app tự cập nhật ngoài App Store (Guideline 2.4.5),
  /// nên bản này tắt hẳn kênh GitHub Releases.
  static const enabled = !bool.fromEnvironment('APP_STORE');

  /// Trả về [UpdateInfo] nếu có bản mới hơn, null nếu đã là bản mới nhất.
  /// Ném [UpdateCheckException] khi không kiểm tra được, để không báo nhầm
  /// "đã mới nhất".
  Future<UpdateInfo?> check() async {
    final pkg = await PackageInfo.fromPlatform();
    final http.Response res;
    try {
      res = await http.get(
        Uri.parse(
            'https://api.github.com/repos/$_owner/$_repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw UpdateCheckException('Không kết nối được máy chủ cập nhật.');
    }
    if (res.statusCode == 404) {
      throw UpdateCheckException(
          'Không tìm thấy bản phát hành trên GitHub (repo private hoặc chưa có release).');
    }
    if (res.statusCode != 200) {
      throw UpdateCheckException(
          'Máy chủ cập nhật trả lỗi HTTP ${res.statusCode}.');
    }
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final latest =
          ((json['tag_name'] as String?) ?? '').replaceFirst(RegExp(r'^v'), '');
      if (latest.isEmpty || !_isNewer(latest, pkg.version)) return null;

      // Mỗi hệ điều hành lấy đúng gói của mình trong release.
      bool mine(String name) => Platform.isMacOS
          ? name.endsWith('-macos.zip')
          : name.endsWith('.exe');
      String? exeUrl;
      for (final a in (json['assets'] as List? ?? const [])) {
        final name = (a['name'] as String?)?.toLowerCase() ?? '';
        if (mine(name)) {
          exeUrl = a['browser_download_url'] as String?;
          break;
        }
      }
      return UpdateInfo(
        version: latest,
        notes: (json['body'] as String?) ?? '',
        installerUrl: exeUrl,
        pageUrl: (json['html_url'] as String?) ?? releasesUrl,
      );
    } catch (_) {
      throw UpdateCheckException('Dữ liệu bản phát hành không hợp lệ.');
    }
  }

  bool _isNewer(String latest, String current) {
    List<int> parts(String v) =>
        v.split('.').map((s) => int.tryParse(s.split('+').first) ?? 0).toList();
    final a = parts(latest), b = parts(current);
    final n = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// Tải installer về thư mục tạm và chạy, rồi thoát app để cài (Windows).
  Future<void> downloadAndRun(UpdateInfo info,
      {void Function(double progress)? onProgress}) async {
    final url = info.installerUrl;
    if (url == null) throw Exception('Release không có file cài (.exe).');
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'qlgd_edu-setup-${info.version}.exe'));

    final resp = await http.Client().send(http.Request('GET', Uri.parse(url)));
    final total = resp.contentLength ?? 0;
    final sink = file.openWrite();
    var received = 0;
    await for (final chunk in resp.stream) {
      received += chunk.length;
      sink.add(chunk);
      if (total > 0) onProgress?.call(received / total);
    }
    await sink.close();

    await Process.start(file.path, const [],
        mode: ProcessStartMode.detached);
    exit(0); // đóng app để installer ghi đè được file
  }
}
