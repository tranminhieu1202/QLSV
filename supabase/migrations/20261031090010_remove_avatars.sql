-- ============================================================================
-- Gỡ tính năng ảnh đại diện trên Supabase (tránh tràn dung lượng Storage).
-- Đảo ngược 20261007090007_avatars.sql; chạy được cả khi migration đó chưa
-- từng được áp dụng. App vẫn chạy bình thường: avatar_url không còn → null →
-- hiển thị chữ cái đầu tên; nút tải ảnh sẽ báo lỗi thay vì lưu được ảnh.
-- ============================================================================

-- 1) Chặn mọi thao tác ghi/đọc ảnh qua API -----------------------------------
drop policy if exists avatars_read on storage.objects;
drop policy if exists avatars_insert_own on storage.objects;
drop policy if exists avatars_update_own on storage.objects;
drop policy if exists avatars_delete_own on storage.objects;

-- 2) Xóa kho ảnh. Supabase có thể chặn xóa trực tiếp bảng storage bằng SQL;
--    khi đó chỉ báo NOTICE, cần xóa tay: Dashboard → Storage → avatars →
--    Empty bucket → Delete bucket.
do $$
begin
  delete from storage.objects where bucket_id = 'avatars';
  delete from storage.buckets where id = 'avatars';
exception when others then
  raise notice 'Không xóa được bucket avatars bằng SQL (%). Hãy xóa trong Dashboard → Storage.', sqlerrm;
end $$;

-- 3) Bỏ cột avatar_url: tạo lại view student_overview như bản gốc -----------
drop view if exists public.student_overview;
create view public.student_overview
with (security_invoker = true) as
select
  s.*,
  coalesce(cpa.cpa, 0)             as cpa,
  coalesce(cpa.passed_credits, 0)  as passed_credits,
  coalesce(d.debt_credits, 0)      as debt_credits,
  adv.full_name                    as advisor_name
from public.students s
left join public.student_cpa cpa on cpa.student_id = s.id
left join public.student_debt d on d.student_id = s.id
left join public.profiles adv on adv.id = s.advisor_id;
grant select on public.student_overview to authenticated;

alter table public.profiles drop column if exists avatar_url;

notify pgrst, 'reload schema';
