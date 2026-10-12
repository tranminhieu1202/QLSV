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

- **Tổng quan**: lọc theo khóa cho toàn màn hình; 5 chỉ số chính (sinh viên, bị cảnh báo học vụ kèm số diện buộc thôi học, chậm tiến độ, nợ tín chỉ, CPA trung bình của SV đã có điểm); biểu đồ cảnh báo học vụ và tiến độ đào tạo theo năm học, phân bố CPA theo xếp loại (rê chuột xem số liệu, bấm nút bảng để xem dạng bảng); danh sách sinh viên cần chú ý, bấm để mở hồ sơ.
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

- **Ghi nhớ đăng nhập** (mọi vai trò, mặc định bật): mở lại ứng dụng là vào thẳng, không cần nhập mật khẩu; phiên tự gia hạn. Bỏ chọn khi dùng máy chung. Tài khoản bị khóa, bị đổi mật khẩu hoặc bấm *Đăng xuất* thì phải đăng nhập lại. Tên đăng nhập gần nhất luôn được điền sẵn.
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

Quy mô hiện tại: khoảng 9.800 dòng Dart, 700 dòng SQL/TypeScript/Python, 600 dòng test tự động cho tính toán học vụ, lọc/sắp xếp, xuất file và giao diện tiêu đề cột.

