-- ============================================================================
-- Phân lớp cho cố vấn học tập (CVHT): quản trị gán cả lớp cho một CVHT thay
-- vì sửa từng sinh viên. Máy chủ tự đồng bộ students.advisor_id (RLS của CVHT
-- vẫn dựa vào cột này):
--   - gán / đổi CVHT của lớp → mọi sinh viên lớp đó nhận CVHT mới;
--   - bỏ gán lớp → sinh viên lớp đó không còn CVHT;
--   - thêm sinh viên mới, hoặc chuyển sinh viên sang lớp khác → tự lấy CVHT
--     của lớp (nếu lớp đã được phân).
-- Chạy lại vẫn an toàn.
-- ============================================================================

create table if not exists public.class_advisors (
  class_name  text primary key,
  advisor_id  uuid not null references public.profiles (id) on delete cascade,
  updated_at  timestamptz not null default now()
);
create index if not exists class_advisors_advisor_idx
  on public.class_advisors (advisor_id);

alter table public.class_advisors enable row level security;
drop policy if exists class_advisors_select on public.class_advisors;
create policy class_advisors_select on public.class_advisors
  for select using (auth.uid() is not null);
drop policy if exists class_advisors_write on public.class_advisors;
create policy class_advisors_write on public.class_advisors
  for all using (public.is_admin()) with check (public.is_admin());

-- Đồng bộ sinh viên khi phân / đổi / bỏ lớp.
create or replace function public.tg_class_advisors_sync()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    update public.students set advisor_id = null
    where class_name = old.class_name and advisor_id = old.advisor_id;
    return old;
  end if;
  if tg_op = 'UPDATE' and new.class_name is distinct from old.class_name then
    update public.students set advisor_id = null
    where class_name = old.class_name and advisor_id = old.advisor_id;
  end if;
  update public.students set advisor_id = new.advisor_id
  where class_name = new.class_name
    and advisor_id is distinct from new.advisor_id;
  return new;
end;
$$;

drop trigger if exists class_advisors_sync on public.class_advisors;
create trigger class_advisors_sync
  after insert or update or delete on public.class_advisors
  for each row execute function public.tg_class_advisors_sync();

-- Sinh viên mới / đổi lớp: lấy CVHT của lớp. Chạy trước students_guard theo
-- thứ tự tên trigger ('class...' < 'students...').
create or replace function public.tg_students_class_advisor()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v uuid;
begin
  if tg_op = 'INSERT' or new.class_name is distinct from old.class_name then
    select advisor_id into v from public.class_advisors
    where class_name = new.class_name;
    if found then
      new.advisor_id := v;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists class_advisor_default on public.students;
create trigger class_advisor_default
  before insert or update of class_name on public.students
  for each row execute function public.tg_students_class_advisor();

-- Dữ liệu sẵn có: lớp nào đang chỉ có đúng một CVHT thì ghi nhận luôn.
insert into public.class_advisors (class_name, advisor_id)
select class_name, (array_agg(distinct advisor_id))[1]
from public.students
where advisor_id is not null
group by class_name
having count(distinct advisor_id) = 1
on conflict (class_name) do nothing;

notify pgrst, 'reload schema';
