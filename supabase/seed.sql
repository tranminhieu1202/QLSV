-- ============================================================================
-- Seed dữ liệu nền (chỉ dùng cho môi trường dev / `supabase db reset`).
-- Trên cloud: tạo tài khoản qua Auth API/Dashboard, không insert auth.users.
-- ============================================================================

-- ------------------------------------------------- khối kiến thức (yêu cầu TC)
insert into public.curriculum_blocks (key, name, kind, quota, sort_order) values
  ('I',     'I. Khối kiến thức chung',                                         'mandatory', 0, 1),
  ('II.1',  'II. Kiến thức theo lĩnh vực (bắt buộc)',                          'mandatory', 0, 2),
  ('II.2',  'II. Kiến thức theo lĩnh vực (tự chọn)',                           'elective',  3, 3),
  ('III.1', 'III. Kiến thức theo khối ngành (bắt buộc)',                       'mandatory', 0, 4),
  ('III.2', 'III. Kiến thức theo khối ngành (tự chọn)',                        'elective',  7, 5),
  ('IV.1',  'IV. Kiến thức theo nhóm ngành (bắt buộc)',                        'mandatory', 0, 6),
  ('IV.2',  'IV. Kiến thức theo nhóm ngành (tự chọn)',                         'elective',  9, 7),
  ('V.1',   'V. Kiến thức ngành (bắt buộc)',                                   'mandatory', 0, 8),
  ('V.2',   'V. Kiến thức ngành (tự chọn chung)',                              'elective',  6, 9),
  ('V.3.1', 'V.3. Hướng ngành 1: Quản trị hành chính nhà trường',             'direction', 12, 10),
  ('V.3.2', 'V.3. Hướng ngành 2: Quản trị nhân lực và đào tạo',               'direction', 12, 11),
  ('V.3.3', 'V.3. Hướng ngành 3: Phát triển và quản lý chương trình giáo dục', 'direction', 12, 12),
  ('V.4',   'V.4. Thực tập nghiệp vụ',                                         'mandatory', 0, 13),
  ('V.4G',  'V.4. Khóa luận / Học phần thay thế tốt nghiệp',                   'grad',      6, 14);

-- ---------------------------------------------------------------- học phần
insert into public.courses
  (code, name, credits, mandatory, planned_semester, semester_text, block, direction, conditional, oriented)
