"""Sinh script SQL thay toàn bộ dữ liệu sinh viên bằng danh sách từ file Excel.

Cách dùng (cần `pip install openpyxl`):

    python tools/import_students.py data_import/import_students.sql \
        "D:/.../DS LỚP QL.01.xlsx=QH-2026-S QL.01" \
        "C:/.../DS lớp QH2024.N1.xlsx=QH-2024-S N1" ...

Mỗi tham số là `đường_dẫn_file=Tên lớp`. Script quét mọi sheet, tự nhận dòng
tiêu đề (Mã SV / Họ và tên / Ngày sinh / SĐT / Email), gộp các bản ghi trùng mã
sinh viên thành MỘT (lấy giá trị đầu tiên không trống cho từng trường) và in ra
các xung đột để kiểm tra.

File SQL sinh ra chạy trong Supabase Dashboard → SQL Editor, trong một
transaction:
  1. sao lưu sinh viên / kết quả học tập / tài khoản SV cũ vào schema backup_*;
  2. xóa toàn bộ dữ liệu sinh viên cũ và tài khoản đăng nhập của sinh viên;
  3. nhập sinh viên mới, tạo tài khoản đăng nhập (MSSV / mật khẩu 123456).

Khóa (năm nhập học) suy ra từ 2 chữ số đầu của mã: 26xxxxxx → 2026.
LƯU Ý: file SQL chứa dữ liệu cá nhân thật – không commit (data_import/ đã được
gitignore).
"""

import datetime as dt
import re
import sys
import unicodedata
from dataclasses import dataclass, field, fields

import openpyxl

CODE_RE = re.compile(r"^\d{8}$")


def norm(s) -> str:
    """Chuỗi tiêu đề đã chuẩn hóa: NFC, chữ thường, gộp khoảng trắng."""
    s = unicodedata.normalize("NFC", str(s or ""))
    return re.sub(r"\s+", " ", s).strip().lower()


def header_kind(cell) -> str | None:
    h = norm(cell)
    if h in ("mã sv", "msv", "mssv", "mã sinh viên", "mã số sinh viên"):
        return "code"
    if h.startswith("họ và tên") or h == "họ tên":
        return "name"
    if h.startswith("ngày sinh"):
        return "birth"
    if "điện thoại" in h or h in ("sđt", "sdt"):
        return "phone"
    if h in ("gmail", "mail", "email", "e-mail"):
        return "email"
    if h.startswith("giới tính"):
        return "gender"
    if h.startswith("ghi chú"):
        return "note"
    if h in ("lớp", "stt", "tt", "ngành học") or h.startswith("mã lớp"):
        return "other_" + h  # cột đã biết, không phải ghi chú
    return None


@dataclass
class Rec:
    code: str
    name: str = ""
    birth: str = ""
    phone: str = ""
    email: str = ""
    note: str = ""
    class_name: str = ""
    sources: list = field(default_factory=list)


def clean_name(v) -> str:
    s = re.sub(r"\s+", " ", unicodedata.normalize("NFC", str(v or ""))).strip()
    return s.title() if s.isupper() else s


def clean_birth(v) -> str:
    if isinstance(v, (dt.datetime, dt.date)):
        return v.strftime("%d/%m/%Y")
    s = str(v or "").strip()
    m = re.match(r"^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})$", s)
    return f"{int(m[1]):02d}/{int(m[2]):02d}/{m[3]}" if m else s


def clean_phone(v) -> str:
    if v is None:
        return ""
    if isinstance(v, float):
        v = int(v)
    parts = [re.sub(r"\D", "", p) for p in re.split(r"[;,/]", str(v))]
    out = []
    for d in parts:
        if len(d) == 9:  # Excel làm mất số 0 đầu
            d = "0" + d
        if d:
            out.append(d)
    return "; ".join(out)


def clean_email(v) -> str:
    s = str(v or "").strip().lower()
    return s if "@" in s else ""


def clean_code(v) -> str:
    if isinstance(v, float) and v.is_integer():
        v = int(v)
    s = str(v or "").strip()
    return s if CODE_RE.match(s) else ""


