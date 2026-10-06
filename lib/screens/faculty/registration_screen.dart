import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/academic_service.dart';
import '../../data/repository.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/revision_reload.dart';

/// Quản trị: đặt kỳ học hiện tại + phê duyệt các đề xuất sửa hồ sơ do trợ lý
/// gửi. Sinh viên tự khai báo học phần & điểm nên không còn mở/đóng đăng ký.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with RevisionReload {
  List<ChangeRequest> _pending = [];
  bool _loading = true;
  late final TextEditingController _termCtrl = TextEditingController();

  Future<void> _load() async {
    final state = context.read<AppState>();
    final pending = await state.repo.pendingChangeRequests();
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _termCtrl.text = state.currentTerm;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _termCtrl.dispose();
    super.dispose();
  }

  Future<void> _decide(ChangeRequest req, bool approve) async {
    final state = context.read<AppState>();
    await state.repo
        .decideChangeRequest(req: req, approve: approve, actor: state.user!);
    await state.bumpData();
  }

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    final state = context.watch<AppState>();
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Kỳ học & phê duyệt hồ sơ',
          subtitle: 'Kỳ hiện tại: ${AcademicService.termLabel(state.currentTerm)} · '
              '${_pending.length} đề xuất sửa hồ sơ chờ duyệt',
        ),
        _periodControls(state),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Đề xuất sửa hồ sơ chờ quản trị phê duyệt',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _pending.isEmpty
              ? const Center(
                  child: Text('Không có đề xuất sửa hồ sơ nào chờ duyệt.'))
              : ListView.separated(
                  itemCount: _pending.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _requestCard(_pending[i]),
                ),
        ),
      ],
    );
  }

  Widget _periodControls(AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event_note, color: AppColors.primary),
            const SizedBox(width: 12),
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('Kỳ học hiện tại:'),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _termCtrl,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'vd 20261',
                  helperText: 'Năm + kỳ (1, 2, 3 = hè)',
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                final term = _termCtrl.text.trim();
                if (!RegExp(r'^20\d\d[123]$').hasMatch(term)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Mã kỳ phải có dạng YYYYK, vd 20261.'),
                      backgroundColor: AppColors.danger));
                  return;
                }
                await state.repo.setCurrentTerm(term, state.user!);
                await state.bumpData();
              },
              child: const Text('Cập nhật kỳ'),
            ),
            const SizedBox(width: 24),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Kỳ hiện tại quyết định sinh viên năm thứ mấy (mã 26 là năm 1 '
                  'khi kỳ là 2026x). Sinh viên tự khai báo học phần và điểm của '
                  'mình, không cần mở kỳ đăng ký hay duyệt; cán bộ theo dõi ở '
                  'màn Sinh viên và Cảnh báo.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(ChangeRequest req) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.info,
              child: Icon(Icons.edit_note, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${req.fieldLabel} · ${req.studentName} · '
                      '${req.studentCode}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text('“${req.oldValue ?? '-'}”',
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                decoration: TextDecoration.lineThrough)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward,
                            size: 16, color: AppColors.textMuted),
                      ),
                      Flexible(
                        child: Text('“${req.newValue ?? '-'}”',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Đề xuất bởi: ${req.requestedBy}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _decide(req, false),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Từ chối'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _decide(req, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.ok),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Duyệt'),
            ),
          ],
        ),
      ),
    );
  }
}
