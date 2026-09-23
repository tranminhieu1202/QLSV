-- ============================================================================
-- Giá trị học vụ TÍNH TẠI SERVER (nguồn sự thật): GPA kỳ, CPA tích lũy, tín chỉ
-- nợ, tổng quan sinh viên. Client chỉ hiển thị; mọi con số chính thức lấy ở đây.
-- Tất cả view dùng security_invoker để RLS của bảng gốc vẫn áp cho người truy vấn.
-- ============================================================================

-- Đăng ký hợp lệ: đã duyệt và học phần không phải loại điều kiện (GDTC/QP...).
create view public.effective_enrollments
with (security_invoker = true) as
select
  e.id,
  e.student_id,
  e.course_id,
  e.term,
  e.status,
  e.grade4,
  c.credits,
  c.mandatory,
  c.block,
  c.planned_semester
from public.enrollments e
join public.courses c on c.id = e.course_id
where e.approval = 'approved'
  and c.conditional = false;

-- Tổng hợp theo học kỳ.
create view public.student_term_summary
with (security_invoker = true) as
select
  student_id,
  term,
  round(
    sum(grade4 * credits) filter (where grade4 is not null)
    / nullif(sum(credits) filter (where grade4 is not null), 0), 2) as gpa,
  sum(credits)                                    as registered_credits,
  coalesce(sum(credits) filter (where status = 'passed'), 0) as passed_credits,
  coalesce(sum(credits) filter (where status = 'failed'), 0) as debt_credits
from public.effective_enrollments
group by student_id, term;

-- CPA tích lũy toàn khóa.
create view public.student_cpa
with (security_invoker = true) as
select
  student_id,
  round(
    sum(grade4 * credits) filter (where grade4 is not null)
    / nullif(sum(credits) filter (where grade4 is not null), 0), 2) as cpa,
  coalesce(sum(credits) filter (where status = 'passed'), 0) as passed_credits
from public.effective_enrollments
group by student_id;

-- Tín chỉ nợ đọng: học phần từng trượt và CHƯA từng đạt (đếm 1 lần / học phần).
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

-- Tổng quan mỗi SV cho màn hình danh sách của giảng viên (tránh N+1 query).
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
