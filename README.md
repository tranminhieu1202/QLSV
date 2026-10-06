# QLGD EDU – Hệ thống quản lý tiến trình đào tạo

Ứng dụng máy tính (Windows và macOS) giúp **Khoa Quản lý Giáo dục** theo dõi tiến trình học tập của sinh viên ngành *Quản trị trường học*: hồ sơ sinh viên, chương trình đào tạo, học phần & điểm do sinh viên tự khai báo, CPA, cảnh báo học vụ theo Quy chế đào tạo của ĐHQGHN, báo cáo và xuất file Excel/PDF.

Dữ liệu lưu tập trung trên **Supabase (PostgreSQL)**. Nhiều cán bộ và sinh viên dùng đồng thời và luôn thấy cùng một dữ liệu. Quyền truy cập được kiểm soát ngay trong cơ sở dữ liệu (Row Level Security), không chỉ ở giao diện.

---

## 1. Tính năng

### 1.1. Phân quyền theo vai trò

| Chức năng | Quản trị | Ban chủ nhiệm khoa | Trợ lý quản trị | Cố vấn học tập | Sinh viên |
|---|:-:|:-:|:-:|:-:|:-:|
| Xem tổng quan, danh sách, cảnh báo | Toàn khoa | Toàn khoa | Toàn khoa | Lớp mình cố vấn | – |
| Báo cáo & xuất Excel/PDF | ✔ | ✔ | ✔ | Lớp mình cố vấn | – |
| Thêm sinh viên, sửa hồ sơ sinh viên | ✔ trực tiếp | – | ✔ cần quản trị duyệt | – | Tự sửa thông tin liên hệ |
| Quản lý chương trình đào tạo | ✔ | Xem | Xem | Xem | Xem |
| Đặt kỳ học hiện tại, duyệt thay đổi hồ sơ | ✔ | – | – | – | – |
| Quản lý tài khoản cán bộ, khóa/xóa tài khoản | ✔ | – | – | – | – |
| Tự khai báo học phần, kỳ học và điểm của mình | – | – | – | – | ✔ |
| Đổi mật khẩu, sửa thông tin cá nhân | ✔ | ✔ | ✔ | ✔ | ✔ |

### 1.2. Các màn hình dành cho cán bộ

- **Tổng quan**: số sinh viên, số SV cần chú ý (từ cảnh báo học vụ lần 2), số SV nợ tín chỉ, CPA trung bình; biểu đồ phân bố mức cảnh báo và số SV theo khóa.
- **Sinh viên**
  - Danh sách có tìm kiếm theo MSSV/họ tên.
  - Tiêu đề cột kiểu Excel: bấm để sắp xếp, menu lọc giá trị theo Khóa / Lớp / CVHT.
  - Thêm sinh viên kèm tạo tài khoản đăng nhập; mã SV được gợi ý tự động theo quy ước của trường.
  - Xem hồ sơ chi tiết của từng SV gồm 4 tab: điểm tổng hợp, điểm chi tiết, tiến trình đào tạo theo khối kiến thức, cảnh báo.
  - Đặt lại mật khẩu, khóa tài khoản, xóa sinh viên.
- **Cảnh báo**: danh sách SV có cảnh báo, lọc theo mức tối thiểu. Mỗi cảnh báo kèm chi tiết các học phần không đạt hoặc còn thiếu so với tiến trình.
- **Báo cáo & xuất file**
  - **Mẫu báo cáo nhanh**: SV bị cảnh báo học vụ lần 1, lần 2 liên tiếp, thuộc diện buộc thôi học, SV năm 1–4, SV năm 2 và 3, đúng tiến độ, chậm tiến độ, đang nợ tín chỉ, CPA < 2.0, đủ tín chỉ xét tốt nghiệp.
  - **Tiêu chí tùy chỉnh** kết hợp được với nhau: mức cảnh báo, năm thứ, khóa, lớp, cố vấn, tiến độ, nợ tín chỉ, ngưỡng CPA.
  - Chọn cột cần xuất, sắp xếp theo cột bất kỳ, sửa tiêu đề, xem trước trước khi xuất.
  - **Xuất Excel** (.xlsx) gồm trang danh sách và trang thống kê.
  - **Xuất PDF** khổ A4 ngang, có quốc hiệu, tiêu chí lọc, thống kê và chữ ký người lập biểu, dùng font tiếng Việt nhúng sẵn.
  - Màn Sinh viên và Cảnh báo cũng có nút "Xuất" cho danh sách đang hiển thị.
