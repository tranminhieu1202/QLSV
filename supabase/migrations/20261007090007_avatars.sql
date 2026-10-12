-- ============================================================================
-- Ảnh đại diện cho mọi tài khoản (quản trị, ban chủ nhiệm, trợ lý, CVHT,
-- sinh viên). Ảnh lưu ở Storage bucket công khai `avatars`, mỗi người chỉ được
-- ghi vào thư mục `<auth.uid()>/` của chính mình.
-- ============================================================================

alter table public.profiles add column if not exists avatar_url text;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 1048576, array['image/png', 'image/jpeg'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists avatars_read on storage.objects;
create policy avatars_read on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists avatars_insert_own on storage.objects;
create policy avatars_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatars_update_own on storage.objects;
create policy avatars_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists avatars_delete_own on storage.objects;
create policy avatars_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- Hiển thị ảnh của sinh viên ở danh sách / hồ sơ sinh viên (lấy từ tài khoản
-- có cùng MSSV).
create or replace view public.student_overview
with (security_invoker = true) as
select s.*,
  coalesce(cpa.cpa, 0) as cpa,
  coalesce(cpa.passed_credits, 0) as passed_credits,
  coalesce(d.debt_credits, 0) as debt_credits,
  adv.full_name as advisor_name,
  (select p.avatar_url from public.profiles p
    where p.student_code = s.student_code and p.avatar_url is not null
    limit 1) as avatar_url
from public.students s
left join public.student_cpa cpa on cpa.student_id = s.id
left join public.student_debt d on d.student_id = s.id
left join public.profiles adv on adv.id = s.advisor_id;