```
lib/
  data/       Repository (Supabase), AcademicService (GPA/CPA/cảnh báo),
              ReportService/ReportExporter (báo cáo, Excel, PDF), cập nhật app
  models/     Student, Course, Enrollment, StudentProgress, AppUser
  providers/  AppState (quản lý trạng thái toàn cục)
  screens/    faculty/ (cán bộ), student/ (sinh viên), đăng nhập, hoạt động
  theme/      AppTheme, AppColors (hệ màu Material 3)
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
| Apple Developer Program (nếu phát hành trên Mac App Store) | $99/năm (~2.400.000 VNĐ) |

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

## 4. Đưa app lên Mac App Store & cập nhật

### 4.0. Đánh giá tính khả thi

**Kết luận: khả thi.** Phần mã nguồn đã sẵn sàng; phần còn lại là thủ tục với Apple (tài khoản, chứng chỉ, hồ sơ app) và phải làm trên máy Mac.

| Hạng mục | Trạng thái | Ghi chú |
|---|:-:|---|
| App Sandbox, quyền mạng, quyền lưu/mở file do người dùng chọn | ✅ Có sẵn | `Release.entitlements`: `app-sandbox`, `network.client`, `files.user-selected.read-write`. Xuất Excel/PDF và chọn ảnh đại diện đều dùng hộp thoại hệ thống nên chạy được trong sandbox |
| Bundle ID riêng | ✅ Đã đổi | `edu.vnu.qlgd`. Nếu tài khoản Apple không thuộc ĐHQGHN, có thể đổi sang ID khác, miễn là đổi trước lần upload đầu tiên |
| Tắt tự cập nhật qua GitHub ở bản App Store | ✅ Đã làm | Apple **cấm** app trên Mac App Store tự cập nhật ngoài App Store (Guideline 2.4.5). Build với `--dart-define=APP_STORE=true` sẽ ẩn mục "Kiểm tra cập nhật" và không kiểm tra lúc khởi động |
| Danh mục app & khai báo mã hóa | ✅ Đã thêm | `Info.plist`: `LSApplicationCategoryType = education`; `ITSAppUsesNonExemptEncryption = false` (app chỉ dùng HTTPS), nên không phải trả lời câu hỏi xuất khẩu mã hóa mỗi lần upload |
| Icon 1024×1024 | ✅ Có sẵn | `AppIcon.appiconset` |
| macOS tối thiểu | ✅ 12.0 | |
| Tài khoản Apple Developer | ⏳ Cần làm | Đăng ký dưới tên **tổ chức** thì cần số **D-U-N-S** (miễn phí, mất 1–2 tuần). Đăng ký cá nhân thì trên App Store sẽ hiện tên cá nhân là nhà phát hành |
| Chứng chỉ, provisioning profile, Archive | ⏳ Cần máy Mac | Không làm được trên Windows |
| Chính sách quyền riêng tư (Privacy Policy URL) | ⏳ Cần làm | Bắt buộc. App xử lý dữ liệu cá nhân của sinh viên: họ tên, MSSV, ngày sinh, điểm, ảnh đại diện. Phần **App Privacy** trên App Store Connect phải khai đúng các loại dữ liệu này |
| Tài khoản demo cho Apple duyệt | ⏳ Cần làm | App bắt buộc đăng nhập, nên phải cấp cho Apple 1 tài khoản cán bộ và 1 tài khoản sinh viên chứa dữ liệu mẫu, **không** dùng dữ liệu thật |

**Rủi ro bị từ chối cần lưu ý:**

- **App chỉ dành cho người trong một khoa** (Guideline 3.2 / 4.2): Apple có thể từ chối đăng công khai một app nội bộ. Hướng xử lý, theo thứ tự ưu tiên:
  1. Xin **Unlisted App Distribution**: app vẫn nằm trên Mac App Store và cập nhật bình thường, nhưng không hiện khi tìm kiếm, chỉ ai có link mới cài được. Đây là hình thức phù hợp nhất với app nội bộ.
  2. Phát hành **Custom App** qua Apple School Manager / Business Manager của trường.
  3. Không lên App Store: phân phối qua website bằng bản **ký Developer ID + Notarize**, tức là giữ kênh GitHub Releases hiện tại nhưng không còn bị Gatekeeper cảnh báo.
- **Xóa tài khoản** (Guideline 5.1.1(v)): yêu cầu này chỉ áp dụng khi app cho phép người dùng *tự tạo* tài khoản. QLGD EDU chỉ có quản trị viên tạo tài khoản, nên khi gửi duyệt hãy nói rõ điều này trong phần *Notes for Review*.

### 4.1. Chuẩn bị (làm một lần)

1. **Đăng ký Apple Developer Program** tại [developer.apple.com/programs](https://developer.apple.com/programs/) – phí $99/năm (~2.400.000 VNĐ), chờ duyệt 24–48 giờ.

2. **Bundle ID** – đã đổi từ `com.example.qlgdEdu` sang `edu.vnu.qlgd` trong `macos/Runner/Configs/AppInfo.xcconfig`. Lưu ý: bản macOS tải từ GitHub trước đây dùng ID cũ, nên sau khi chuyển sang bản mới, người dùng sẽ phải đăng nhập lại một lần.

3. **Tạo App ID** trên Apple Developer Portal: Certificates, Identifiers & Profiles → Identifiers → + → App IDs → App → nhập Bundle ID `edu.vnu.qlgd`. Không cần bật thêm capability nào; quyền mạng và quyền file đã khai trong entitlements chứ không nằm ở App ID.

4. **Tạo Certificate & Provisioning Profile**:
   - Certificate: tạo **Mac App Distribution** và **Mac Installer Distribution** (dùng CSR từ Keychain Access).
   - Profile: tạo **Mac App Store** provisioning profile, chọn App ID và certificate vừa tạo.

5. **Cấu hình signing trong Xcode**: mở `macos/Runner.xcworkspace` → Runner target → Signing & Capabilities → chọn Team, Provisioning Profile, Signing Certificate = Mac App Distribution.

6. **Tạo app trên App Store Connect** tại [appstoreconnect.apple.com](https://appstoreconnect.apple.com/): New App → macOS → điền tên, Bundle ID, SKU, mô tả, screenshots (1280×800 hoặc 2560×1600), Privacy Policy URL, category = Education.

### 4.2. Build & upload lên App Store

```bash
flutter clean
flutter build macos --release --dart-define=APP_STORE=true   # BẮT BUỘC có cờ này
open macos/Runner.xcworkspace   # mở Xcode
```

> Khi chạy `flutter build`, cờ `APP_STORE` được ghi vào `macos/Flutter/ephemeral/Flutter-Generated.xcconfig`, và bước Archive trong Xcode sẽ dùng lại cờ đó. Vì vậy phải chạy lệnh trên **ngay trước khi** Archive. Nếu thiếu cờ, app sẽ còn chức năng tự cập nhật qua GitHub và bị Apple từ chối.

Trong Xcode: Product → Archive → Distribute App → App Store Connect → Upload. Chờ Apple xử lý (5–30 phút), sau đó vào App Store Connect chọn build, điền thông tin và Submit for Review (thường duyệt trong 24–48 giờ).

### 4.3. Quy trình cập nhật mỗi bản mới

1. **Tăng version** trong `pubspec.yaml` — build number (sau dấu `+`) phải tăng dần mỗi lần upload:
   ```diff
   -version: 1.0.0+1
   +version: 1.0.1+2
   ```
2. **Build, Archive & Upload** như mục 4.2.
3. Trên App Store Connect: + Version or Platform → nhập version mới → chọn build → ghi What's New → Submit for Review.
4. **Người dùng nhận bản mới tự động** qua App Store (tab Updates hoặc Automatic Updates).

### 4.4. Lưu ý

- **App Sandbox bắt buộc** cho Mac App Store — app đã bật sẵn trong Entitlements.
- Nếu muốn phân phối ngoài App Store (qua website), chỉ cần **Notarize** app thay vì submit review — nhanh hơn và không cần chờ duyệt.
- Hai kênh phát hành có thể chạy song song, nhưng **mỗi bản build chỉ thuộc một kênh**. Bản GitHub (Windows, macOS tải zip) tự cập nhật qua GitHub Releases như hiện nay. Bản App Store build với `APP_STORE=true` và chỉ được App Store cập nhật.

---

## 5. Hướng dẫn cho lập trình viên

```bash
flutter pub get
flutter run -d windows        # chạy thử
flutter analyze && flutter test
```

- **Cấu hình Supabase**: `lib/data/supabase_config.dart` (URL + publishable key). Schema nằm trong `supabase/migrations/`, edge functions trong `supabase/functions/`.
- **Phát hành bản mới**: gắn tag `vX.Y.Z` lên `main` rồi push. GitHub Actions sẽ build, chạy test, đóng gói bộ cài và tạo Release; ứng dụng đã cài sẽ tự nhận bản mới.
- **Nhập danh sách sinh viên**: xem hướng dẫn ở đầu `tools/import_students.py`. File SQL sinh ra chứa dữ liệu cá nhân, được đặt trong `data_import/` (đã gitignore) và **không được commit**.
