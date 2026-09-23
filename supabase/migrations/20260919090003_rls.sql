-- ============================================================================
-- Bảo mật cấp dòng (RLS) cho 5 vai trò. Quyền được ENFORCE tại CSDL, không chỉ
-- ở client. Các hàm trợ giúp dùng SECURITY DEFINER để tránh đệ quy RLS.
-- ============================================================================

create or replace function public.auth_role()
returns public.app_role language sql stable
security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean language sql stable
security definer set search_path = public as $$
  select public.auth_role() = 'admin';
$$;

create or replace function public.is_faculty()
returns boolean language sql stable
security definer set search_path = public as $$
  select coalesce(public.auth_role() <> 'student', false);
$$;

-- Xem toàn bộ SV: quản trị + ban chủ nhiệm + trợ lý quản trị.
create or replace function public.can_view_all()
returns boolean language sql stable
security definer set search_path = public as $$
  select public.auth_role() in ('admin', 'dean', 'assistant');
$$;

create or replace function public.current_student_code()
returns text language sql stable
security definer set search_path = public as $$
  select student_code from public.profiles where id = auth.uid();
$$;

create or replace function public.owns_student(sid bigint)
returns boolean language sql stable
security definer set search_path = public as $$
  select exists (
    select 1 from public.students s
    where s.id = sid and s.student_code = public.current_student_code());
$$;

create or replace function public.advises_student(sid bigint)
returns boolean language sql stable
security definer set search_path = public as $$
  select exists (
    select 1 from public.students s
    where s.id = sid and s.advisor_id = auth.uid());
$$;

-- Chặn sinh viên tự sửa các trường ngoài thông tin liên hệ của mình.
create or replace function public.tg_students_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then
    return new;
  end if;
  -- Chỉ còn lại chủ hồ sơ (sinh viên) mới tới đây; giới hạn cột được đổi.
  if new.student_code is distinct from old.student_code
     or new.full_name  is distinct from old.full_name
     or new.cohort     is distinct from old.cohort
     or new.class_name is distinct from old.class_name
     or new.advisor_id is distinct from old.advisor_id
     or new.enroll_year is distinct from old.enroll_year
     or new.direction  is distinct from old.direction
     or new.status     is distinct from old.status then
    raise exception 'Sinh viên chỉ được sửa thông tin liên hệ của chính mình.';
  end if;
  return new;
end;
$$;

create trigger students_guard before update on public.students
  for each row execute function public.tg_students_guard();

-- ---------------------------------------------------------- bật RLS
alter table public.profiles          enable row level security;
alter table public.students          enable row level security;
alter table public.courses           enable row level security;
alter table public.curriculum_blocks enable row level security;
alter table public.enrollments       enable row level security;
alter table public.change_requests   enable row level security;
alter table public.settings          enable row level security;
alter table public.audit_log         enable row level security;

-- ---------------------------------------------------------- profiles
-- Nội bộ khoa: mọi người đã đăng nhập đọc được họ tên/vai trò (để hiển thị CVHT).
create policy profiles_select on public.profiles
  for select using (auth.uid() is not null);
create policy profiles_write on public.profiles
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------- students
create policy students_select on public.students
  for select using (
    public.can_view_all() or public.owns_student(id) or public.advises_student(id));
create policy students_insert on public.students
  for insert with check (public.auth_role() in ('admin', 'assistant'));
create policy students_update on public.students
  for update using (public.is_admin() or public.owns_student(id))
  with check (public.is_admin() or public.owns_student(id));
create policy students_delete on public.students
  for delete using (public.is_admin());

-- ---------------------------------------------------------- courses / blocks
create policy courses_select on public.courses
  for select using (auth.uid() is not null);
create policy courses_write on public.courses
  for all using (public.is_admin()) with check (public.is_admin());

create policy blocks_select on public.curriculum_blocks
  for select using (auth.uid() is not null);
create policy blocks_write on public.curriculum_blocks
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------- enrollments
-- Sinh viên tự đăng ký & tự nhập điểm của mình; quản trị toàn quyền.
create policy enrollments_select on public.enrollments
  for select using (
    public.can_view_all() or public.owns_student(student_id)
    or public.advises_student(student_id));
create policy enrollments_insert on public.enrollments
  for insert with check (public.is_admin() or public.owns_student(student_id));
create policy enrollments_update on public.enrollments
  for update using (public.is_admin() or public.owns_student(student_id))
  with check (public.is_admin() or public.owns_student(student_id));
create policy enrollments_delete on public.enrollments
  for delete using (public.is_admin() or public.owns_student(student_id));

-- ---------------------------------------------------------- change_requests
-- Trợ lý gửi đề xuất; quản trị duyệt.
create policy change_requests_select on public.change_requests
  for select using (public.is_admin() or requested_by = auth.uid());
create policy change_requests_insert on public.change_requests
  for insert with check (public.auth_role() in ('assistant', 'admin'));
create policy change_requests_update on public.change_requests
  for update using (public.is_admin()) with check (public.is_admin());
create policy change_requests_delete on public.change_requests
  for delete using (public.is_admin());

-- ---------------------------------------------------------- settings
create policy settings_select on public.settings
  for select using (auth.uid() is not null);
create policy settings_write on public.settings
  for all using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------- audit_log
create policy audit_select on public.audit_log
  for select using (
    public.can_view_all() or student_code = public.current_student_code());
create policy audit_insert on public.audit_log
  for insert with check (auth.uid() is not null);

-- ---------------------------------------------------------- grants
-- RLS quyết định dòng nào; grant chỉ mở quyền bảng cho vai trò đã đăng nhập.
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;
