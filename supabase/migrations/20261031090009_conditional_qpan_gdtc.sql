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

-- Đã thu hẹp: chỉ PES1001 và DEF1001 (xem 20261031090011).
update public.courses
set conditional = true
where conditional = false
  and upper(code) in ('PES1001', 'DEF1001');
