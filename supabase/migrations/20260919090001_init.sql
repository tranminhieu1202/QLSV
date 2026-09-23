-- ============================================================================
-- QLGD EDU · Backend schema (PostgreSQL / Supabase)
-- Nguồn sự thật cho ~2.000 SV (mở rộng tới 5.000).
-- Khóa chính UUID, tích hợp auth.users, timestamps, tính điểm server-side.
-- ============================================================================

create extension if not exists pgcrypto;

-- 5 vai trò: quản trị / ban chủ nhiệm khoa / trợ lý quản trị / cố vấn / sinh viên
create type public.app_role as enum ('admin', 'dean', 'assistant', 'advisor', 'student');

-- ---------------------------------------------------------------- profiles
-- Mỗi tài khoản đăng nhập (auth.users) có 1 hồ sơ vai trò tương ứng.
create table public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text unique,
  role         public.app_role not null default 'student',
  full_name    text not null default '',
  student_code text,
  active       boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- ---------------------------------------------------------------- courses
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

-- Yêu cầu tín chỉ theo từng khối kiến thức (phục vụ tính tổng CTĐT server-side).
create table public.curriculum_blocks (
  key        text primary key,
  name       text not null,
  kind       text not null check (kind in ('mandatory', 'elective', 'direction', 'grad')),
  quota      int not null default 0,
  sort_order int not null default 0
);

-- ---------------------------------------------------------------- students
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

-- ---------------------------------------------------------------- enrollments
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

-- ---------------------------------------------------- profile change requests
-- Trợ lý quản trị đề xuất sửa hồ sơ -> chờ quản trị phê duyệt.
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

-- ---------------------------------------------------------------- settings
create table public.settings (
  key   text primary key,
  value text
);

-- ---------------------------------------------------------------- audit log
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

-- ============================================================================
-- Triggers & functions
-- ============================================================================

-- updated_at tự động
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

-- ------------------------------------------------------ thang điểm (chuẩn hoá)
-- Điểm tổng kết hệ 10 = GK*0.3 + CK*0.7 (nếu chưa có GK thì lấy CK).
create or replace function public.grade_overall(p_midterm numeric, p_final numeric)
returns numeric language sql immutable as $$
  select round(
    case when p_midterm is null then p_final
         else p_midterm * 0.3 + p_final * 0.7 end::numeric, 1);
$$;

create or replace function public.grade_letter(g10 numeric)
returns text language sql immutable as $$
  select case
    when g10 >= 9.5 then 'A+'
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
    when g10 >= 8.5 then 4.0
    when g10 >= 8.0 then 3.5
    when g10 >= 7.0 then 3.0
    when g10 >= 6.5 then 2.5
    when g10 >= 5.5 then 2.0
    when g10 >= 5.0 then 1.5
    when g10 >= 4.0 then 1.0
    else 0.0 end::numeric;
$$;

-- Điểm tổng kết / chữ / hệ 4 / trạng thái được TÍNH TẠI SERVER, không nhận
-- từ client (client chỉ gửi điểm giữa kì & cuối kì).
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

-- ------------------------------------------------ tạo profile khi có user mới
-- Vai trò / họ tên / MSSV lấy từ metadata khi tạo tài khoản.
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
