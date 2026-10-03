// Edge Function: quản trị xóa một tài khoản đăng nhập (auth user).
//
// Chỉ vai trò admin được gọi. Nhận { userId } hoặc { studentCode }.
// Xóa auth user sẽ cascade xóa luôn hồ sơ profiles tương ứng.
//
// Deploy:  supabase functions deploy delete-user

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
      return json({ ok: false, error: 'Chỉ quản trị được xóa tài khoản.' }, 403);
    }

    const admin = createClient(url, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const body = await req.json().catch(() => ({}));
    let targetId: string | null = body.userId ?? null;
    if (!targetId && body.studentCode) {
      const { data } = await admin
        .from('students')
        .select('user_id')
        .eq('student_code', String(body.studentCode))
        .maybeSingle();
      targetId = data?.user_id ?? null;
    }

    if (!targetId) return json({ ok: false, error: 'Không tìm thấy tài khoản.' });
    if (targetId === uid) {
      return json({ ok: false, error: 'Không thể tự xóa tài khoản của mình.' });
    }

    const { error } = await admin.auth.admin.deleteUser(targetId);
    if (error) {
      return json({ ok: false, error: 'Không xóa được: ' + error.message });
    }

    return json({ ok: true });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});