- **Chương trình đào tạo**: các khối kiến thức (chung, lĩnh vực, khối ngành, nhóm ngành, ngành, 3 hướng ngành, thực tập, khóa luận); học phần bắt buộc/tự chọn, kỳ dự kiến, học phần tiên quyết. Quản trị được thêm/sửa/xóa học phần.
- **Kỳ học & duyệt hồ sơ**: đặt kỳ học hiện tại (ví dụ `20261`, dùng để tính SV năm thứ mấy), duyệt hoặc từ chối các thay đổi hồ sơ do trợ lý gửi lên. Không còn mở/đóng kỳ đăng ký: sinh viên tự khai báo, cán bộ chỉ theo dõi.
- **Tài khoản**: tạo tài khoản cán bộ theo vai trò, khóa/mở khóa, xóa tài khoản.
- **Hoạt động**: nhật ký mọi thao tác (ai, lúc nào, làm gì) để đối soát.

### 1.3. Cổng sinh viên

- **Trang chủ**: CPA, GPA kỳ gần nhất, tín chỉ tích lũy và tín chỉ còn thiếu, tín chỉ nợ, % tiến độ, cảnh báo; tiến trình theo từng khối kiến thức.
- **Khai báo học tập**: sinh viên tự khai báo kỳ nào học học phần nào và được bao nhiêu điểm, bất cứ lúc nào, không cần duyệt. Cố vấn học tập, ban chủ nhiệm/trợ lý khoa và quản trị thấy ngay.
  - Chọn học phần trong CTĐT (gõ mã/tên để tìm) và học kỳ (HK1, HK2, hè từ năm nhập học tới năm học hiện tại).
  - Nhập **điểm học phần** (hệ 10, như trên bảng điểm), hoặc **điểm thành phần** (bộ phận 30% + cuối kì 70%), hoặc để "Chưa có điểm" (đang học). Điểm chữ, hệ 4 và trạng thái do máy chủ tính.
  - Sửa kỳ/điểm hoặc xóa khai báo; khai báo lại học phần đã đạt được tính là học cải thiện.
  - **Gợi ý học phần nên học**, ưu tiên học phần bắt buộc bị trễ tiến độ; có kiểm tra học phần tiên quyết.
- **Hồ sơ**: tự sửa thông tin liên hệ (SĐT, email, quê quán, ngày sinh).

### 1.4. Nghiệp vụ học vụ được tự động hóa

Áp dụng **Quy chế đào tạo đại học tại ĐHQGHN** (QĐ 3626/QĐ-ĐHQGHN ngày 21/10/2022):

- **Quy đổi điểm** (Điều 41, 43):

  | Hệ 10 | 9,0–10 | 8,5–8,9 | 8,0–8,4 | 7,0–7,9 | 6,5–6,9 | 5,5–6,4 | 5,0–5,4 | 4,0–4,9 | < 4,0 |
  |---|---|---|---|---|---|---|---|---|---|
  | Điểm chữ | A+ | A | B+ | B | C+ | C | D+ | D | F |
  | Hệ 4 | 4,0 | 3,7 | 3,5 | 3,0 | 2,5 | 2,0 | 1,5 | 1,0 | 0 |

- **GPA học kỳ** tính mọi học phần trong kỳ, cả đạt và không đạt. **CPA (TB chung tích lũy)** chỉ tính học phần đã đạt; học cải thiện thì lần đạt gần nhất thay điểm cũ. Học phần điều kiện (GDTC, GDQP-AN…) không tính.
- **Kỳ hè** được gộp vào học kỳ chính ngay trước nó khi xử lý học vụ.
- **Xếp loại học lực** theo GPA học kỳ: Xuất sắc ≥ 3,60 · Giỏi ≥ 3,20 · Khá ≥ 2,50 · Trung bình ≥ 2,00 · Yếu.
- **Năm đào tạo** theo TC tích lũy: < 35 năm 1 · 35–70 năm 2 · 71–105 năm 3 · 106–140 năm 4.
- **Cảnh báo học vụ** sau mỗi học kỳ chính có điểm, khi vi phạm một trong các điều kiện (Điều 44):
  - CPA dưới 1,20 (năm đào tạo thứ nhất), 1,40 (năm 2), 1,60 (năm 3), 1,80 (các năm sau);
  - GPA học kỳ dưới 0,80 ở học kỳ đầu khóa, dưới 1,00 ở các kỳ sau;
  - nợ đọng điểm F quá 24 TC, hoặc số TC không đạt trong kỳ vượt 50% số TC đã đăng ký.
