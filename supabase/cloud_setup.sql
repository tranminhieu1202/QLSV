-- ============================================================================
-- QLGD EDU · CÀI ĐẶT CLOUD MỘT LẦN (dán toàn bộ file này vào Dashboard →
-- SQL Editor của project rỗng, bấm Run). Gộp: schema + views + RLS +
-- chương trình đào tạo + 4 tài khoản mặc định (admin/dean/assistant/advisor1,
-- mật khẩu 123456). Chỉ chạy trên project CHƯA có schema.
-- (Nguồn: migrations 001–006 + phần dữ liệu CTĐT trong seed.sql.)
-- ============================================================================

-- ==================== 1) SCHEMA ====================
create extension if not exists pgcrypto;

create type public.app_role as enum ('admin', 'dean', 'assistant', 'advisor', 'student');

create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text unique,
  role         public.app_role not null default 'student',
  full_name    text not null default '',
  student_code text,
  active       boolean not null default true,
  phone        text,
  email        text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create table public.courses (
  id               bigint primary key generated always as identity,
  code             text unique not null,
  name             text not null,
  credits          int not null check (credits >= 0),
  mandatory        boolean not null default false,
  planned_semester int not null,
  semester_text    text,
  block            text not null,
  block_name       text not null default '',
  direction        int check (direction in (1, 2, 3)),
  conditional      boolean not null default false,
  oriented         boolean not null default false,
  prerequisite     text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create table public.curriculum_blocks (
  key        text primary key,
  name       text not null,
  kind       text not null check (kind in ('mandatory', 'elective', 'direction', 'grad')),
  quota      int not null default 0,
  sort_order int not null default 0
);

create table public.students (
  id           bigint primary key generated always as identity,
  student_code text unique not null,
  full_name    text not null,
  cohort       text not null,
  class_name   text not null,
  major        text not null default 'Quản trị trường học',
  enroll_year  int not null,
  advisor_id   uuid references public.profiles (id) on delete set null,
  direction    int check (direction in (1, 2, 3)),
  status       text not null default 'active'
                 check (status in ('active', 'suspended', 'graduated')),
  phone        text,
  birth_date   text,
  hometown     text,
  email        text,
  user_id      uuid references public.profiles (id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index students_advisor_idx on public.students (advisor_id);
create index students_cohort_idx on public.students (cohort);

create table public.enrollments (
  id           bigint primary key generated always as identity,
  student_id   bigint not null references public.students (id) on delete cascade,
  course_id    bigint not null references public.courses (id),
  term         text not null,
  midterm      numeric(4, 1) check (midterm between 0 and 10),
  final_exam   numeric(4, 1) check (final_exam between 0 and 10),
  grade10      numeric(4, 1),
  grade_letter text,
  grade4       numeric(3, 2),
  status       text not null default 'registered'
                 check (status in ('registered', 'studying', 'passed', 'failed')),
  approval     text not null default 'approved'
                 check (approval in ('pending', 'approved', 'rejected')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (student_id, course_id, term)
);
create index enrollments_student_idx on public.enrollments (student_id);
create index enrollments_course_idx on public.enrollments (course_id);

create table public.change_requests (
  id             bigint primary key generated always as identity,
  student_id     bigint not null references public.students (id) on delete cascade,
  student_code   text not null,
  field          text not null,
  field_label    text not null,
  old_value      text,
  new_value      text,
  requested_by   uuid references public.profiles (id) on delete set null,
  requested_role public.app_role,
  status         text not null default 'pending'
                   check (status in ('pending', 'approved', 'rejected')),
  created_at     timestamptz not null default now()
);
create index change_requests_status_idx on public.change_requests (status);

create table public.settings (
  key   text primary key,
  value text
);

create table public.audit_log (
  id           bigint primary key generated always as identity,
  ts           timestamptz not null default now(),
  actor_id     uuid references public.profiles (id) on delete set null,
  actor_name   text not null,
  role         public.app_role,
  action       text not null,
  detail       text not null,
  student_code text
);
create index audit_log_ts_idx on public.audit_log (ts desc);

create or replace function public.tg_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger set_updated_at before update on public.profiles
  for each row execute function public.tg_set_updated_at();
create trigger set_updated_at before update on public.courses
  for each row execute function public.tg_set_updated_at();
create trigger set_updated_at before update on public.students
  for each row execute function public.tg_set_updated_at();
create trigger set_updated_at before update on public.enrollments
  for each row execute function public.tg_set_updated_at();

create or replace function public.grade_overall(p_midterm numeric, p_final numeric)
returns numeric language sql immutable as $$
  select round(
    case when p_midterm is null then p_final
         else p_midterm * 0.3 + p_final * 0.7 end::numeric, 1);
$$;

create or replace function public.grade_letter(g10 numeric)
returns text language sql immutable as $$
  select case
    when g10 >= 9.0 then 'A+'
    when g10 >= 8.5 then 'A'
    when g10 >= 8.0 then 'B+'
    when g10 >= 7.0 then 'B'
    when g10 >= 6.5 then 'C+'
    when g10 >= 5.5 then 'C'
    when g10 >= 5.0 then 'D+'
    when g10 >= 4.0 then 'D'
    else 'F' end;
$$;

create or replace function public.grade_four(g10 numeric)
returns numeric language sql immutable as $$
  select case
    when g10 >= 9.0 then 4.0
    when g10 >= 8.5 then 3.7
    when g10 >= 8.0 then 3.5
    when g10 >= 7.0 then 3.0
    when g10 >= 6.5 then 2.5
    when g10 >= 5.5 then 2.0
    when g10 >= 5.0 then 1.5
    when g10 >= 4.0 then 1.0
    else 0.0 end::numeric;
$$;

create or replace function public.tg_apply_grade()
returns trigger language plpgsql as $$
begin
  if new.final_exam is null then
    new.grade10 := null;
    new.grade_letter := null;
    new.grade4 := null;
    if new.status is null or new.status in ('passed', 'failed') then
      new.status := 'studying';
    end if;
  else
    new.grade10 := public.grade_overall(new.midterm, new.final_exam);
    new.grade_letter := public.grade_letter(new.grade10);
    new.grade4 := public.grade_four(new.grade10);
    new.status := case when new.grade10 >= 4.0 then 'passed' else 'failed' end;
  end if;
  return new;
end;
$$;

create trigger apply_grade before insert or update of midterm, final_exam
  on public.enrollments
  for each row execute function public.tg_apply_grade();

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, username, role, full_name, student_code, active)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'username', split_part(new.email, '@', 1)),
    coalesce((new.raw_user_meta_data ->> 'role')::public.app_role, 'student'),
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'student_code',
    true
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- ==================== 2) VIEWS (tính CPA/GPA server-side) ====================
create view public.effective_enrollments
with (security_invoker = true) as
select e.id, e.student_id, e.course_id, e.term, e.status, e.grade4,
       c.credits, c.mandatory, c.block, c.planned_semester
from public.enrollments e
join public.courses c on c.id = e.course_id
where e.approval = 'approved' and c.conditional = false;

create view public.student_term_summary
with (security_invoker = true) as
select student_id, term,
  round(sum(grade4 * credits) filter (where grade4 is not null)
        / nullif(sum(credits) filter (where grade4 is not null), 0), 2) as gpa,
  sum(credits) as registered_credits,
  coalesce(sum(credits) filter (where status = 'passed'), 0) as passed_credits,
  coalesce(sum(credits) filter (where status = 'failed'), 0) as debt_credits
from public.effective_enrollments
group by student_id, term;

-- CPA tích lũy: chỉ học phần đã đạt, mỗi học phần lấy lần đạt gần nhất.
create view public.student_cpa
with (security_invoker = true) as
select student_id,
  round(sum(grade4 * credits) filter (where grade4 is not null)
        / nullif(sum(credits) filter (where grade4 is not null), 0), 2) as cpa,
  coalesce(sum(credits), 0) as passed_credits
from (
  select distinct on (student_id, course_id) student_id, course_id, grade4, credits
  from public.effective_enrollments
  where status = 'passed'
  order by student_id, course_id, term desc, id desc
) t
group by student_id;

create view public.student_debt
with (security_invoker = true) as
select student_id, sum(credits) as debt_credits
from (
  select student_id, course_id, max(credits) as credits
  from public.effective_enrollments
  group by student_id, course_id
  having bool_or(status = 'failed') and not bool_or(status = 'passed')
) t
group by student_id;

create view public.student_overview
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

-- ==================== 3) RLS ====================
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
  select exists (select 1 from public.students s
    where s.id = sid and s.student_code = public.current_student_code());
