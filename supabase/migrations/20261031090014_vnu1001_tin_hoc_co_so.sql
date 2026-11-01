-- ============================================================================
-- VNU1001 là học phần Tin học cơ sở: ghi rõ trong tên để sinh viên nhận ra
-- khi khai báo. Vẫn là học phần tính điểm bình thường (không phải điều kiện).
-- Chạy lại vẫn an toàn.
-- ============================================================================

update public.courses
set name = 'Nhập môn công nghệ số và ứng dụng trí tuệ nhân tạo (Tin học cơ sở)'
where code = 'VNU1001';
