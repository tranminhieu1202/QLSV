# Chính sách quyền riêng tư – QLGD EDU

*Cập nhật: 23/10/2026*

QLGD EDU là ứng dụng quản lý tiến trình đào tạo của Khoa Quản lý Giáo dục. Tài liệu này mô tả dữ liệu ứng dụng xử lý và cách dữ liệu được bảo vệ.

## 1. Dữ liệu được lưu

Ứng dụng chỉ dùng tài khoản do Khoa cấp. Dữ liệu sau được lưu trên máy chủ cơ sở dữ liệu (Supabase) của Khoa:

- **Thông tin tài khoản**: họ tên, tên đăng nhập/email, vai trò.
- **Hồ sơ sinh viên**: mã sinh viên, lớp, khóa, cố vấn học tập; thông tin liên hệ do sinh viên tự cập nhật (số điện thoại, email, quê quán, ngày sinh).
- **Kết quả học tập**: học phần, học kỳ và điểm do sinh viên khai báo; các chỉ số tính từ đó (GPA, CPA, cảnh báo học vụ).
- **Ảnh đại diện** (nếu người dùng tự tải lên).
- **Nhật ký thao tác**: ai thực hiện thao tác gì và vào lúc nào, phục vụ đối soát.

Trên máy tính, ứng dụng chỉ ghi nhớ tên đăng nhập gần nhất và phiên đăng nhập để tiện sử dụng.

## 2. Mục đích sử dụng

Dữ liệu chỉ được dùng để theo dõi tiến trình học tập, xác định cảnh báo học vụ theo quy chế đào tạo và lập báo cáo nội bộ của Khoa.

Ứng dụng **không** hiển thị quảng cáo, **không** dùng công cụ phân tích hay theo dõi người dùng, và **không** bán hoặc chia sẻ dữ liệu cho bên thứ ba.

## 3. Ai được xem dữ liệu

Quyền truy cập được kiểm soát ở cấp cơ sở dữ liệu (Row Level Security):

- Sinh viên chỉ xem và sửa dữ liệu của chính mình.
- Cố vấn học tập xem sinh viên các lớp mình cố vấn.
- Ban chủ nhiệm khoa, trợ lý và quản trị xem dữ liệu toàn khoa theo vai trò.

Dữ liệu được truyền qua kết nối mã hóa (HTTPS).

## 4. Lưu trữ và xóa dữ liệu

Dữ liệu được lưu trong thời gian sinh viên theo học và theo quy định lưu trữ hồ sơ của Khoa. Người dùng có thể đề nghị chỉnh sửa hoặc xóa tài khoản và dữ liệu cá nhân bằng cách liên hệ quản trị viên của Khoa theo thông tin bên dưới.

## 5. Liên hệ

Mọi câu hỏi về quyền riêng tư, xin liên hệ: **tranminhieu1202@gmail.com**