$$;
create or replace function public.advises_student(sid bigint)
returns boolean language sql stable
security definer set search_path = public as $$
  select exists (select 1 from public.students s
    where s.id = sid and s.advisor_id = auth.uid());
$$;

create or replace function public.tg_students_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then return new; end if;
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

alter table public.profiles          enable row level security;
alter table public.students          enable row level security;
alter table public.courses           enable row level security;
alter table public.curriculum_blocks enable row level security;
alter table public.enrollments       enable row level security;
alter table public.change_requests   enable row level security;
alter table public.settings          enable row level security;
alter table public.audit_log         enable row level security;

create policy profiles_select on public.profiles
  for select using (auth.uid() is not null);
create policy profiles_write on public.profiles
  for all using (public.is_admin()) with check (public.is_admin());
create policy profiles_update_self on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- Chặn người dùng thường tự đổi vai trò / username / trạng thái / MSSV.
create or replace function public.tg_profiles_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then return new; end if;
  if new.role is distinct from old.role
     or new.username is distinct from old.username
     or new.active is distinct from old.active
     or new.student_code is distinct from old.student_code then
    raise exception 'Chỉ được sửa thông tin cá nhân (họ tên, liên hệ) của chính mình.';
  end if;
  return new;
end;
$$;
create trigger profiles_guard before update on public.profiles
  for each row execute function public.tg_profiles_guard();

