-- ============================================================================
-- 1) Thang điểm theo Quy chế đào tạo đại học tại ĐHQGHN
--    (QĐ 3626/QĐ-ĐHQGHN ngày 21/10/2022, Điều 41 & 43):
--    A+ 9,0–10 → 4,0 · A 8,5–8,9 → 3,7 · B+ 8,0–8,4 → 3,5 · B 7,0–7,9 → 3,0
--    C+ 6,5–6,9 → 2,5 · C 5,5–6,4 → 2,0 · D+ 5,0–5,4 → 1,5 · D 4,0–4,9 → 1,0
--    F < 4,0 → 0.
-- 2) Sinh viên tự khai báo học phần & điểm: bỏ mở/đóng kỳ đăng ký và bước
--    duyệt đăng ký.
-- 3) CPA (điểm TB chung tích lũy) chỉ tính học phần đã đạt, mỗi học phần lấy
--    lần đạt gần nhất (học cải thiện thay điểm cũ – Điều 21, 42).
-- ============================================================================

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

-- Quy đổi lại điểm đã có theo thang mới (trigger apply_grade chỉ chạy khi đổi
-- điểm thành phần nên cập nhật trực tiếp).
update public.enrollments
set grade_letter = public.grade_letter(grade10),
    grade4       = public.grade_four(grade10)
where grade10 is not null;

-- Không còn bước duyệt: các đăng ký đang chờ coi như đã khai báo.
update public.enrollments set approval = 'approved' where approval = 'pending';

-- Không còn mở/đóng kỳ đăng ký.
delete from public.settings where key = 'reg_open';

create or replace view public.student_cpa
with (security_invoker = true) as
select
  student_id,
  round(
    sum(grade4 * credits) filter (where grade4 is not null)
    / nullif(sum(credits) filter (where grade4 is not null), 0), 2) as cpa,
  coalesce(sum(credits), 0) as passed_credits
from (
  select distinct on (student_id, course_id)
    student_id, course_id, grade4, credits
  from public.effective_enrollments
  where status = 'passed'
  order by student_id, course_id, term desc, id desc
) t
group by student_id;
