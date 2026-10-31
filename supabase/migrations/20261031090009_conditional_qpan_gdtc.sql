-- ============================================================================
-- Học phần Giáo dục quốc phòng – an ninh (GDQP-AN) và Giáo dục thể chất
-- (GDTC) là học phần ĐIỀU KIỆN: chỉ xét Đạt/Không đạt, không tính vào điểm TB
-- học kỳ, CPA và tín chỉ tích lũy (ứng dụng ≥ 1.1.6 và view
-- effective_enrollments đều dựa vào cột courses.conditional).
--
-- Đánh dấu mọi học phần thuộc hai nhóm này, kể cả học phần được thêm vào
-- chương trình đào tạo sau dữ liệu mẫu (vd GDQP-AN tách thành nhiều học phần)
-- mà quản trị quên bật "Điều kiện".
-- ============================================================================

update public.courses
set conditional = true
where conditional = false
  and (code ilike 'DEF%'
       or code ilike 'PES%'
       or name ilike '%quốc phòng%'
       or name ilike '%thể chất%');