create policy students_select on public.students
  for select using (public.can_view_all() or public.owns_student(id) or public.advises_student(id));
create policy students_insert on public.students
  for insert with check (public.auth_role() in ('admin', 'assistant'));
create policy students_update on public.students
  for update using (public.is_admin() or public.owns_student(id))
  with check (public.is_admin() or public.owns_student(id));
create policy students_delete on public.students
  for delete using (public.is_admin());

create policy courses_select on public.courses
  for select using (auth.uid() is not null);
create policy courses_write on public.courses
  for all using (public.is_admin()) with check (public.is_admin());
create policy blocks_select on public.curriculum_blocks
  for select using (auth.uid() is not null);
create policy blocks_write on public.curriculum_blocks
  for all using (public.is_admin()) with check (public.is_admin());

create policy enrollments_select on public.enrollments
  for select using (public.can_view_all() or public.owns_student(student_id) or public.advises_student(student_id));
create policy enrollments_insert on public.enrollments
  for insert with check (public.is_admin() or public.owns_student(student_id));
create policy enrollments_update on public.enrollments
  for update using (public.is_admin() or public.owns_student(student_id))
  with check (public.is_admin() or public.owns_student(student_id));
create policy enrollments_delete on public.enrollments
  for delete using (public.is_admin() or public.owns_student(student_id));

create policy change_requests_select on public.change_requests
  for select using (public.is_admin() or requested_by = auth.uid());
create policy change_requests_insert on public.change_requests
  for insert with check (public.auth_role() in ('assistant', 'admin'));
