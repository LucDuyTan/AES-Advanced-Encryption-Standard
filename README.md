# AES-Advanced-Encryption-Standard
Chuẩn mã hóa tiên tiến AES (Advanced Encryption Standard) là thuật toán mã hóa khối đối xứng được Viện Tiêu chuẩn và Công nghệ Quốc gia Hoa Kỳ (NIST) ban hành để thay thế cho tiêu chuẩn DES đã lỗi thời. AES xử lý các khối dữ liệu cố định có kích thước 128-bit (16 byte) dựa trên các khóa mật mã có độ dài 128, 192, hoặc 256-bit. Do đặc thù của mật mã đối xứng, hệ thống sử dụng chung một khóa bí mật (Cipher Key) cho cả quy trình mã hóa (Encryption) và giải mã (Decryption).
Để áp dụng mã khối AES vào luồng dữ liệu thực tế, nhóm đề tài hướng tới hiện thực cấu trúc đa chế độ hoạt động bao gồm:
1.	Chế độ ECB (Electronic Code Book): Mã hóa và giải mã các khối dữ liệu một cách độc lập hoàn toàn.
2.	Chế độ CBC (Cipher Block Chaining): Khối rõ trước khi mã hóa được cộng XOR với khối mã của bước ngay trước đó. Chế độ này bắt buộc sử dụng một Véc-tơ khởi tạo (IV) có kích thước 128-bit để làm mờ khối đầu tiên.
3.	Chế độ CFB (Cipher Feedback): Biến mã khối thành mã dòng bằng cách hồi tiếp bản mã của khối trước đó vào bộ mã hóa, sau đó lấy kết quả XOR với khối rõ hiện tại.
4.	Chế độ OFB (Output Feedback): Tạo ra chuỗi khóa dòng độc lập với bản rõ bằng cách mã hóa lặp lại véc-tơ khởi tạo IV, sau đó lấy chuỗi khóa này XOR với bản rõ để tạo bản mã.
5.	Chế độ CTR (Counter Mode): Hoạt động như một hệ mật mã dòng bằng cách mã hóa một bộ đếm (Counter) kết hợp giữa IV và số đếm tăng dần qua mỗi khối, sau đó XOR với bản rõ. Chế độ này tối ưu tốt nhất cho phần cứng nhờ tính song song tuyệt đối.
Định hướng thiết kế: Nhóm quyết định hiện thực hệ thống SoC tăng tốc phần cứng đa chức năng, hỗ trợ cả 3 độ dài khóa (128/192/256-bit) và tích hợp đồng bộ cả 5 chế độ hoạt động nêu trên (ECB, CBC, CFB, OFB, CTR).
