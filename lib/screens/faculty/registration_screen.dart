import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Quản trị: mở/đóng kỳ đăng ký + phê duyệt các đề xuất sửa hồ sơ do trợ lý gửi.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  List<ChangeRequest> _pending = [];
  bool _loading = true;
  int _rev = -1;
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
    final state = context.watch<AppState>();
    if (state.dataRevision != _rev) {
      _rev = state.dataRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Kỳ đăng ký & phê duyệt hồ sơ',
          subtitle: 'Kỳ hiện tại: ${state.currentTerm} · '
              '${state.regOpen ? "Đang mở đăng ký" : "Đã đóng đăng ký"} · '
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
          children: [
            const Icon(Icons.event_available, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text('Kỳ đăng ký:'),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _termCtrl,
                decoration: const InputDecoration(isDense: true, hintText: 'vd 20261'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () async {
                await state.repo.setCurrentTerm(_termCtrl.text.trim(), state.user!);
                await state.bumpData();
              },
              child: const Text('Cập nhật kỳ'),
            ),
            const SizedBox(width: 24),
            const Text('Trạng thái đăng ký:'),
            const SizedBox(width: 8),
            Switch(
              value: state.regOpen,
              onChanged: (v) async {
                await state.repo.setRegOpen(v, state.user!);
                await state.bumpData();
              },
            ),
            Text(state.regOpen ? 'Đang mở' : 'Đã đóng',
                style: TextStyle(
                    color: state.regOpen ? AppColors.ok : AppColors.danger,
                    fontWeight: FontWeight.w600)),
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