create policy change_requests_update on public.change_requests
  for update using (public.is_admin()) with check (public.is_admin());
create policy change_requests_delete on public.change_requests
  for delete using (public.is_admin());

create policy settings_select on public.settings
  for select using (auth.uid() is not null);
create policy settings_write on public.settings
  for all using (public.is_admin()) with check (public.is_admin());

create policy audit_select on public.audit_log
  for select using (public.can_view_all() or student_code = public.current_student_code());
create policy audit_insert on public.audit_log
  for insert with check (auth.uid() is not null);

grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant execute on all functions in schema public to authenticated;

-- ==================== 4) CHƯƠNG TRÌNH ĐÀO TẠO ====================
insert into public.curriculum_blocks (key, name, kind, quota, sort_order) values
  ('I',     'I. Khối kiến thức chung',                                         'mandatory', 0, 1),
  ('II.1',  'II. Kiến thức theo lĩnh vực (bắt buộc)',                          'mandatory', 0, 2),
  ('II.2',  'II. Kiến thức theo lĩnh vực (tự chọn)',                           'elective',  3, 3),
  ('III.1', 'III. Kiến thức theo khối ngành (bắt buộc)',                       'mandatory', 0, 4),
  ('III.2', 'III. Kiến thức theo khối ngành (tự chọn)',                        'elective',  7, 5),
  ('IV.1',  'IV. Kiến thức theo nhóm ngành (bắt buộc)',                        'mandatory', 0, 6),
  ('IV.2',  'IV. Kiến thức theo nhóm ngành (tự chọn)',                         'elective',  9, 7),
  ('V.1',   'V. Kiến thức ngành (bắt buộc)',                                   'mandatory', 0, 8),
  ('V.2',   'V. Kiến thức ngành (tự chọn chung)',                              'elective',  6, 9),
  ('V.3.1', 'V.3. Hướng ngành 1: Quản trị hành chính nhà trường',             'direction', 12, 10),
  ('V.3.2', 'V.3. Hướng ngành 2: Quản trị nhân lực và đào tạo',               'direction', 12, 11),
  ('V.3.3', 'V.3. Hướng ngành 3: Phát triển và quản lý chương trình giáo dục', 'direction', 12, 12),
  ('V.4',   'V.4. Thực tập nghiệp vụ',                                         'mandatory', 0, 13),
  ('V.4G',  'V.4. Khóa luận / Học phần thay thế tốt nghiệp',                   'grad',      6, 14);

insert into public.courses
  (code, name, credits, mandatory, planned_semester, semester_text, block, direction, conditional, oriented)
