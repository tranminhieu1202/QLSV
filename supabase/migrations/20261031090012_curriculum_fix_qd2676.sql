-- ============================================================================
-- Đối chiếu chương trình đào tạo với Phụ lục 13, QĐ 2676/QĐ-ĐHGD ngày
-- 24/10/2025 (ngành Quản trị trường học, áp dụng từ khóa 2025) và sửa các
-- điểm lệch: số tín chỉ, học kỳ tổ chức, tên học phần, đánh dấu tự chọn định
-- hướng (*). Chạy lại nhiều lần vẫn cho cùng kết quả.
-- ============================================================================

-- SCA1007: 2 TC (khối III.2 tự chọn có tổng 17 TC = 2+3+2+3+3+2+2).
update public.courses set credits = 2 where code = 'SCA1007';

-- EDM2002 tổ chức ở học kỳ 3.
update public.courses set planned_semester = 3, semester_text = '3'
where code = 'EDM2002';

-- Tên học phần theo đúng quyết định.
update public.courses set name = 'Hệ thống thông tin trong quản trị nhà trường'
where code = 'SCA3016';
update public.courses set name = 'Văn thư lưu trữ trong quản trị trường học'
where code = 'SCA3023';
update public.courses set name = 'Quản trị dự án trong trường học'
where code = 'SCA3008';

-- Các học phần này không có dấu * (không phải tự chọn định hướng).
update public.courses set oriented = false
where code in ('EDM2003', 'SCA3008', 'SCA3029', 'EDM3015');
