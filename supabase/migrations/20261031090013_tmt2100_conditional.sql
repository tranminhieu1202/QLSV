-- ============================================================================
-- TMT2100 Kĩ năng bổ trợ là học phần điều kiện: chỉ xét Đạt / Không đạt,
-- không tính vào điểm TB, CPA, tín chỉ tích lũy. Giữ đúng tên theo QĐ 2676
-- (kể cả nếu bản nháp trước đã đổi tên thành "... (Tin học cơ sở)").
-- Chạy lại vẫn an toàn.
-- ============================================================================

update public.courses
set name = 'Kĩ năng bổ trợ',
    conditional = true
where code = 'TMT2100';