- **Mức cảnh báo** theo số lần liên tiếp: *Cảnh báo lần 1* → *Cảnh báo lần 2* → quá 2 lần liên tiếp là *Thuộc diện buộc thôi học*. Một học kỳ không vi phạm thì về 0.
- Giới hạn TC đăng ký mỗi học kỳ chính: từ 2/3 đến 3/2 khối lượng trung bình một học kỳ theo kế hoạch chuẩn (chỉ để đánh dấu "Thiếu/Thừa tín chỉ").
- Lưu ý thêm (không phải cảnh báo học vụ): nợ tín chỉ, CPA dưới 2,00 (chuẩn tốt nghiệp) với SV năm cuối.
  - Cảnh báo chậm tiến độ khi đạt dưới 80% số TC bắt buộc lẽ ra đã phải xong.
- **Năm học tự động theo mã SV**: 2 số đầu của mã là năm nhập học. Khi kỳ hiện tại là `20261` thì mã 26 là năm 1, 25 là năm 2, 24 là năm 3, 23 là năm 4. Khi quản trị chuyển kỳ sang `20271`, mã 27 tự động thành năm 1 mà không cần sửa dữ liệu.
- **Hướng ngành**: tự nhận hướng sinh viên đang theo dựa trên số tín chỉ đã đạt.

### 1.5. Vận hành

- **Tự kiểm tra bản cập nhật** qua GitHub Releases, tải và cài bản mới ngay trong ứng dụng.
- **Bộ cài Windows** (Inno Setup) và **gói macOS** (`qlgd_edu-<phiên bản>-macos.zip`, macOS 12 trở lên) được build tự động bằng GitHub Actions mỗi khi gắn tag `v*`. Gói macOS chưa ký số/notarize nên lần đầu mở cần chuột phải → *Open*; khi có bản mới, app mở link tải gói .zip thay vì tự cài.
- **Nhập dữ liệu sinh viên từ Excel** (`tools/import_students.py`):
  - Tự nhận cột trong file và gộp mã sinh viên trùng.
  - Sao lưu dữ liệu cũ trước khi thay.
  - Tạo tài khoản đăng nhập hàng loạt.

---

## 2. Kiến trúc & công nghệ

| Thành phần | Công nghệ |
|---|---|
| Ứng dụng | Flutter 3 (Dart), Material 3, Provider |
| Cơ sở dữ liệu | Supabase PostgreSQL: bảng, view tính CPA/nợ TC, trigger tính điểm, RLS phân quyền |
| Xác thực | Supabase Auth (MSSV hoặc tên đăng nhập + mật khẩu) |
| Nghiệp vụ cần quyền cao | Supabase Edge Functions (Deno/TypeScript): tạo cán bộ, tạo SV, đặt lại mật khẩu, xóa tài khoản |
| Báo cáo | `excel`, `pdf`, `file_selector`; biểu đồ bằng `fl_chart` |
| Phát hành | GitHub Actions + Inno Setup, cập nhật qua GitHub Releases |

Quy mô hiện tại: khoảng 8.700 dòng Dart, 1.500 dòng SQL/TypeScript/Python, và các test tự động cho tính toán học vụ, lọc/sắp xếp, xuất file và giao diện tiêu đề cột.

```
lib/
  data/       Repository (Supabase), AcademicService (GPA/CPA/cảnh báo),
              ReportService/ReportExporter (báo cáo, Excel, PDF), cập nhật app
  models/     Student, Course, Enrollment, StudentProgress, AppUser
  screens/    faculty/ (cán bộ), student/ (sinh viên), đăng nhập, hoạt động
  widgets/    thành phần dùng chung (thẻ thống kê, tiêu đề cột, nút xuất…)
supabase/     migrations (schema, view, RLS), edge functions
tools/        script nhập danh sách sinh viên từ Excel
installer/    cấu hình Inno Setup
```

