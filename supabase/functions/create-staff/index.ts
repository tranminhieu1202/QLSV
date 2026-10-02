// Edge Function: quản trị tạo tài khoản cán bộ (BCN khoa / trợ lý QT / CVHT).
//
// Chỉ vai trò admin được gọi. Dùng service role để tạo user trong auth.
//
// Deploy:  supabase functions deploy create-staff

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

const FACULTY_ROLES = ['dean', 'assistant', 'advisor'];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  try {
    const url = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const authHeader = req.headers.get('Authorization') ?? '';

    const caller = createClient(url, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData } = await caller.auth.getUser();
    const uid = userData?.user?.id;
    if (!uid) return json({ ok: false, error: 'Chưa đăng nhập.' }, 401);

    const { data: profile } = await caller
      .from('profiles')
      .select('role')
      .eq('id', uid)
      .maybeSingle();
    if (profile?.role !== 'admin') {
      return json({ ok: false, error: 'Chỉ quản trị được tạo tài khoản.' }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const username = String(body.username ?? '').trim();
    const fullName = String(body.fullName ?? '').trim();
    const role = String(body.role ?? '').trim();
    const password = String(body.password ?? '123456');
    const phone = body.phone ? String(body.phone).trim() : null;
    const contactEmail = body.email ? String(body.email).trim() : null;

    if (!username || !fullName) {
      return json({ ok: false, error: 'Thiếu tên đăng nhập hoặc họ tên.' });
    }
    if (!FACULTY_ROLES.includes(role)) {
      return json({ ok: false, error: 'Vai trò không hợp lệ.' });
    }
    if (password.length < 6) {
      return json({ ok: false, error: 'Mật khẩu tối thiểu 6 ký tự.' });
    }

    const email = username.includes('@') ? username : `${username}@qlgd.edu.vn`;
    const uname = email.split('@')[0];

    const admin = createClient(url, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: created, error: createErr } =
      await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name: fullName, role, username: uname },
      });
    if (createErr || !created?.user) {
      return json({
        ok: false,
        error: 'Không tạo được tài khoản: ' + (createErr?.message ?? ''),
      });
    }

    // Cập nhật liên hệ (trigger handle_new_user đã tạo profile từ metadata).
    if (phone || contactEmail) {
      await admin
        .from('profiles')
        .update({ phone, email: contactEmail })
        .eq('id', created.user.id);
    }

    return json({ ok: true, user_id: created.user.id, email });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});