def read_file(path: str, class_name: str):
    wb = openpyxl.load_workbook(path, data_only=True, read_only=True)
    for ws in wb.worksheets:
        cols = None
        for row in ws.iter_rows(values_only=True):
            if cols is None:
                kinds = {header_kind(c): i for i, c in enumerate(row) if header_kind(c)}
                if "code" in kinds and "name" in kinds:
                    cols = kinds
                continue
            code = clean_code(row[cols["code"]] if cols["code"] < len(row) else None)
            if not code:
                continue

            def get(kind):
                i = cols.get(kind)
                return row[i] if i is not None and i < len(row) else None

            # Ghi chú có thể nằm ở cột không có tiêu đề (vd "rút hs đợi quyết định").
            extra = [
                c.strip()
                for i, c in enumerate(row)
                if i not in cols.values() and isinstance(c, str) and c.strip()
                and not re.fullmatch(r"[\d.,%\s-]+", c.strip())  # số liệu dạng chữ
            ]
            note = " ".join(x for x in [str(get("note") or "").strip(), *extra] if x)
            yield Rec(
                code=code,
                name=clean_name(get("name")),
                birth=clean_birth(get("birth")),
                phone=clean_phone(get("phone")),
                email=clean_email(get("email")),
                note=note,
                class_name=class_name,
                sources=[f"{path.split('/')[-1]} [{ws.title}]"],
            )


def merge(records):
    by_code: dict[str, Rec] = {}
    conflicts = []
    dup_rows = 0
    for r in records:
        cur = by_code.get(r.code)
        if cur is None:
            by_code[r.code] = r
            continue
        dup_rows += 1
        for f in fields(Rec):
            if f.name in ("code", "sources"):
                continue
            a, b = getattr(cur, f.name), getattr(r, f.name)
            if not a and b:
                setattr(cur, f.name, b)
            elif a and b and norm(a) != norm(b) and f.name in ("name", "birth", "class_name"):
                conflicts.append(f"{r.code} {f.name}: '{a}' (giữ) ≠ '{b}' ({r.sources[0]})")
        if r.sources[0] not in cur.sources:
            cur.sources.append(r.sources[0])
    return by_code, dup_rows, conflicts


def q(v) -> str:
    return "null" if v in (None, "") else "'" + str(v).replace("'", "''") + "'"