values
  ('PHI1006', 'Triết học Mác – Lênin', 3, true, 1, '1', 'I', null, false, false),
  ('PEC1008', 'Kinh tế chính trị Mác – Lênin', 2, true, 1, '1', 'I', null, false, false),
  ('PHI1002', 'Chủ nghĩa xã hội khoa học', 2, true, 3, '3', 'I', null, false, false),
  ('HIS1001', 'Lịch sử Đảng Cộng sản Việt Nam', 2, true, 4, '4', 'I', null, false, false),
  ('POL1001', 'Tư tưởng Hồ Chí Minh', 2, true, 2, '2', 'I', null, false, false),
  ('THL1057', 'Nhà nước và Pháp luật đại cương', 2, true, 2, '2', 'I', null, false, false),
  ('FLF1101', 'Ngoại ngữ B1', 5, true, 2, '2-4', 'I', null, false, false),
  ('VNU1001', 'Nhập môn công nghệ số và ứng dụng trí tuệ nhân tạo', 3, true, 2, '2', 'I', null, false, false),
  ('TMT2100', 'Kĩ năng bổ trợ', 3, true, 3, '3-7', 'I', null, true, false),
  ('PES1001', 'Giáo dục thể chất', 4, true, 2, '2-7', 'I', null, true, false),
  ('DEF1001', 'Giáo dục quốc phòng – an ninh', 8, true, 2, '2-3', 'I', null, true, false),

  ('PSE2008', 'Tâm lí học giáo dục', 4, true, 1, '1', 'II.1', null, false, false),
  ('EAM3002', 'Nhập môn Thống kê ứng dụng trong giáo dục', 3, true, 2, '2', 'II.1', null, false, false),
  ('PSE2004', 'Phương pháp nghiên cứu khoa học trong giáo dục', 3, true, 2, '2', 'II.1', null, false, false),
  ('EDM2013', 'Nhập môn Khoa học quản lý trong giáo dục', 2, true, 1, '1', 'II.1', null, false, false),
  ('EDT2001', 'Nhập môn Công nghệ giáo dục', 2, true, 1, '1', 'II.1', null, false, false),
  ('EAM2052', 'Nhập môn đo lường và đánh giá trong giáo dục', 2, true, 1, '1', 'II.1', null, false, false),
  ('TMT3013', 'Đạo đức nghề nghiệp trong lĩnh vực giáo dục', 4, true, 1, '1-8', 'II.1', null, false, false),

  ('PSE2006', 'Tư vấn tâm lý học đường', 3, false, 3, '3', 'II.2', null, false, false),
  ('PSE2009', 'Nhập môn Khoa học giáo dục', 3, false, 2, '2', 'II.2', null, false, true),
  ('EDM2002', 'Quản lý hành chính nhà nước và quản lý ngành giáo dục và đào tạo', 3, false, 2, '2', 'II.2', null, false, false),

  ('MNS2064', 'Hành chính học đại cương', 3, true, 3, '3', 'III.1', null, false, false),
  ('SCA1002', 'Đại cương về Quản trị trường học', 3, true, 3, '3', 'III.1', null, false, false),
  ('SCA1006', 'Lý thuyết hành chính trong các tổ chức giáo dục', 3, true, 4, '4', 'III.1', null, false, false),

  ('EDM1006', 'Xã hội học giáo dục', 2, false, 3, '3', 'III.2', null, false, true),
  ('EDM2003', 'Kinh tế học giáo dục', 3, false, 3, '3', 'III.2', null, false, true),
  ('EDM1002', 'Tư duy thiết kế cho việc lãnh đạo và học tập', 2, false, 3, '3', 'III.2', null, false, false),
  ('SCA2014', 'Quản trị truyền thông và quan hệ công chúng trong nhà trường', 3, false, 3, '3', 'III.2', null, false, false),
  ('SCA3013', 'Giám sát hoạt động dạy học và giáo dục trong nhà trường', 3, false, 3, '3', 'III.2', null, false, true),
  ('SCA1007', 'Nghiên cứu so sánh hệ thống đa cấp trong quản trị nhà trường', 3, false, 3, '3', 'III.2', null, false, false),
  ('SCA3035', 'Xây dựng môi trường giáo dục', 2, false, 3, '3', 'III.2', null, false, true),

  ('SCA2001', 'Ứng dụng tâm lý học trong quản trị nhà trường', 3, true, 4, '4', 'IV.1', null, false, false),
  ('EDM2004', 'Lý luận quản lý và quản lý giáo dục', 3, true, 4, '4', 'IV.1', null, false, false),
  ('SCA2015', 'Quản trị chương trình nhà trường', 3, true, 5, '5', 'IV.1', null, false, false),

  ('SCA2004', 'Quản trị chiến lược trong nhà trường', 3, false, 5, '5', 'IV.2', null, false, true),
  ('SCA2006', 'Ứng dụng công nghệ thông tin trong quản trị nhà trường', 3, false, 4, '4', 'IV.2', null, false, false),
  ('SCA2008', 'Xây dựng văn hóa nhà trường', 3, false, 4, '4', 'IV.2', null, false, true),
  ('SCA2009', 'Kỹ năng quản trị trường học 1', 3, false, 4, '4', 'IV.2', null, false, true),
  ('SCA2010', 'Kỹ năng quản trị trường học 2', 3, false, 4, '4', 'IV.2', null, false, false),
  ('SCA2011', 'Kỹ năng quản trị trường học 3', 3, false, 4, '4', 'IV.2', null, false, false),

  ('SCA3018', 'Quản trị và phát triển nguồn nhân lực trong nhà trường', 3, true, 5, '5', 'V.1', null, false, false),
  ('SCA3019', 'Quản trị tài chính trong nhà trường', 3, true, 6, '6', 'V.1', null, false, false),
  ('SCA3020', 'Quản trị cơ sở vật chất trong nhà trường', 3, true, 5, '5', 'V.1', null, false, false),
  ('SCA3021', 'Quản trị chất lượng và trách nhiệm giải trình trong giáo dục', 3, true, 7, '7', 'V.1', null, false, false),
  ('SCA3022', 'Tiếng Anh chuyên ngành Quản trị trường học', 3, true, 5, '5', 'V.1', null, false, false),
  ('SCA3009', 'Quản trị thương hiệu và Marketing của nhà trường', 3, true, 6, '6', 'V.1', null, false, false),
  ('SCA3017', 'Kỹ năng quản trị nhà trường hiệu quả', 3, true, 6, '6', 'V.1', null, false, false),

  ('EDM3009', 'Huy động cộng đồng phát triển giáo dục', 3, false, 5, '5', 'V.2', null, false, true),
  ('SCA3010', 'Lãnh đạo sáng tạo', 3, false, 6, '6', 'V.2', null, false, true),
  ('EDM2006', 'Hệ thống giáo dục quốc dân và cơ sở pháp lý trong quản lý giáo dục', 3, false, 5, '5', 'V.2', null, false, false),
  ('SCA3016', 'Hệ thống thông tin quản trị nhà trường', 3, false, 6, '6', 'V.2', null, false, false),

  ('SCA3002', 'Chính sách và thực thi quản trị trường học', 3, false, 7, '7', 'V.3.1', 1, false, false),
  ('SCA2012', 'Kỹ thuật điều hành nhà trường', 3, false, 7, '7', 'V.3.1', 1, false, true),
  ('SCA3033', 'Quản lý và thực thi văn bản hành chính nhà nước trong lĩnh vực giáo dục', 3, false, 7, '7', 'V.3.1', 1, false, true),
  ('SCA3023', 'Văn thư lưu trữ quản trị trường học', 3, false, 7, '7', 'V.3.1', 1, false, true),
  ('SCA3024', 'Nghi thức văn phòng và lễ tân', 3, false, 8, '8', 'V.3.1', 1, false, true),
  ('SCA3025', 'Quản trị tổ chức sự kiện', 3, false, 8, '8', 'V.3.1', 1, false, false),
  ('SCA3026', 'Kỹ năng soạn thảo văn bản hành chính', 3, false, 7, '7', 'V.3.1', 1, false, false),
  ('SCA3027', 'Truyền thông và xây dựng thương hiệu nhà trường', 3, false, 7, '7', 'V.3.1', 1, false, false),

  ('SCA3007', 'Tư vấn hướng nghiệp trong nhà trường', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3008', 'Quản trị dự án trong giáo dục', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3028', 'Quản trị phát triển chuyên môn giáo viên', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3029', 'Tạo động lực trong tổ chức giáo dục', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('SCA3030', 'Quản trị sự thay đổi trong tổ chức giáo dục', 3, false, 8, '8', 'V.3.2', 2, false, true),
  ('SCA3031', 'Hành vi tổ chức', 3, false, 7, '7', 'V.3.2', 2, false, true),
  ('EDM3011', 'Văn hóa tổ chức và truyền thông nội bộ trong trường học', 3, false, 7, '7', 'V.3.2', 2, false, false),
  ('EDM3013', 'Phân tích và quản trị thực hiện công việc', 3, false, 8, '8', 'V.3.2', 2, false, false),

  ('TMT3009', 'Lý luận dạy học', 3, false, 7, '7', 'V.3.3', 3, false, false),
  ('PSE2005', 'Tổ chức các hoạt động giáo dục trong nhà trường', 3, false, 7, '7', 'V.3.3', 3, false, false),
  ('EDM3014', 'Thiết kế và phát triển chương trình giảng dạy', 3, false, 7, '7', 'V.3.3', 3, false, true),
  ('EDM3015', 'Huy động cộng đồng phát triển chương trình giáo dục nhà trường', 3, false, 7, '7', 'V.3.3', 3, false, true),
  ('EDM3016', 'Khởi nghiệp trong giáo dục', 3, false, 8, '8', 'V.3.3', 3, false, true),
  ('EDM3017', 'Thực thi chương trình giáo dục trong nhà trường', 3, false, 8, '8', 'V.3.3', 3, false, false),
  ('SCA3032', 'Đánh giá chương trình giáo dục', 3, false, 7, '7', 'V.3.3', 3, false, true),
  ('SCA3034', 'Phân tích chương trình giáo dục', 3, false, 7, '7', 'V.3.3', 3, false, true),

  ('SCA3050', 'Thực tập nghiệp vụ 1', 3, true, 6, '6', 'V.4', null, false, false),
  ('SCA3051', 'Thực tập nghiệp vụ 2', 4, true, 7, '7', 'V.4', null, false, false),
  ('SCA4003', 'Khóa luận tốt nghiệp', 6, false, 8, '8', 'V.4G', null, false, false),
  ('SCA4004', 'Thực hành quản trị trường học', 3, false, 8, '8', 'V.4G', null, false, false),
  ('SCA4005', 'Nghiệp vụ Quản lý hành chính trong cơ sở giáo dục', 3, false, 8, '8', 'V.4G', null, false, false);

-- tên khối cho từng học phần
update public.courses c
set block_name = b.name
from public.curriculum_blocks b
where b.key = c.block;

-- ---------------------------------------------------------------- settings
insert into public.settings (key, value) values
  ('current_term', '20261'),
  ('reg_open', '1'),
  ('demo_student_code', '2023001');

-- ============================================================================
-- Tài khoản demo (mật khẩu: 123456). Chỉ chạy khi reset DB local.
-- ============================================================================
create or replace function public.seed_user(
  p_email text, p_password text, p_role public.app_role,
  p_name text, p_student_code text default null)
returns uuid language plpgsql as $$
declare
  uid uuid := gen_random_uuid();
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    confirmation_token, recovery_token, email_change, email_change_token_new,
    raw_app_meta_data, raw_user_meta_data
  ) values (
    '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
    p_email, crypt(p_password, gen_salt('bf')),
    now(), now(), now(),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_strip_nulls(jsonb_build_object(
      'full_name', p_name, 'role', p_role::text, 'student_code', p_student_code))
  );

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), uid, uid::text,
    jsonb_build_object('sub', uid::text, 'email', p_email), 'email',
    now(), now(), now()
  );

  return uid;
