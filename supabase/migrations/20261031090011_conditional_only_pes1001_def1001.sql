-- ============================================================================
-- Chỉ PES1001 (Giáo dục thể chất) và DEF1001 (Giáo dục quốc phòng – an ninh)
-- là học phần ĐIỀU KIỆN trong nhóm GDTC/GDQP-AN: chỉ xét Đạt/Không đạt, không
-- tính vào điểm TB học kỳ, CPA và tín chỉ tích lũy.
--
-- Migration 20261031090009 đánh dấu rộng theo mẫu (DEF%, PES%, tên chứa
-- "quốc phòng"/"thể chất") nên có thể đã bật nhầm học phần khác; migration này
-- trả các học phần đó về học phần tính điểm bình thường. Chạy lại nhiều lần
-- vẫn cho cùng kết quả. Các học phần điều kiện khác (vd TMT2100 Kĩ năng bổ
-- trợ) không bị ảnh hưởng.
-- ============================================================================

update public.courses
set conditional = (upper(code) in ('PES1001', 'DEF1001'))
where upper(code) in ('PES1001', 'DEF1001')
   or code ilike 'DEF%'
   or code ilike 'PES%'
   or name ilike '%quốc phòng%'
   or name ilike '%thể chất%';
