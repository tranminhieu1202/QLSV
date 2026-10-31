# QLGD EDU – Hướng dẫn sử dụng theo vai trò

Tài liệu dành cho **người dùng** ứng dụng QLGD EDU: cán bộ Khoa Quản lý Giáo dục, cố vấn học tập và sinh viên ngành *Quản trị trường học*. Phần kỹ thuật (kiến trúc, build, phát hành) xem ở [README.md](README.md).

**Mục lục**

1. [Giới thiệu nhanh](#1-giới-thiệu-nhanh)
2. [Cài đặt ứng dụng](#2-cài-đặt-ứng-dụng)
3. [Đăng nhập và các chức năng chung](#3-đăng-nhập-và-các-chức-năng-chung)
4. [Bảng phân quyền](#4-bảng-phân-quyền)
5. [Hướng dẫn cho Quản trị](#5-hướng-dẫn-cho-quản-trị)
6. [Hướng dẫn cho Ban chủ nhiệm khoa](#6-hướng-dẫn-cho-ban-chủ-nhiệm-khoa)
7. [Hướng dẫn cho Trợ lý quản trị](#7-hướng-dẫn-cho-trợ-lý-quản-trị)
8. [Hướng dẫn cho Cố vấn học tập](#8-hướng-dẫn-cho-cố-vấn-học-tập)
9. [Hướng dẫn cho Sinh viên](#9-hướng-dẫn-cho-sinh-viên)
10. [Cách ứng dụng tính điểm và cảnh báo học vụ](#10-cách-ứng-dụng-tính-điểm-và-cảnh-báo-học-vụ)
11. [Câu hỏi thường gặp](#11-câu-hỏi-thường-gặp)

---

## 1. Giới thiệu nhanh

QLGD EDU theo dõi tiến trình học tập 4 năm – 8 học kỳ của sinh viên trên **một nguồn dữ liệu chung**. Sinh viên tự khai báo học phần và điểm; cán bộ khoa và cố vấn học tập thấy ngay kết quả, cùng với CPA, tiến độ và **cảnh báo học vụ được tính tự động** theo Quy chế đào tạo của ĐHQGHN.

Ứng dụng có 5 vai trò:

| Vai trò | Dành cho | Tóm tắt |
|---|---|---|
| **Quản trị** | Cán bộ phụ trách hệ thống | Toàn quyền: quản lý sinh viên, tài khoản, chương trình đào tạo, kỳ học, duyệt hồ sơ |
| **Ban chủ nhiệm khoa** (BCN Khoa) | Lãnh đạo khoa | Xem toàn khoa, báo cáo, xuất file. Không sửa dữ liệu |
| **Trợ lý quản trị** (Trợ lý QT) | Trợ lý khoa | Xem toàn khoa, thêm sinh viên, đề xuất sửa hồ sơ (cần quản trị duyệt) |
| **Cố vấn học tập** (CVHT) | Giảng viên cố vấn | Xem và báo cáo sinh viên các lớp mình cố vấn |
| **Sinh viên** | Sinh viên ngành Quản trị trường học | Tự khai báo học phần, điểm; xem tiến độ và cảnh báo của mình |

Mọi người dùng chung một cơ sở dữ liệu trên máy chủ: thay đổi của một người được người khác thấy ngay sau khi làm mới. Quyền truy cập được kiểm soát ở cả máy chủ, không chỉ ở giao diện, nên người dùng không thể xem dữ liệu ngoài phạm vi của mình.

---

## 2. Cài đặt ứng dụng

Tải bản mới nhất tại: **https://github.com/tranminhieu1202/QLSV/releases/latest**

### Windows (Windows 10 trở lên)

1. Tải file `qlgd_edu-setup-<phiên bản>.exe`.
2. Mở file. Nếu Windows hiện **"Windows protected your PC"**, bấm **More info** → **Run anyway**. Cảnh báo này xuất hiện vì bộ cài chưa có chữ ký số Windows, không phải do virus.
3. Làm theo hướng dẫn cài đặt, sau đó mở **QLGD EDU** từ Start menu hoặc biểu tượng trên màn hình.

### macOS (macOS 13 Ventura trở lên)

1. Tải file `qlgd_edu-<phiên bản>-macos.zip`.
2. Mở file zip để giải nén, kéo **QLGD EDU** vào thư mục **Applications**.
3. Mở app từ Applications hoặc Launchpad. App đã được Apple xác thực (notarize) nên mở được ngay, không có cảnh báo.

Khi ứng dụng có mặt trên **Mac App Store**, người dùng Mac có thể cài từ App Store để được cập nhật tự động. Nếu chuyển sang bản App Store, hãy xóa bản tải từ GitHub trong Applications trước, rồi cài từ App Store và đăng nhập lại. Dữ liệu không bị mất vì nằm trên máy chủ.

### Cập nhật phiên bản

- Lúc khởi động, ứng dụng tự kiểm tra bản mới. Có thể kiểm tra thủ công: bấm vào **tên người dùng** ở góc trên bên phải → **Kiểm tra cập nhật**.
- **Windows**: bấm cập nhật, ứng dụng tự tải và cài bản mới.
- **macOS (bản GitHub)**: ứng dụng mở trang tải file zip; tải về và thay app cũ trong Applications.
- **macOS (bản App Store)**: cập nhật qua App Store, không có mục *Kiểm tra cập nhật* trong ứng dụng.

---

## 3. Đăng nhập và các chức năng chung

### 3.1. Đăng nhập

- **Cán bộ**: đăng nhập bằng **tên đăng nhập** do quản trị cấp (ví dụ `nguyenvana`).
- **Sinh viên**: đăng nhập bằng **mã số sinh viên** (ví dụ `24011057`).
- **Mật khẩu ban đầu** do Khoa cung cấp. **Hãy đổi mật khẩu ngay sau lần đăng nhập đầu tiên** (mục 3.3).
- Ô **Ghi nhớ đăng nhập trên máy này** (mặc định bật): lần sau mở ứng dụng không cần nhập lại mật khẩu. **Bỏ chọn khi dùng máy chung** (phòng máy, máy mượn).
- Tên đăng nhập gần nhất luôn được điền sẵn.

Phải đăng nhập lại khi: bấm *Đăng xuất*, mật khẩu bị đổi, hoặc tài khoản bị khóa.

### 3.2. Thanh điều hướng và thanh trên cùng

- **Cột bên trái**: danh sách màn hình theo vai trò (xem từng chương bên dưới).
- **Thanh trên cùng**: tên màn hình, **kỳ học hiện tại** (ví dụ *HK1 2026–2027*), nút **làm mới** (biểu tượng vòng tròn) để tải lại dữ liệu mới nhất, và **tên người dùng**.

### 3.3. Menu tài khoản (bấm vào tên người dùng ở góc trên bên phải)

| Mục | Chức năng |
|---|---|
| **Thông tin cá nhân & ảnh đại diện** | Sửa thông tin liên hệ, tải ảnh đại diện |
| **Đổi mật khẩu** | Nhập mật khẩu mới hai lần (ô *Mật khẩu mới* và *Nhập lại mật khẩu*) |
| **Kiểm tra cập nhật** | Kiểm tra phiên bản mới (không có ở bản App Store) |
| **Đăng xuất** | Thoát tài khoản; lần sau phải nhập lại mật khẩu |

### 3.4. Màn hình Hoạt động

Mọi vai trò đều có màn hình **Hoạt động**: nhật ký các thao tác (ai, lúc nào, làm gì) trong phạm vi được xem. Bấm **Đồng bộ ngay** để tải dữ liệu mới nhất từ máy chủ.

### 3.5. Thao tác chung với bảng dữ liệu

- **Tìm kiếm**: gõ mã sinh viên hoặc họ tên vào ô tìm kiếm.
- **Sắp xếp**: bấm vào **tiêu đề cột**; bấm lần nữa để đảo chiều.
- **Lọc**: bấm mũi tên cạnh tiêu đề cột (Khóa, Lớp, CVHT…) để chọn giá trị cần lọc, giống bộ lọc của Excel.
- **Mở hồ sơ**: bấm vào một dòng sinh viên.

---

## 4. Bảng phân quyền

✔ = được phép · 👁 = chỉ xem · – = không có

| Chức năng | Quản trị | BCN Khoa | Trợ lý QT | CVHT | Sinh viên |
|---|:-:|:-:|:-:|:-:|:-:|
| Tổng quan, Sinh viên, Cảnh báo | Toàn khoa | Toàn khoa | Toàn khoa | Lớp mình cố vấn | – |
| Xem hồ sơ chi tiết sinh viên | Toàn khoa | Toàn khoa | Toàn khoa | Lớp mình cố vấn | Của mình |
| Báo cáo & xuất Excel/PDF | ✔ | ✔ | ✔ | Lớp mình cố vấn | – |
| Thêm sinh viên (kèm tài khoản) | ✔ | – | ✔ | – | – |
| Sửa hồ sơ sinh viên | ✔ trực tiếp | – | ✔ chờ quản trị duyệt | – | Thông tin liên hệ của mình |
| Đặt lại mật khẩu, khóa/mở khóa, xóa sinh viên | ✔ | – | – | – | – |
| Chương trình đào tạo | ✔ thêm/sửa/xóa | 👁 | 👁 | 👁 | 👁 |
| Đặt kỳ học hiện tại, duyệt đề xuất sửa hồ sơ | ✔ | – | – | – | – |
| Quản lý tài khoản cán bộ | ✔ | – | – | – | – |
| Khai báo học phần, học kỳ, điểm | – | – | – | – | ✔ của mình |
| Nhật ký hoạt động | ✔ | ✔ | ✔ | ✔ | ✔ |
| Đổi mật khẩu, sửa thông tin cá nhân, ảnh đại diện | ✔ | ✔ | ✔ | ✔ | ✔ |

> **Điểm học tập chỉ do sinh viên khai báo.** Cán bộ và cố vấn xem được điểm nhưng không sửa. Nếu điểm sai, cố vấn nhắc sinh viên sửa ở màn hình *Khai báo học tập*.

---

## 5. Hướng dẫn cho Quản trị

**Các màn hình:** Tổng quan · Sinh viên · Cảnh báo · Báo cáo & xuất file · CT đào tạo · **Kỳ học & duyệt hồ sơ** · **Tài khoản** · Hoạt động

### 5.1. Tổng quan

Màn hình đầu tiên sau khi đăng nhập, tóm tắt tình hình đào tạo toàn khoa.

- **Lọc theo khóa** (góc trên bên phải): áp dụng cho toàn bộ màn hình.
- **5 chỉ số chính**: số sinh viên; số sinh viên bị cảnh báo học vụ (kèm số diện buộc thôi học); chậm tiến độ; đang nợ tín chỉ; CPA trung bình của sinh viên đã có điểm.
- **Biểu đồ**: cảnh báo học vụ theo năm học, tiến độ đào tạo theo năm học, phân bố CPA theo xếp loại.
  - Rê chuột lên cột để xem số liệu.
  - Bấm biểu tượng bảng ở góc biểu đồ để xem dạng bảng.
- **Sinh viên cần chú ý**: ưu tiên cảnh báo học vụ, chậm tiến độ, nợ tín chỉ. Bấm vào một sinh viên để mở hồ sơ.
- Bấm **Làm mới** để cập nhật số liệu.

### 5.2. Sinh viên

**Xem danh sách:** tìm kiếm, sắp xếp, lọc như mục 3.5. Ô **Tất cả trạng thái** cho phép lọc nhanh:
- *Cần chú ý (≥ cảnh báo lần 2)*
- *Đang nợ tín chỉ*

**Thêm sinh viên:**
1. Bấm **Thêm sinh viên**.
2. Nhập **Mã số SV**. Ứng dụng gợi ý mã theo quy ước của trường; 2 chữ số đầu là năm nhập học.
3. Nhập **Họ và tên**, **Khóa (năm)**, **Lớp** (chọn lớp có sẵn hoặc nhập lớp mới), **Hướng ngành** (nếu có), **Cố vấn học tập**.
4. Giữ chọn **Tạo tài khoản đăng nhập** để sinh viên đăng nhập được bằng mã số sinh viên và mật khẩu ban đầu.
5. Bấm **Lưu**.

**Xuất danh sách đang hiển thị:** bấm **Xuất** (Excel hoặc PDF).

> Nhập hàng loạt từ file Excel (thay toàn bộ danh sách sinh viên) do bộ phận kỹ thuật thực hiện bằng công cụ `tools/import_students.py`. Xem [README.md](README.md), mục 1.5.

### 5.3. Hồ sơ chi tiết sinh viên

Bấm vào một sinh viên ở màn Sinh viên, Cảnh báo hoặc Tổng quan. Hồ sơ gồm 4 tab:

| Tab | Nội dung |
|---|---|
| **Điểm tổng hợp** | CPA, GPA từng kỳ, tín chỉ tích lũy, xếp loại |
| **Điểm chi tiết** | Từng học phần sinh viên đã khai báo: kỳ học, điểm hệ 10, điểm chữ, hệ 4, trạng thái |
| **Tiến trình đào tạo** | Tiến độ theo từng khối kiến thức, học phần còn thiếu |
| **Cảnh báo** | Các cảnh báo hiện có và lý do |

Thao tác của Quản trị trên hồ sơ:
- **Sửa thông tin**: sửa trực tiếp, có hiệu lực ngay.
- **Đặt lại MK**: đưa mật khẩu của sinh viên về mật khẩu ban đầu. Dùng khi sinh viên quên mật khẩu.
- **Quản lý tài khoản** → **Khóa đăng nhập** / **Mở khóa đăng nhập**: tạm chặn hoặc cho phép sinh viên đăng nhập.
- **Quản lý tài khoản** → **Xóa sinh viên**: xóa vĩnh viễn hồ sơ, kết quả học tập và tài khoản. **Không hoàn tác được.**

### 5.4. Cảnh báo

- Danh sách sinh viên có cảnh báo, kèm chi tiết học phần không đạt hoặc còn thiếu so với tiến trình.
- **Mức tối thiểu**: chọn mức thấp nhất cần hiển thị (*Lưu ý*, *Cảnh báo lần 1*, *Cảnh báo lần 2*, *Buộc thôi học*).
- Bấm **Xem hồ sơ** để mở hồ sơ sinh viên; bấm **Xuất** để xuất danh sách.

### 5.5. Báo cáo & xuất file

1. **Chọn nhóm sinh viên**, bằng một trong hai cách:
   - **Mẫu báo cáo nhanh**: tất cả sinh viên; cảnh báo học vụ lần 1; lần 2 liên tiếp; thuộc diện buộc thôi học; sinh viên năm 1–4; năm 2 và 3; đúng tiến độ; chậm tiến độ; đang nợ tín chỉ; CPA dưới 2.0; đủ tín chỉ xét tốt nghiệp.
   - **Tiêu chí tùy chỉnh** (kết hợp được nhiều tiêu chí): mức cảnh báo, sinh viên năm thứ, khóa, lớp, cố vấn, tiến độ, nợ tín chỉ, ngưỡng CPA. Bấm **Xóa tiêu chí** để làm lại.
2. **Tiêu đề báo cáo**: dùng tiêu đề tự động hoặc tự nhập.
3. **Chọn cột** cần xuất và **sắp xếp** theo cột bất kỳ; xem trước ở bảng bên phải.
4. Bấm **Xuất Excel** hoặc **Xuất PDF**, chọn nơi lưu file.
   - **Excel (.xlsx)**: trang danh sách và trang thống kê.
   - **PDF**: khổ A4 ngang, có quốc hiệu, tiêu chí lọc, thống kê và chỗ ký của người lập biểu.

### 5.6. CT đào tạo (chương trình đào tạo)

- Xem các khối kiến thức (chung, lĩnh vực, khối ngành, nhóm ngành, ngành, các hướng ngành, thực tập, khóa luận) với số tín chỉ, học phần bắt buộc/tự chọn, kỳ dự kiến, học phần tiên quyết.
- **Thêm học phần**: bấm **Thêm học phần**, nhập *Mã HP*, *Tên học phần*, *Số TC*, *Khối kiến thức*, *Loại* (bắt buộc, tự chọn định hướng, điều kiện), *Kỳ tổ chức* (ví dụ `2-4`), *Tiên quyết (mã)*, rồi **Lưu**.
- **Sửa / Xóa**: bấm biểu tượng bút chì hoặc thùng rác ở cuối dòng học phần.

> Học phần **Điều kiện** (GDTC, GDQP-AN…) không tính vào GPA/CPA. Sửa chương trình đào tạo ảnh hưởng tới tiến độ và cảnh báo của **mọi** sinh viên; hãy kiểm tra kỹ trước khi lưu.

### 5.7. Kỳ học & duyệt hồ sơ

**Đặt kỳ học hiện tại** (đầu mỗi học kỳ):
1. Nhập mã kỳ dạng `YYYYK`: năm bắt đầu năm học + số kỳ (`1`, `2`, `3` = học kỳ hè). Ví dụ `20261` là HK1 năm học 2026–2027.
2. Bấm **Cập nhật kỳ**.

Kỳ hiện tại quyết định sinh viên đang học năm thứ mấy. Ví dụ khi kỳ là `20261`, sinh viên có mã bắt đầu bằng 26 là năm 1, 25 là năm 2… Chuyển sang `20271` thì sinh viên mã 27 tự thành năm 1, không cần sửa dữ liệu.

**Duyệt đề xuất sửa hồ sơ** do Trợ lý QT gửi lên:
- Mỗi đề xuất hiện người đề xuất, giá trị cũ và giá trị mới.
- Bấm **Duyệt** để áp dụng, hoặc **Từ chối** để bỏ.

### 5.8. Tài khoản (tài khoản cán bộ)

- **Thêm tài khoản**:
  1. Nhập *Họ và tên*, *Tên đăng nhập*, *Vai trò* (BCN Khoa / Trợ lý QT / CVHT), *Email cá nhân*, *Số điện thoại*.
  2. Bấm **Tạo tài khoản**, rồi gửi tên đăng nhập và mật khẩu ban đầu cho người dùng, kèm lời nhắc đổi mật khẩu.
- **Khóa / mở khóa**: bấm nút **…** ở cuối dòng tài khoản.
- **Xóa tài khoản**: bấm nút **…** → **Xóa tài khoản**. **Không hoàn tác được.**

Sau khi tạo tài khoản CVHT, phân công cố vấn cho sinh viên ở bước *Thêm sinh viên* hoặc *Sửa thông tin* trong hồ sơ.

### 5.9. Việc nên làm định kỳ

| Thời điểm | Việc |
|---|---|
| Đầu mỗi học kỳ | Cập nhật **kỳ học hiện tại** |
| Khi có khóa mới | Nhập danh sách sinh viên, tạo tài khoản CVHT và phân công cố vấn |
| Hằng tuần | Duyệt đề xuất sửa hồ sơ của trợ lý |
| Sau mỗi học kỳ chính | Xem màn **Cảnh báo**, xuất báo cáo cảnh báo học vụ |
| Khi cán bộ nghỉ việc | Khóa hoặc xóa tài khoản |

---

## 6. Hướng dẫn cho Ban chủ nhiệm khoa

**Các màn hình:** Tổng quan · Sinh viên · Cảnh báo · Báo cáo & xuất file · CT đào tạo · Hoạt động

Ban chủ nhiệm khoa **xem được toàn bộ dữ liệu của khoa** nhưng **không sửa** dữ liệu.

- **Theo dõi tình hình chung**: màn **Tổng quan** (mục 5.1). Lọc theo khóa để so sánh giữa các khóa.
- **Xem sinh viên**: màn **Sinh viên** (mục 5.2), bấm vào một sinh viên để xem hồ sơ 4 tab (mục 5.3). Không có các nút sửa, đặt lại mật khẩu, khóa hay xóa.
- **Theo dõi cảnh báo học vụ**: màn **Cảnh báo** (mục 5.4).
- **Lập báo cáo**: màn **Báo cáo & xuất file** (mục 5.5), xuất Excel hoặc PDF để trình ký, báo cáo trường.
- **Xem chương trình đào tạo**: màn **CT đào tạo** (chỉ xem).
- **Đối soát thao tác**: màn **Hoạt động**.

Cần sửa dữ liệu (thông tin sinh viên, chương trình đào tạo, kỳ học): liên hệ Quản trị.

---

## 7. Hướng dẫn cho Trợ lý quản trị

**Các màn hình:** Tổng quan · Sinh viên · Cảnh báo · Báo cáo & xuất file · CT đào tạo · Hoạt động

Trợ lý **xem toàn khoa** như Ban chủ nhiệm khoa, và được **thêm sinh viên**, **đề xuất sửa hồ sơ**.

### 7.1. Thêm sinh viên

Làm như mục 5.2: **Sinh viên** → **Thêm sinh viên** → nhập thông tin → giữ chọn *Tạo tài khoản đăng nhập* → **Lưu**.

### 7.2. Sửa hồ sơ sinh viên (cần Quản trị duyệt)

1. Mở hồ sơ sinh viên → **Sửa thông tin**.
2. Sửa các trường cần thiết → lưu.
3. Thay đổi **chưa có hiệu lực ngay**: ứng dụng gửi một **đề xuất** tới Quản trị. Khi Quản trị bấm **Duyệt**, thay đổi mới được áp dụng; nếu **Từ chối**, hồ sơ giữ nguyên.

### 7.3. Các việc khác

- **Báo cáo & xuất file** (mục 5.5), **Cảnh báo** (mục 5.4), **Tổng quan** (mục 5.1): như Quản trị.
- **Không làm được**: đặt lại mật khẩu, khóa hoặc xóa sinh viên; sửa chương trình đào tạo; đặt kỳ học; quản lý tài khoản cán bộ. Khi sinh viên quên mật khẩu, chuyển yêu cầu cho Quản trị.

---

## 8. Hướng dẫn cho Cố vấn học tập

**Các màn hình:** Tổng quan · Sinh viên · Cảnh báo · Báo cáo & xuất file · CT đào tạo · Hoạt động

Cố vấn học tập **chỉ thấy sinh viên các lớp mình được phân công cố vấn**. Mọi số liệu, biểu đồ và báo cáo đều tính trên phạm vi này.

### 8.1. Quy trình theo dõi lớp cố vấn

1. **Tổng quan**: xem nhanh lớp mình có bao nhiêu sinh viên bị cảnh báo, chậm tiến độ, nợ tín chỉ, và danh sách **Sinh viên cần chú ý**.
2. **Cảnh báo**: xem chi tiết lý do cảnh báo của từng sinh viên (học phần không đạt, thiếu tín chỉ so với tiến trình).
3. **Mở hồ sơ** sinh viên để xem điểm chi tiết và tiến trình theo khối kiến thức (mục 5.3).
4. Liên hệ, tư vấn sinh viên: gợi ý học lại, học cải thiện, đăng ký học phần còn thiếu.

### 8.2. Khi điểm của sinh viên sai hoặc thiếu

Điểm do sinh viên tự khai báo. Cố vấn **không sửa được** điểm; hãy nhắc sinh viên vào **Khai báo học tập** để sửa (mục 9.2). Sau khi sinh viên sửa, bấm nút **làm mới** để thấy kết quả mới.

### 8.3. Báo cáo lớp cố vấn

Màn **Báo cáo & xuất file** (mục 5.5), giới hạn trong các lớp mình cố vấn. Ví dụ: chọn mẫu *Cảnh báo học vụ lần 1* → **Xuất PDF** để nộp khoa.

### 8.4. Không làm được

Thêm hoặc sửa sinh viên, đặt lại mật khẩu, khóa tài khoản, sửa chương trình đào tạo. Liên hệ Trợ lý QT hoặc Quản trị khi cần.

> Không thấy sinh viên nào? Có thể bạn chưa được phân công lớp. Liên hệ Quản trị hoặc Trợ lý QT để được phân công cố vấn.

---

## 9. Hướng dẫn cho Sinh viên

**Các màn hình:** Trang chủ · Khai báo học tập · CT đào tạo · Hoạt động

### 9.1. Trang chủ

- **Chỉ số**: CPA, GPA kỳ gần nhất, tín chỉ tích lũy, tín chỉ còn thiếu, tín chỉ nợ, % tiến độ, cảnh báo học vụ (nếu có).
- **Tiến trình theo khối kiến thức**: mỗi khối đã đạt bao nhiêu tín chỉ, còn thiếu học phần nào.
- **Sửa hồ sơ**: cập nhật số điện thoại, email, quê quán, ngày sinh. Thay đổi có hiệu lực ngay, không cần duyệt.

### 9.2. Khai báo học tập

Sinh viên **tự khai báo** mình học học phần nào, kỳ nào, được bao nhiêu điểm, **bất cứ lúc nào, không cần duyệt**. Cố vấn học tập và khoa thấy ngay.

**Khai báo một học phần:**
1. Bấm **Khai báo học phần**.
2. **Học phần**: gõ mã hoặc tên để tìm trong chương trình đào tạo.
3. **Học kỳ**: chọn HK1, HK2 hoặc học kỳ hè, từ năm nhập học tới năm học hiện tại.
4. **Điểm**, chọn một trong hai cách:
   - **Có điểm**: nhập **điểm học phần hệ 10**, tức điểm tổng kết cuối cùng của học phần như trên bảng điểm (ví dụ `8.6`). Không nhập điểm giữa kì hay cuối kì riêng.
   - **Chưa có điểm**: học phần được ghi là *Đang học*; nhập điểm sau khi có kết quả.
5. Bấm **Lưu**.

Từ điểm hệ 10, hệ thống tự quy ra **điểm chữ**, **điểm hệ 4** và trạng thái (đạt / không đạt). Ô xem trước trong hộp thoại hiện kết quả quy đổi ngay khi bạn gõ điểm.

**Điểm trung bình học kỳ (hệ 4)** hiện ở đầu mỗi học kỳ, kèm xếp loại học lực. Cách tính: lấy điểm hệ 4 của từng học phần nhân với số tín chỉ, cộng lại, rồi chia cho tổng số tín chỉ của các học phần đã có điểm trong kỳ. Ví dụ học kỳ 1 có 7 học phần:

| Học phần | TC | Điểm 10 | Điểm chữ | Điểm 4 | Điểm 4 × TC |
|---|:-:|:-:|:-:|:-:|:-:|
| HP 1 | 3 | 9,2 | A+ | 4,0 | 12,0 |
| HP 2 | 3 | 8,6 | A | 3,7 | 11,1 |
| HP 3 | 2 | 7,4 | B | 3,0 | 6,0 |
| HP 4 | 2 | 6,8 | C+ | 2,5 | 5,0 |
| HP 5 | 3 | 5,9 | C | 2,0 | 6,0 |
| HP 6 | 4 | 8,1 | B+ | 3,5 | 14,0 |
| HP 7 | 2 | 4,2 | D | 1,0 | 2,0 |
| **Cộng** | **19** | | | | **56,1** |

Điểm trung bình học kỳ = 56,1 / 19 = **2,95** (hệ 4), học lực **Khá**.

**Sửa hoặc xóa:** ở dòng học phần, bấm **Sửa kỳ / điểm** hoặc **Xóa**.

**Học lại, học cải thiện:** khai báo lại học phần đó ở kỳ mới. Lần đạt gần nhất sẽ thay điểm cũ khi tính CPA.

**Gợi ý học phần nên học tiếp:** ứng dụng gợi ý các học phần nên đăng ký, ưu tiên học phần bắt buộc đang trễ tiến độ, có kiểm tra học phần tiên quyết. Bấm **Thêm vào kỳ này** để khai báo nhanh.

### 9.3. CT đào tạo

Xem toàn bộ chương trình đào tạo: các khối kiến thức, học phần bắt buộc/tự chọn, số tín chỉ, kỳ dự kiến, học phần tiên quyết. Dùng để lên kế hoạch học tập.

### 9.4. Hoạt động

Nhật ký các thao tác liên quan đến tài khoản của bạn.

### 9.5. Lưu ý cho sinh viên

- **Khai báo trung thực, đúng với bảng điểm chính thức.** Khoa có thể đối chiếu với bảng điểm của trường.
- Kiểm tra **Trang chủ** sau mỗi học kỳ để biết mình có bị cảnh báo học vụ hay không.
- Quên mật khẩu: liên hệ cố vấn học tập hoặc văn phòng khoa để được đặt lại.

---

## 10. Cách ứng dụng tính điểm và cảnh báo học vụ

Áp dụng **Quy chế đào tạo đại học tại ĐHQGHN** (QĐ 3626/QĐ-ĐHQGHN ngày 21/10/2022).

### 10.1. Quy đổi điểm

| Hệ 10 | 9,0–10 | 8,5–8,9 | 8,0–8,4 | 7,0–7,9 | 6,5–6,9 | 5,5–6,4 | 5,0–5,4 | 4,0–4,9 | < 4,0 |
|---|---|---|---|---|---|---|---|---|---|
| Điểm chữ | A+ | A | B+ | B | C+ | C | D+ | D | F |
| Hệ 4 | 4,0 | 3,7 | 3,5 | 3,0 | 2,5 | 2,0 | 1,5 | 1,0 | 0 |

### 10.2. GPA, CPA, xếp loại

- **GPA học kỳ**: tính mọi học phần trong kỳ, cả đạt và không đạt.
- **CPA (trung bình chung tích lũy)**: chỉ tính học phần đã đạt; học cải thiện thì lần đạt gần nhất thay điểm cũ.
- Học phần điều kiện (GDTC, GDQP-AN…) không tính vào GPA/CPA. Học kỳ hè được gộp vào học kỳ chính ngay trước nó.
- **Xếp loại** theo GPA học kỳ: Xuất sắc ≥ 3,60 · Giỏi ≥ 3,20 · Khá ≥ 2,50 · Trung bình ≥ 2,00 · Yếu < 2,00.

### 10.3. Năm đào tạo

Theo tín chỉ tích lũy: dưới 35 TC là năm 1 · 35–70 năm 2 · 71–105 năm 3 · từ 106 năm 4.

### 10.4. Cảnh báo học vụ

Xét sau mỗi học kỳ chính có điểm. Sinh viên bị cảnh báo khi vi phạm **một** trong các điều kiện:

- CPA dưới **1,20** (năm thứ nhất), **1,40** (năm 2), **1,60** (năm 3), **1,80** (các năm sau);
- GPA học kỳ dưới **0,80** ở học kỳ đầu khóa, dưới **1,00** ở các kỳ sau;
- nợ đọng điểm F quá **24 TC**, hoặc số TC không đạt trong kỳ vượt **50%** số TC đã đăng ký.

**Mức cảnh báo** theo số lần liên tiếp: *Cảnh báo lần 1* → *Cảnh báo lần 2* → quá 2 lần liên tiếp là *Thuộc diện buộc thôi học*. Một học kỳ không vi phạm thì số lần trở về 0.

**Lưu ý** (không phải cảnh báo học vụ, giúp theo dõi sớm):
- **Chậm tiến độ**: đạt dưới 80% số TC bắt buộc lẽ ra đã phải hoàn thành.
- **Nợ tín chỉ**: còn học phần chưa đạt.
- **CPA dưới 2,00** với sinh viên năm cuối (chưa đạt chuẩn tốt nghiệp).

---

## 11. Câu hỏi thường gặp

**Quên mật khẩu thì làm thế nào?**
- Sinh viên: liên hệ cố vấn học tập hoặc văn phòng khoa. Quản trị sẽ đặt lại mật khẩu về mật khẩu ban đầu; sau đó hãy đổi ngay.
- Cán bộ: liên hệ Quản trị.

**Báo "sai tên đăng nhập hoặc mật khẩu" dù nhập đúng?**
Kiểm tra bộ gõ tiếng Việt (Unikey/EVKey) đã tắt khi gõ mật khẩu, và phím Caps Lock. Nếu vẫn không được, tài khoản có thể đã bị khóa; liên hệ Quản trị.

**Vừa khai báo điểm nhưng cố vấn chưa thấy?**
Cố vấn bấm nút **làm mới** trên thanh trên cùng, hoặc **Đồng bộ ngay** ở màn Hoạt động.

**Vì sao tôi bị cảnh báo dù đã qua môn?**
Mở **Trang chủ** (sinh viên) hoặc tab **Cảnh báo** trong hồ sơ (cán bộ) để xem lý do. Thường gặp: học phần qua môn nhưng chưa khai báo, khai báo nhầm kỳ, hoặc chậm tiến độ so với kế hoạch đào tạo.

**Năm học của sinh viên hiển thị sai?**
Năm học tính theo mã sinh viên và kỳ học hiện tại. Quản trị kiểm tra lại **kỳ học hiện tại** ở màn *Kỳ học & duyệt hồ sơ*.

**Xuất PDF bị lỗi font tiếng Việt?**
Không xảy ra: font tiếng Việt đã nhúng sẵn trong ứng dụng. Nếu gặp, cập nhật lên phiên bản mới nhất.

**Có dùng được trên điện thoại không?**
Hiện ứng dụng chạy trên máy tính Windows và macOS.

**Liên hệ hỗ trợ**
Email: tranminhieu1202@gmail.com · Trang hỗ trợ: [docs/SUPPORT.md](docs/SUPPORT.md) · Chính sách quyền riêng tư: [docs/PRIVACY.md](docs/PRIVACY.md)