---

## 3. Đánh giá độ khó & khối lượng (phục vụ báo giá)

Bảng dưới ước lượng công sức để **xây dựng mới từ đầu một phần mềm đầy đủ** tương đương phiên bản hiện tại, theo chất lượng triển khai thật cho đơn vị đào tạo (có phân tích nghiệp vụ, kiểm thử, triển khai và đào tạo). Đơn vị là **ngày công** của một lập trình viên có kinh nghiệm (8 giờ/ngày).

Độ khó: ★ đơn giản · ★★ trung bình · ★★★ khá phức tạp · ★★★★ phức tạp · ★★★★★ rất phức tạp / nhiều rủi ro nghiệp vụ.

| # | Hạng mục | Độ khó | Ngày công | Ghi chú |
|---|---|:-:|:-:|---|
| 1 | Khảo sát, phân tích quy chế đào tạo & chương trình đào tạo | ★★★★ | 6 – 8 | Đọc quy chế, chuẩn hóa quy tắc cảnh báo, khối kiến thức, hướng ngành; phải làm việc với khoa |
| 2 | Thiết kế CSDL, view tính toán, trigger, phân quyền RLS | ★★★★ | 6 – 8 | 5 vai trò, phân quyền đến từng dòng dữ liệu; lỗi ở đây ảnh hưởng bảo mật |
| 3 | Đăng nhập, phân quyền, quản lý tài khoản, khóa tài khoản, edge functions | ★★★ | 5 – 7 | Tạo tài khoản hàng loạt, đặt lại mật khẩu, chống tài khoản "mồ côi" |
| 4 | Quản lý sinh viên & quy trình duyệt thay đổi hồ sơ | ★★★ | 6 – 8 | Trợ lý đề xuất → quản trị duyệt; lưu giá trị cũ/mới |
| 5 | Quản lý chương trình đào tạo | ★★ | 4 – 5 | Khối bắt buộc/tự chọn, hạn mức tín chỉ, tiên quyết |
| 6 | Sinh viên tự khai báo học phần & điểm, gợi ý học phần | ★★★★ | 6 – 8 | Ràng buộc tín chỉ, tiên quyết, học lại, ưu tiên học phần trễ tiến độ |
| 7 | Nhập điểm, quy đổi thang điểm, GPA/CPA | ★★★ | 4 – 5 | Tính ở máy chủ để đảm bảo đúng và thống nhất |
| 8 | Bộ tính tiến độ & cảnh báo học vụ theo quy chế ĐHQGHN | ★★★★★ | 8 – 10 | Phần nghiệp vụ khó nhất; cần đối chiếu nhiều trường hợp thực tế với phòng đào tạo |
| 9 | Tổng quan & biểu đồ thống kê | ★★ | 3 – 4 | |
| 10 | Báo cáo tùy chỉnh, xuất Excel/PDF, sắp xếp & lọc kiểu Excel | ★★★ | 6 – 8 | Font tiếng Việt trong PDF, mẫu biểu hành chính, sắp xếp theo bảng chữ cái tiếng Việt |
| 11 | Nhật ký hoạt động | ★ | 2 | |
| 12 | Nhập/chuyển đổi dữ liệu thực tế từ Excel | ★★★ | 3 – 4 | File của trường không đồng nhất, mã trùng, dữ liệu thiếu (SĐT mất số 0, ghi chú bảo lưu…) |
| 13 | Đóng gói bộ cài, cập nhật tự động, CI/CD | ★★★ | 3 – 4 | |
| 14 | Kiểm thử (tự động + thủ công theo vai trò), sửa lỗi | ★★★ | 8 – 10 | |
| 15 | Triển khai máy chủ, tài liệu hướng dẫn, đào tạo người dùng | ★★ | 4 – 5 | |
| | **Tổng** | | **74 – 96** | Khoảng **3,5 – 4,5 tháng** cho 1 người, hoặc **2 – 2,5 tháng** cho nhóm 2 người |

Nên cộng thêm **10 – 15% dự phòng** cho thay đổi yêu cầu, vì quy chế đào tạo và mẫu biểu thường được điều chỉnh trong quá trình làm.

