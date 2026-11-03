-- ============================================================================
-- Bảng điểm ẢO cho sinh viên demo 99010001 (tài khoản cho Apple App Review).
-- Dán vào Supabase → SQL Editor → Run. Chạy lại bao nhiêu lần cũng được:
-- mỗi lần xoá điểm cũ của sinh viên demo rồi tạo lại. KHÔNG đụng sinh viên khác.
--
-- Khóa QH-2025 theo kế hoạch đào tạo:
--   HK1 2025–2026 (20251) = học kỳ 1, HK2 2025–2026 (20252) = học kỳ 2: có điểm
--   HK1 2026–2027 (20261) = học kỳ 3 (kỳ hiện tại): đang học, chưa có điểm
-- Học phần điều kiện (GDTC, GDQP-AN): Đạt. Có 1 học phần điểm D để màn cảnh
-- báo / điểm chữ có dữ liệu đa dạng.
-- ============================================================================

do $$
declare
  v_sid bigint;
  v_advisor uuid;
begin
  select id into v_sid from public.students where student_code = '99010001';
  if v_sid is null then
    raise exception 'Chưa có sinh viên 99010001 – hãy tạo trong app trước.';
  end if;

  -- 1) Đưa sinh viên demo về lớp riêng DEMO, CVHT = appreview (nếu có), để
  --    không lẫn vào thống kê của lớp thật.
  --    SQL Editor không đăng nhập như quản trị trong app nên trigger
  --    students_guard chặn đổi lớp; tắt tạm trigger này rồi bật lại ngay. Cả
  --    khối DO là một giao dịch: lỗi ở đâu thì mọi thứ (kể cả việc tắt
  --    trigger) đều được hoàn tác.
  select id into v_advisor from public.profiles where username = 'appreview';
  if v_advisor is not null then
    alter table public.students disable trigger students_guard;
    begin
      insert into public.class_advisors (class_name, advisor_id)
      values ('DEMO', v_advisor)
      on conflict (class_name) do update set advisor_id = excluded.advisor_id;
    exception when undefined_table then
      null; -- chưa chạy migration phân lớp: gán trực tiếp ở dưới
    end;
    update public.students
    set class_name = 'DEMO', cohort = 'QH-2025', enroll_year = 2025,
        advisor_id = v_advisor
    where id = v_sid;
    alter table public.students enable trigger students_guard;
  end if;

  -- 2) Xoá điểm cũ của sinh viên demo.
  delete from public.enrollments where student_id = v_sid;

  -- 3) Học kỳ 1 và 2: có điểm. Điểm 6,0–9,4 cố định theo mã học phần (chạy lại
  --    vẫn ra cùng điểm). Tự chọn: chỉ lấy đủ số TC cần của khối.
  insert into public.enrollments
    (student_id, course_id, term, status, approval, midterm, final_exam)
  select v_sid, c.id,
         case c.planned_semester when 1 then '20251' else '20252' end,
         'studying', 'approved', null,
         case
           when c.conditional then 10                        -- Đạt
           when c.code = 'EAM3002' then 5.2                  -- điểm D
           else round((6 + (abs(hashtext(c.code)) % 35) / 10.0)::numeric, 1)
         end
  from public.courses c
  where c.planned_semester in (1, 2)
    and (c.mandatory or c.code in ('PSE2009'));          -- tự chọn II.2: 3 TC

  -- 4) Học kỳ 3 (kỳ hiện tại): đang học.
  insert into public.enrollments
    (student_id, course_id, term, status, approval, midterm, final_exam)
  select v_sid, c.id, '20261', 'studying', 'approved', null, null
  from public.courses c
  where c.planned_semester = 3
    and (c.mandatory or c.code in ('EDM1006', 'EDM2003', 'EDM1002'));
end $$;

-- Kiểm tra kết quả
select e.term, c.code, c.name, c.credits, e.grade10, e.grade_letter, e.grade4,
       e.status
from public.enrollments e
join public.courses c on c.id = e.course_id
join public.students s on s.id = e.student_id
where s.student_code = '99010001'
order by e.term, c.code;