def build_sql(recs: list[Rec], stamp: str) -> str:
    values = []
    for r in recs:
        year = 2000 + int(r.code[:2])
        status = "suspended" if re.search(r"rút|bảo lưu", r.note.lower()) else "active"
        values.append(
            f"  ({q(r.code)}, {q(r.name)}, {q(f'QH-{year}')}, {q(r.class_name)}, {year}, "
            f"{q(status)}, {q(r.phone)}, {q(r.birth)}, {q(r.email)})"
        )
    rows = ",\n".join(values)
    bk = f"backup_{stamp}"
    return f"""-- ============================================================================
-- Thay toàn bộ dữ liệu sinh viên bằng danh sách thực tế ({len(recs)} sinh viên).
-- Sinh tự động bởi tools/import_students.py – CHỨA DỮ LIỆU CÁ NHÂN, không commit.
-- Chạy trong Supabase Dashboard → SQL Editor. Toàn bộ nằm trong 1 transaction:
-- lỗi ở bất kỳ bước nào sẽ hoàn tác hết.
-- Dữ liệu cũ được sao lưu vào schema {bk} (không lộ ra API).
-- ============================================================================
begin;

-- 1) Sao lưu ---------------------------------------------------------------
create schema if not exists {bk};
create table {bk}.students        as select * from public.students;
create table {bk}.enrollments     as select * from public.enrollments;
create table {bk}.change_requests as select * from public.change_requests;
create table {bk}.audit_log       as select * from public.audit_log where student_code is not null;
create table {bk}.student_profiles as select * from public.profiles where role = 'student';
create table {bk}.student_auth_users as
  select * from auth.users where email like '%@sv.qlgd.edu.vn';

-- 2) Xóa dữ liệu sinh viên cũ ---------------------------------------------
-- Xóa tài khoản đăng nhập của sinh viên (profiles xóa theo cascade).
delete from auth.users where email like '%@sv.qlgd.edu.vn';
-- Hồ sơ SV; kết quả học tập & yêu cầu sửa hồ sơ xóa theo cascade.
delete from public.students;
delete from public.audit_log where student_code is not null;
delete from public.settings where key = 'demo_student_code';

-- 3) Nhập sinh viên mới ---------------------------------------------------
insert into public.students
  (student_code, full_name, cohort, class_name, enroll_year, status, phone, birth_date, email)
values
{rows};

-- 4) Tạo tài khoản đăng nhập: MSSV / 123456 (người dùng tự đổi sau) ---------
do $$
declare
  rec record;
  uid uuid;
  pw text := crypt('123456', gen_salt('bf')); -- băm 1 lần, dùng chung
begin
  for rec in select id, student_code, full_name from public.students loop
    uid := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      confirmation_token, recovery_token, email_change, email_change_token_new,
      raw_app_meta_data, raw_user_meta_data
    ) values (
      '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
      rec.student_code || '@sv.qlgd.edu.vn', pw,
      now(), now(), now(),
      '', '', '', '',
      '{{"provider":"email","providers":["email"]}}'::jsonb,
      jsonb_build_object('full_name', rec.full_name, 'role', 'student',
        'username', rec.student_code, 'student_code', rec.student_code)
    );
    begin
      insert into auth.identities (
        provider_id, user_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at
      ) values (
        uid::text, uid,
        jsonb_build_object('sub', uid::text,
          'email', rec.student_code || '@sv.qlgd.edu.vn'),
        'email', now(), now(), now()
      );
    exception when others then
      null;
    end;
    -- trigger handle_new_user thường đã tạo profile; chèn an toàn nếu chưa
    insert into public.profiles (id, username, role, full_name, student_code, active)
    values (uid, rec.student_code, 'student', rec.full_name, rec.student_code, true)
    on conflict (id) do nothing;
    update public.students set user_id = uid where id = rec.id;
  end loop;
end $$;

-- 5) Kiểm tra --------------------------------------------------------------
do $$
begin
  if (select count(*) from public.students) <> {len(recs)} then
    raise exception 'Số sinh viên sau khi nhập không khớp ({len(recs)}).';
  end if;
  if exists (select 1 from public.students where user_id is null) then
    raise exception 'Có sinh viên chưa được tạo tài khoản.';
  end if;
end $$;

commit;

-- Thống kê sau khi nhập:
select cohort, class_name, count(*) as so_sv
from public.students group by cohort, class_name order by cohort, class_name;
"""


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 1
    out = argv[1]
    records = []
    for arg in argv[2:]:
        path, _, class_name = arg.rpartition("=")
        got = list(read_file(path, class_name.strip()))
        print(f"{len(got):4d} dòng  ← {path}  ({class_name})")
        records += got
    by_code, dup_rows, conflicts = merge(records)
    recs = sorted(by_code.values(), key=lambda r: r.code)

    print(f"\nTổng {len(records)} dòng, bỏ {dup_rows} dòng trùng mã → {len(recs)} sinh viên.")
    for prefix in sorted({r.code[:2] for r in recs}):
        n = sum(1 for r in recs if r.code.startswith(prefix))
        print(f"  mã {prefix}xxxxxx (QH-20{prefix}): {n}")
    if conflicts:
        print(f"\n{len(conflicts)} xung đột giữa các file (giữ giá trị đầu):")
        for c in conflicts:
            print("  " + c)
    noted = [r for r in recs if r.note]
    if noted:
        print("\nGhi chú:")
        for r in noted:
            print(f"  {r.code} {r.name}: {r.note}")
    missing = [r.code for r in recs if not r.name]
    if missing:
        print(f"\nThiếu họ tên: {missing}")
        return 1

    stamp = dt.date.today().strftime("%Y%m%d")
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(build_sql(recs, stamp))
    print(f"\nĐã ghi {out}")
    return 0


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main(sys.argv))