### 3.1. Cách tính giá tham khảo

```
Giá = Tổng ngày công × Đơn giá ngày công × (1 + % dự phòng)
```

| Phương án | Ngày công (có 15% dự phòng) | Đơn giá/ngày (giả định) | Thành tiền |
|---|:-:|:-:|:-:|
| Tối thiểu | 74 × 1,15 ≈ 85 | 1.500.000 đ | ≈ 128 triệu đ |
| Tối đa | 96 × 1,15 ≈ 110 | 1.500.000 đ | ≈ 165 triệu đ |

> Đơn giá ở trên chỉ là **giả định để minh họa cách tính**. Hãy thay bằng đơn giá thực tế của bạn hoặc của công ty (khác nhau theo kinh nghiệm, khu vực, hình thức freelance hay công ty, có xuất hóa đơn hay không).

### 3.2. Chi phí vận hành hằng năm (báo riêng với khách hàng)

| Khoản | Ghi chú |
|---|---|
| Máy chủ Supabase | Gói miễn phí sẽ **tạm dừng project khi lâu không dùng** và giới hạn dung lượng; dùng thật nên chọn gói trả phí (khoảng 25 USD/tháng tại thời điểm viết; xem giá hiện hành trên trang Supabase) |
| Bảo trì, hỗ trợ, cập nhật theo quy chế mới | Thường **15 – 20% giá trị hợp đồng/năm** |
| Chứng thư ký số mã nguồn (tùy chọn) | Giúp Windows không cảnh báo "ứng dụng không rõ nguồn gốc" khi cài |

### 3.3. Hạng mục mở rộng (báo giá thêm nếu khách cần)

| Hạng mục | Độ khó | Ngày công ước tính |
|---|:-:|:-:|
| Bản web (dùng trên trình duyệt) | ★★★ | 8 – 12 |
| Ứng dụng di động cho sinh viên (Android/iOS) | ★★★ | 10 – 15 |
| Đồng bộ với phần mềm đào tạo của trường (API/nhập file định kỳ) | ★★★★★ | 10 – 20 (tùy hệ thống của trường) |
| Đăng nhập một lần bằng tài khoản trường (SSO / Google Workspace / Microsoft 365) | ★★★ | 4 – 6 |
| Gửi thông báo cảnh báo qua email / Zalo OA | ★★★ | 5 – 8 |
| Nhập điểm hàng loạt từ file Excel của giảng viên | ★★★ | 4 – 6 |
| Quản lý nhiều ngành / nhiều chương trình đào tạo | ★★★★ | 8 – 12 |
| Điểm rèn luyện, KPI, đánh giá đồng đẳng | ★★★ | 6 – 10 |

### 3.4. Rủi ro cần nêu rõ trong hợp đồng

- **Quy chế đào tạo và cách tính cảnh báo** phải được khoa/phòng đào tạo xác nhận bằng văn bản. Thay đổi quy tắc sau nghiệm thu được tính là yêu cầu mới.
- **Chất lượng dữ liệu đầu vào** (danh sách lớp, điểm cũ) do khách hàng cung cấp. Việc làm sạch dữ liệu quá phạm vi đã thống nhất sẽ tính thêm công.
- **Dữ liệu cá nhân của sinh viên**: cần thống nhất trách nhiệm bảo mật, nơi đặt máy chủ và chính sách sao lưu.
- **Phạm vi nền tảng**: hỗ trợ Windows và macOS; web và di động là hạng mục riêng.

---

## 4. Hướng dẫn cho lập trình viên

```bash
flutter pub get
flutter run -d windows        # chạy thử
flutter analyze && flutter test
```

- **Cấu hình Supabase**: `lib/data/supabase_config.dart` (URL + publishable key). Schema nằm trong `supabase/migrations/`, edge functions trong `supabase/functions/`.
- **Phát hành bản mới**: gắn tag `vX.Y.Z` lên `main` rồi push. GitHub Actions sẽ build, chạy test, đóng gói bộ cài và tạo Release; ứng dụng đã cài sẽ tự nhận bản mới.
- **Nhập danh sách sinh viên**: xem hướng dẫn ở đầu `tools/import_students.py`. File SQL sinh ra chứa dữ liệu cá nhân, được đặt trong `data_import/` (đã gitignore) và **không được commit**.
