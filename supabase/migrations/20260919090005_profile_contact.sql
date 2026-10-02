-- ============================================================================
-- Thông tin liên hệ cho hồ sơ (dùng cho tài khoản giảng viên/cán bộ) và cho
-- phép mọi người tự sửa thông tin cá nhân của CHÍNH MÌNH.
-- ============================================================================

alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists email text;

-- Người dùng tự cập nhật hồ sơ của mình (ngoài chính sách admin sẵn có).
drop policy if exists profiles_update_self on public.profiles;
create policy profiles_update_self on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- Chặn người dùng thường tự đổi vai trò / username / trạng thái / MSSV.
create or replace function public.tg_profiles_guard()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then
    return new;
  end if;
  if new.role is distinct from old.role
     or new.username is distinct from old.username
     or new.active is distinct from old.active
     or new.student_code is distinct from old.student_code then
    raise exception 'Chỉ được sửa thông tin cá nhân (họ tên, liên hệ) của chính mình.';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard on public.profiles;
create trigger profiles_guard before update on public.profiles
  for each row execute function public.tg_profiles_guard();
