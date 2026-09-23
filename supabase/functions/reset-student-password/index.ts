// Edge Function: quản trị đặt lại mật khẩu cho một sinh viên.
//
// Chỉ vai trò admin (quản trị) được gọi. Dùng service role để cập nhật mật khẩu
// của tài khoản sinh viên (client anon không làm được).
//
// Deploy:  supabase functions deploy reset-student-password

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
      return json({ ok: false, error: 'Chỉ quản trị được đặt lại mật khẩu.' }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const code = String(body.studentCode ?? '').trim();
    const password = String(body.password ?? '123456');
    if (!code) return json({ ok: false, error: 'Thiếu mã số sinh viên.' });
    if (password.length < 6) {
      return json({ ok: false, error: 'Mật khẩu tối thiểu 6 ký tự.' });
    }

    const admin = createClient(url, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: student } = await admin
      .from('students')
      .select('user_id')
      .eq('student_code', code)
      .maybeSingle();
    const studentUid = student?.user_id;
    if (!studentUid) {
      return json({ ok: false, error: 'Sinh viên chưa có tài khoản đăng nhập.' });
    }

    const { error: updErr } = await admin.auth.admin.updateUserById(studentUid, {
      password,
    });
    if (updErr) {
      return json({ ok: false, error: 'Không đặt lại được: ' + updErr.message });
    }

    return json({ ok: true });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});