end;
$$;

do $$
declare
  v_advisor uuid;
  v_s1 bigint;
  v_s2 bigint;
  v_s1_user uuid;
  v_s2_user uuid;
begin
  perform public.seed_user('admin@qlgd.edu.vn', '123456', 'admin', 'TS. Nguyễn Quốc Toàn (Quản trị)');
  perform public.seed_user('dean@qlgd.edu.vn', '123456', 'dean', 'PGS.TS. Nguyễn Văn Khoa');
  perform public.seed_user('assistant@qlgd.edu.vn', '123456', 'assistant', 'CN. Lê Thị Đào');
  v_advisor := public.seed_user('advisor1@qlgd.edu.vn', '123456', 'advisor', 'TS. Trần Quốc Việt');

  v_s1_user := public.seed_user('2023001@sv.qlgd.edu.vn', '123456', 'student', 'Huỳnh Thu Hoa', '2023001');
  v_s2_user := public.seed_user('2022001@sv.qlgd.edu.vn', '123456', 'student', 'Lê Quang Tuấn', '2022001');

  insert into public.students
    (student_code, full_name, cohort, class_name, enroll_year, advisor_id,
     direction, status, phone, birth_date, hometown, email, user_id)
  values
    ('2023001', 'Huỳnh Thu Hoa', 'K2023', 'QTTH 02', 2023, v_advisor,
     1, 'active', '0398855827', '19/04/2005', 'Nghệ An', 'sv2023001@gmail.com', v_s1_user)
  returning id into v_s1;

  insert into public.students
    (student_code, full_name, cohort, class_name, enroll_year, advisor_id,
     direction, status, phone, birth_date, hometown, email, user_id)
  values
    ('2022001', 'Lê Quang Tuấn', 'K2022', 'QTTH 03', 2022, v_advisor,
     2, 'active', '0355667788', '02/01/2004', 'Thanh Hóa', 'sv2022001@gmail.com', v_s2_user)
  returning id into v_s2;

  -- Điểm mẫu (điểm tổng kết/chữ/hệ 4/trạng thái do trigger server tự tính).
  insert into public.enrollments (student_id, course_id, term, midterm, final_exam)
  select v_s1, c.id, '20231', 7.0, 8.0 from public.courses c where c.code = 'PHI1006';
  insert into public.enrollments (student_id, course_id, term, midterm, final_exam)
  select v_s1, c.id, '20231', 3.0, 3.5 from public.courses c where c.code = 'PEC1008';
  insert into public.enrollments (student_id, course_id, term, midterm, final_exam)
  select v_s2, c.id, '20221', 8.0, 9.0 from public.courses c where c.code = 'PHI1006';
  -- Đang học (chưa có điểm cuối kì).
  insert into public.enrollments (student_id, course_id, term, midterm)
  select v_s1, c.id, '20261', 6.0 from public.courses c where c.code = 'MNS2064';
end;
$$;
