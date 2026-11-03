-- ============================================================================
-- Quyền riêng tư bảng profiles. Trước đây mọi người đã đăng nhập (kể cả sinh
-- viên) đọc được toàn bộ tài khoản: họ tên, MSSV, tên đăng nhập, SĐT, email.
-- Nay chỉ còn:
--   - mỗi người: hồ sơ của chính mình;
--   - quản trị, BCN khoa, trợ lý QT: mọi hồ sơ (vốn đã xem được toàn bộ SV);
--   - cán bộ (kể cả CVHT): hồ sơ các cán bộ khác (danh sách CVHT, tên người
--     thao tác...);
--   - CVHT: thêm hồ sơ tài khoản của sinh viên lớp mình cố vấn;
--   - sinh viên: thêm hồ sơ CVHT của mình (để hiện tên CVHT).
-- Bảng phân lớp class_advisors cũng chỉ còn cán bộ đọc được.
-- Chạy lại vẫn an toàn.
-- ============================================================================

-- CVHT [auth.uid()] có đang cố vấn sinh viên sở hữu tài khoản [pid] không.
create or replace function public.advises_profile(pid uuid)
returns boolean language sql stable
security definer set search_path = public as $$
  select exists (
    select 1
    from public.profiles p
    join public.students s on s.student_code = p.student_code
    where p.id = pid and s.advisor_id = auth.uid());
$$;

-- Tài khoản [pid] có phải CVHT của sinh viên đang đăng nhập không.
create or replace function public.is_my_advisor(pid uuid)
returns boolean language sql stable
security definer set search_path = public as $$
  select exists (
    select 1 from public.students s
    where s.advisor_id = pid
      and s.student_code = public.current_student_code());
$$;

grant execute on function public.advises_profile(uuid) to authenticated;
grant execute on function public.is_my_advisor(uuid) to authenticated;

drop policy if exists profiles_select on public.profiles;
create policy profiles_select on public.profiles
  for select using (
    id = auth.uid()
    or public.can_view_all()
    or (public.is_faculty() and role <> 'student')
    or (public.auth_role() = 'advisor' and public.advises_profile(id))
    or public.is_my_advisor(id)
  );

drop policy if exists class_advisors_select on public.class_advisors;
create policy class_advisors_select on public.class_advisors
  for select using (public.is_faculty());

notify pgrst, 'reload schema';
