// Edge Function: tạo tài khoản đăng nhập + hồ sơ cho sinh viên mới.
//
// Chỉ quản trị / trợ lý quản trị được gọi. Dùng service role để tạo user trong
// auth (điều mà anon key ở client không làm được), sau đó chèn bản ghi students.
//
// Deploy:  supabase functions deploy create-student
// Local :  supabase functions serve create-student

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

    // Xác định người gọi và vai trò từ JWT.
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
    const role = profile?.role;
    if (role !== 'admin' && role !== 'assistant') {
      return json({ ok: false, error: 'Không có quyền tạo sinh viên.' }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const code = String(body.studentCode ?? '').trim();
    const fullName = String(body.fullName ?? '').trim();
    const enrollYear = Number(body.enrollYear);
    if (!code || !fullName || !Number.isFinite(enrollYear)) {
      return json({ ok: false, error: 'Thiếu mã số, họ tên hoặc khóa.' });
    }

    const admin = createClient(url, serviceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: dup } = await admin
      .from('students')
      .select('id')
      .eq('student_code', code)
      .maybeSingle();
    if (dup) return json({ ok: false, error: 'Mã số sinh viên đã tồn tại.' });

    // Tài khoản đăng nhập: email nội bộ {MSSV}@sv.qlgd.edu.vn, mật khẩu mặc định.
    const email = `${code}@sv.qlgd.edu.vn`;
    const password = String(body.password ?? '123456');
    const { data: created, error: createErr } =
      await admin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          role: 'student',
          student_code: code,
          username: code,
        },
      });
    if (createErr || !created?.user) {
      return json({
        ok: false,
        error: 'Không tạo được tài khoản: ' + (createErr?.message ?? ''),
      });
    }
    const newUid = created.user.id;

    const { error: insErr } = await admin.from('students').insert({
      student_code: code,
      full_name: fullName,
      cohort: String(body.cohort ?? `K${enrollYear}`).trim(),
      class_name: String(body.className ?? '').trim(),
      enroll_year: enrollYear,
      advisor_id: body.advisorId ?? null,
      direction: body.direction ?? null,
      status: 'active',
      phone: body.phone ?? null,
      birth_date: body.birthDate ?? null,
      hometown: body.hometown ?? null,
      email: body.email ?? null,
      user_id: newUid,
    });
    if (insErr) {
      // Tránh tài khoản mồ côi nếu chèn hồ sơ thất bại.
      await admin.auth.admin.deleteUser(newUid);
      return json({ ok: false, error: 'Không lưu được hồ sơ: ' + insErr.message });
    }

    return json({ ok: true, user_id: newUid });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});