values
  ('PHI1006', 'Triết học Mác – Lênin', 3, true, 1, '1', 'I', null, false, false),
  ('PEC1008', 'Kinh tế chính trị Mác – Lênin', 2, true, 1, '1', 'I', null, false, false),
  ('PHI1002', 'Chủ nghĩa xã hội khoa học', 2, true, 3, '3', 'I', null, false, false),
  ('HIS1001', 'Lịch sử Đảng Cộng sản Việt Nam', 2, true, 4, '4', 'I', null, false, false),
  ('POL1001', 'Tư tưởng Hồ Chí Minh', 2, true, 2, '2', 'I', null, false, false),
  ('THL1057', 'Nhà nước và Pháp luật đại cương', 2, true, 2, '2', 'I', null, false, false),
  ('FLF1101', 'Ngoại ngữ B1', 5, true, 2, '2-4', 'I', null, false, false),
  ('VNU1001', 'Nhập môn công nghệ số và ứng dụng trí tuệ nhân tạo', 3, true, 2, '2', 'I', null, false, false),
  ('TMT2100', 'Kĩ năng bổ trợ', 3, true, 3, '3-7', 'I', null, true, false),
  ('PES1001', 'Giáo dục thể chất', 4, true, 2, '2-7', 'I', null, true, false),
  ('DEF1001', 'Giáo dục quốc phòng – an ninh', 8, true, 2, '2-3', 'I', null, true, false),
  ('PSE2008', 'Tâm lí học giáo dục', 4, true, 1, '1', 'II.1', null, false, false),
  ('EAM3002', 'Nhập môn Thống kê ứng dụng trong giáo dục', 3, true, 2, '2', 'II.1', null, false, false),
  ('PSE2004', 'Phương pháp nghiên cứu khoa học trong giáo dục', 3, true, 2, '2', 'II.1', null, false, false),
  ('EDM2013', 'Nhập môn Khoa học quản lý trong giáo dục', 2, true, 1, '1', 'II.1', null, false, false),
  ('EDT2001', 'Nhập môn Công nghệ giáo dục', 2, true, 1, '1', 'II.1', null, false, false),
  ('EAM2052', 'Nhập môn đo lường và đánh giá trong giáo dục', 2, true, 1, '1', 'II.1', null, false, false),
  ('TMT3013', 'Đạo đức nghề nghiệp trong lĩnh vực giáo dục', 4, true, 1, '1-8', 'II.1', null, false, false),
  ('PSE2006', 'Tư vấn tâm lý học đường', 3, false, 3, '3', 'II.2', null, false, false),
  ('PSE2009', 'Nhập môn Khoa học giáo dục', 3, false, 2, '2', 'II.2', null, false, true),
  ('EDM2002', 'Quản lý hành chính nhà nước và quản lý ngành giáo dục và đào tạo', 3, false, 2, '2', 'II.2', null, false, false),
  ('MNS2064', 'Hành chính học đại cương', 3, true, 3, '3', 'III.1', null, false, false),
  ('SCA1002', 'Đại cương về Quản trị trường học', 3, true, 3, '3', 'III.1', null, false, false),
  ('SCA1006', 'Lý thuyết hành chính trong các tổ chức giáo dục', 3, true, 4, '4', 'III.1', null, false, false),
  ('EDM1006', 'Xã hội học giáo dục', 2, false, 3, '3', 'III.2', null, false, true),
  ('EDM2003', 'Kinh tế học giáo dục', 3, false, 3, '3', 'III.2', null, false, true),
  ('EDM1002', 'Tư duy thiết kế cho việc lãnh đạo và học tập', 2, false, 3, '3', 'III.2', null, false, false),
  ('SCA2014', 'Quản trị truyền thông và quan hệ công chúng trong nhà trường', 3, false, 3, '3', 'III.2', null, false, false),
  ('SCA3013', 'Giám sát hoạt động dạy học và giáo dục trong nhà trường', 3, false, 3, '3', 'III.2', null, false, true),
  ('SCA1007', 'Nghiên cứu so sánh hệ thống đa cấp trong quản trị nhà trường', 3, false, 3, '3', 'III.2', null, false, false),
  ('SCA3035', 'Xây dựng môi trường giáo dục', 2, false, 3, '3', 'III.2', null, false, true),
  ('SCA2001', 'Ứng dụng tâm lý học trong quản trị nhà trường', 3, true, 4, '4', 'IV.1', null, false, false),
  ('EDM2004', 'Lý luận quản lý và quản lý giáo dục', 3, true, 4, '4', 'IV.1', null, false, false),
  ('SCA2015', 'Quản trị chương trình nhà trường', 3, true, 5, '5', 'IV.1', null, false, false),
  ('SCA2004', 'Quản trị chiến lược trong nhà trường', 3, false, 5, '5', 'IV.2', null, false, true),
  ('SCA2006', 'Ứng dụng công nghệ thông tin trong quản trị nhà trường', 3, false, 4, '4', 'IV.2', null, false, false),
  ('SCA2008', 'Xây dựng văn hóa nhà trường', 3, false, 4, '4', 'IV.2', null, false, true),
  ('SCA2009', 'Kỹ năng quản trị trường học 1', 3, false, 4, '4', 'IV.2', null, false, true),
  ('SCA2010', 'Kỹ năng quản trị trường học 2', 3, false, 4, '4', 'IV.2', null, false, false),
  ('SCA2011', 'Kỹ năng quản trị trường học 3', 3, false, 4, '4', 'IV.2', null, false, false),
  ('SCA3018', 'Quản trị và phát triển nguồn nhân lực trong nhà trường', 3, true, 5, '5', 'V.1', null, false, false),
  ('SCA3019', 'Quản trị tài chính trong nhà trường', 3, true, 6, '6', 'V.1', null, false, false),
  ('SCA3020', 'Quản trị cơ sở vật chất trong nhà trường', 3, true, 5, '5', 'V.1', null, false, false),
  ('SCA3021', 'Quản trị chất lượng và trách nhiệm giải trình trong giáo dục', 3, true, 7, '7', 'V.1', null, false, false),
  ('SCA3022', 'Tiếng Anh chuyên ngành Quản trị trường học', 3, true, 5, '5', 'V.1', null, false, false),
  ('SCA3009', 'Quản trị thương hiệu và Marketing của nhà trường', 3, true, 6, '6', 'V.1', null, false, false),
  ('SCA3017', 'Kỹ năng quản trị nhà trường hiệu quả', 3, true, 6, '6', 'V.1', null, false, false),
  ('EDM3009', 'Huy động cộng đồng phát triển giáo dục', 3, false, 5, '5', 'V.2', null, false, true),
  ('SCA3010', 'Lãnh đạo sáng tạo', 3, false, 6, '6', 'V.2', null, false, true),
  ('EDM2006', 'Hệ thống giáo dục quốc dân và cơ sở pháp lý trong quản lý giáo dục', 3, false, 5, '5', 'V.2', null, false, false),
  ('SCA3016', 'Hệ thống thông tin quản trị nhà trường', 3, false, 6, '6', 'V.2', null, false, false),
  ('SCA3002', 'Chính sách và thực thi quản trị trường học', 3, false, 7, '7', 'V.3.1', 1, false, false),
  ('SCA2012', 'Kỹ thuật điều hành nhà trường', 3, false, 7, '7', 'V.3.1', 1, false, true),
  ('SCA3033', 'Quản lý và thực thi văn bản hành chính nhà nước trong lĩnh vực giáo dục', 3, false, 7, '7', 'V.3.1', 1, false, true),
  ('SCA3023', 'Văn thư lưu trữ quản trị trường học', 3, false, 7, '7', 'V.3.1', 1, false, true),
  ('SCA3024', 'Nghi thức văn phòng và lễ tân', 3, false, 8, '8', 'V.3.1', 1, false, true),
  ('SCA3025', 'Quản trị tổ chức sự kiện', 3, false, 8, '8', 'V.3.1', 1, false, false),
  ('SCA3026', 'Kỹ năng soạn thảo văn bản hành chính', 3, false, 7, '7', 'V.3.1', 1, false, false),
  ('SCA3027', 'Truyền thông và xây dựng thương hiệu nhà trường', 3, false, 7, '7', 'V.3.1', 1, false, false),
  ('SCA3007', 'Tư vấn hướng nghiệp trong nhà trường', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3008', 'Quản trị dự án trong giáo dục', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3028', 'Quản trị phát triển chuyên môn giáo viên', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3029', 'Tạo động lực trong tổ chức giáo dục', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3030', 'Quản trị sự thay đổi trong tổ chức giáo dục', 3, false, 8, '8', 'V.3.2', 2, false, true),
  ('SCA3031', 'Hành vi tổ chức', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('EDM3011', 'Văn hóa tổ chức và truyền thông nội bộ trong trường học', 3, false, 7, '7', 'V.3.2', 2, false, false),
  ('EDM3013', 'Phân tích và quản trị thực hiện công việc', 3, false, 8, '8', 'V.3.2', 2, false, false),
  ('TMT3009', 'Lý luận dạy học', 3, false, 7, '7', 'V.3.3', 3, false, false),
  ('PSE2005', 'Tổ chức các hoạt động giáo dục trong nhà trường', 3, false, 7, '7', 'V.3.3', 3, false, false),
  ('EDM3014', 'Thiết kế và phát triển chương trình giảng dạy', 3, false, 7, '7', 'V.3.3', 3, false, true),
  ('EDM3015', 'Huy động cộng đồng phát triển chương trình giáo dục nhà trường', 3, false, 7, '7', 'V.3.3', 3, false, true),
  ('EDM3016', 'Khởi nghiệp trong giáo dục', 3, false, 8, '8', 'V.3.3', 3, false, true),
  ('EDM3017', 'Thực thi chương trình giáo dục trong nhà trường', 3, false, 8, '8', 'V.3.3', 3, false, false),
  ('SCA3032', 'Đánh giá chương trình giáo dục', 3, false, 7, '7', 'V.3.3', 3, false, true),
  ('SCA3034', 'Phân tích chương trình giáo dục', 3, false, 7, '7', 'V.3.3', 3, false, true),
  ('SCA3050', 'Thực tập nghiệp vụ 1', 3, true, 6, '6', 'V.4', null, false, false),
  ('SCA3051', 'Thực tập nghiệp vụ 2', 4, true, 7, '7', 'V.4', null, false, false),
  ('SCA4003', 'Khóa luận tốt nghiệp', 6, false, 8, '8', 'V.4G', null, false, false),
  ('SCA4004', 'Thực hành quản trị trường học', 3, false, 8, '8', 'V.4G', null, false, false),
  ('SCA4005', 'Nghiệp vụ Quản lý hành chính trong cơ sở giáo dục', 3, false, 8, '8', 'V.4G', null, false, false);

update public.courses c
set block_name = b.name
from public.curriculum_blocks b
where b.key = c.block;

insert into public.settings (key, value) values
  ('current_term', '20261'),
  ('demo_student_code', '2023001');

-- ==================== 5) TÀI KHOẢN MẶC ĐỊNH (mật khẩu 123456) ====================
do $$
declare rec record; uid uuid;
begin
  for rec in select * from (values
      ('admin@qlgd.edu.vn',     'admin',     'TS. Nguyễn Quốc Toàn (Quản trị)'),
      ('dean@qlgd.edu.vn',      'dean',      'PGS.TS. Nguyễn Văn Khoa'),
      ('assistant@qlgd.edu.vn', 'assistant', 'CN. Lê Thị Đào'),
      ('advisor1@qlgd.edu.vn',  'advisor',   'TS. Trần Quốc Việt')
    ) as t(email, role, full_name)
  loop
    if not exists (select 1 from auth.users where email = rec.email) then
      uid := gen_random_uuid();
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at,
        confirmation_token, recovery_token, email_change, email_change_token_new,
        raw_app_meta_data, raw_user_meta_data
      ) values (
        '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
        rec.email, crypt('123456', gen_salt('bf')),
        now(), now(), now(), '', '', '', '',
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('full_name', rec.full_name, 'role', rec.role,
          'username', split_part(rec.email, '@', 1))
      );
      begin
        insert into auth.identities (provider_id, user_id, identity_data, provider,
          last_sign_in_at, created_at, updated_at)
        values (uid::text, uid, jsonb_build_object('sub', uid::text, 'email', rec.email),
          'email', now(), now(), now());
      exception when others then null; end;
      insert into public.profiles (id, username, role, full_name, active)
      values (uid, split_part(rec.email, '@', 1), rec.role::public.app_role, rec.full_name, true)
      on conflict (id) do update
        set role = excluded.role, full_name = excluded.full_name, active = true;
    end if;
  end loop;
end $$;

-- ==================== Ảnh đại diện (Storage) ====================
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
