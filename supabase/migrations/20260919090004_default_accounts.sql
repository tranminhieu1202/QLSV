-- ============================================================================
-- Tài khoản mặc định ban đầu cho cloud (mật khẩu: 123456).
-- Người dùng tự đổi mật khẩu sau khi đăng nhập (menu → Đổi mật khẩu).
--
-- `seed.sql` KHÔNG chạy trên cloud khi `supabase db push`, nên các tài khoản
-- bootstrap được tạo tại đây để lệnh push tự tạo luôn. Idempotent: chỉ tạo khi
-- email chưa tồn tại, không ghi đè mật khẩu người dùng đã tự đổi.
-- ============================================================================

do $$
declare
  rec record;
  uid uuid;
begin
  for rec in
    select * from (values
      ('admin@qlgd.edu.vn',     'admin',     'TS. Nguyễn Quốc Toàn (Quản trị)'),
      ('dean@qlgd.edu.vn',      'dean',      'PGS.TS. Nguyễn Văn Khoa'),
      ('assistant@qlgd.edu.vn', 'assistant', 'CN. Lê Thị Đào'),
      ('advisor1@qlgd.edu.vn',  'advisor',   'TS. Trần Quốc Việt')
    ) as t(email, role, full_name)
  loop
    if not exists (select 1 from auth.users where email = rec.email) then
      uid := gen_random_uuid();

      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, created_at, updated_at,
        confirmation_token, recovery_token, email_change, email_change_token_new,
        raw_app_meta_data, raw_user_meta_data
      ) values (
        '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
        rec.email, crypt('123456', gen_salt('bf')),
        now(), now(), now(),
        '', '', '', '',
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('full_name', rec.full_name, 'role', rec.role,
          'username', split_part(rec.email, '@', 1))
      );

      -- identity bọc exception để không vỡ nếu schema khác giữa các phiên bản
      begin
        insert into auth.identities (
          provider_id, user_id, identity_data, provider,
          last_sign_in_at, created_at, updated_at
        ) values (
          uid::text, uid,
          jsonb_build_object('sub', uid::text, 'email', rec.email), 'email',
          now(), now(), now()
        );
      exception when others then
        null;
      end;

      -- trigger handle_new_user thường đã tạo profile; chèn an toàn nếu chưa
      insert into public.profiles (id, username, role, full_name, active)
      values (uid, split_part(rec.email, '@', 1), rec.role::public.app_role,
              rec.full_name, true)
      on conflict (id) do update
        set role = excluded.role, full_name = excluded.full_name, active = true;
    end if;
  end loop;
end $$;
