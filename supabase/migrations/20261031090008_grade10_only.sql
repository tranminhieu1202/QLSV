-- ============================================================================
-- Sinh viên chỉ nhập ĐIỂM TỔNG KẾT HỌC PHẦN (hệ 10) – điểm cuối cùng trên bảng
-- điểm, lưu ở cột final_exam. Bỏ nhập điểm thành phần.
--
-- Lý do: công thức cũ GK×0,3 + CK×0,7 sai. Điểm học phần thực tế gồm điểm
-- thường xuyên, giữa kì và cuối kì với trọng số theo đề cương từng học phần,
-- nên ứng dụng không tự tính được – sinh viên nhập thẳng điểm tổng kết.
--
-- Bản ứng dụng cũ (≤ 1.1.4) còn gửi điểm giữa kì: máy chủ từ chối để không
-- lưu thêm điểm tính sai, và báo người dùng cập nhật ứng dụng.
-- ============================================================================

create or replace function public.grade_overall(p_midterm numeric, p_final numeric)
returns numeric language sql immutable as $$
  select round(p_final, 1);
$$;

create or replace function public.tg_apply_grade()
returns trigger language plpgsql as $$
begin
  if new.midterm is not null then
    raise exception using
      errcode = 'P0001',
      message = 'Ứng dụng đã đổi cách nhập điểm: chỉ nhập điểm tổng kết học '
                'phần (hệ 10). Hãy cập nhật ứng dụng lên phiên bản mới nhất.';
  end if;
  if new.final_exam is null then
    new.grade10 := null;
    new.grade_letter := null;
    new.grade4 := null;
    if new.status is null or new.status in ('passed', 'failed') then
      new.status := 'studying';
    end if;
  else
    new.grade10 := round(new.final_exam, 1);
    new.grade_letter := public.grade_letter(new.grade10);
    new.grade4 := public.grade_four(new.grade10);
    new.status := case when new.grade10 >= 4.0 then 'passed' else 'failed' end;
  end if;
  return new;
end;
$$;

-- Học phần đã nhập theo điểm thành phần có điểm tổng kết tính bằng công thức
-- sai: đưa về "Chưa có điểm" (giữ học phần và học kỳ) để sinh viên nhập lại
-- điểm tổng kết. Trigger apply_grade xoá grade10/chữ/hệ 4 và đặt "đang học".
update public.enrollments
set midterm = null,
    final_exam = null
where midterm is not null;
