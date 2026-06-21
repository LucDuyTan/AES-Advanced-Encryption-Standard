# AES-Advanced-Encryption-Standard

Chuẩn mã hóa tiên tiến AES (Advanced Encryption Standard) là thuật toán mã hóa khối đối xứng được Viện Tiêu chuẩn và Công nghệ Quốc gia Hoa Kỳ (NIST) ban hành để thay thế cho tiêu chuẩn DES đã lỗi thời. AES xử lý các khối dữ liệu cố định có kích thước 128-bit (16 byte) dựa trên các khóa mật mã có độ dài 128, 192, hoặc 256-bit. Do đặc thù của mật mã đối xứng, hệ thống sử dụng chung một khóa bí mật (Cipher Key) cho cả quy trình mã hóa (Encryption) và giải mã (Decryption).

Để áp dụng mã khối AES vào luồng dữ liệu thực tế, nhóm đề tài hướng tới hiện thực cấu trúc đa chế độ hoạt động bao gồm:

1. **Chế độ ECB (Electronic Code Book):** Mã hóa và giải mã các khối dữ liệu một cách độc lập hoàn toàn.
2. **Chế độ CBC (Cipher Block Chaining):** Khối rõ trước khi mã hóa được cộng XOR với khối mã của bước ngay trước đó. Chế độ này bắt buộc sử dụng một Véc-tơ khởi tạo (IV) có kích thước 128-bit để làm mờ khối đầu tiên.
3. **Chế độ CFB (Cipher Feedback):** Biến mã khối thành mã dòng bằng cách hồi tiếp bản mã của khối trước đó vào bộ mã hóa, sau đó lấy kết quả XOR với khối rõ hiện tại.
4. **Chế độ OFB (Output Feedback):** Tạo ra chuỗi khóa dòng độc lập với bản rõ bằng cách mã hóa lặp lại véc-tơ khởi tạo IV, sau đó lấy chuỗi khóa này XOR với bản rõ để tạo bản mã.
5. **Chế độ CTR (Counter Mode):** Hoạt động như một hệ mật mã dòng bằng cách mã hóa một bộ đếm (Counter) kết hợp giữa IV và số đếm tăng dần qua mỗi khối, sau đó XOR với bản rõ. Chế độ này tối ưu tốt nhất cho phần cứng nhờ tính song song tuyệt đối.

**Định hướng thiết kế:** Nhóm quyết định hiện thực hệ thống SoC tăng tốc phần cứng đa chức năng, hỗ trợ cả 3 độ dài khóa (128/192/256-bit) và tích hợp đồng bộ cả 5 chế độ hoạt động nêu trên (ECB, CBC, CFB, OFB, CTR).

---

## I. Kiến trúc

### 1. IP AES

<img width="407" height="482" alt="image" src="https://github.com/user-attachments/assets/7f1a6d4c-3929-48e0-a40f-82352181eed2" />

* ** Kiến trúc được sử dụng là Kiến trúc vòng lặp, tái sử dụng logic, giảm tài nguyên phần cứng, giúp tiết kiệm điện năng tiêu thụ.

### 2. Avalon-MM Bus

<img width="655" height="348" alt="image" src="https://github.com/user-attachments/assets/bc475153-8628-458b-b135-de8025435ff5" />

* **a) Nios II (Vi xử lý trung tâm):** Đây là vi xử lý lõi mềm (soft-core) được cấu hình trực tiếp trên các khối logic của chip FPGA, Nios II chịu trách nhiệm thực thi mã lệnh chương trình (C/C++), điều phối luồng dữ liệu, xử lý các tín hiệu ngắt (interrupts) và quản lý hoạt động của tất cả các khối ngoại vi còn lại. Trong hệ thống này, Nios II đóng vai trò là thiết bị chủ (Master).
* **b) Avalon-MM (Avalon Memory-Mapped Interface):** Đây là hệ thống bus giao tiếp trung tâm, đóng vai trò kết nối tất cả các thành phần trong hệ thống với nhau. Thông qua cơ chế định vị địa chỉ bộ nhớ (Memory-Mapped), Nios II có thể kết nối và điều khiển các khối ngoại vi (như DMA, Timer, AES) thông qua các địa chỉ cụ thể. Hệ thống bus này tự động xử lý các lệnh đọc/ghi dữ liệu, phân chia quyền ưu tiên truy cập và định tuyến luồng thông tin giữa thiết bị Master và Slave.
* **c) On-Chip Memory (Bộ nhớ nội):** Khối RAM/ROM này được khởi tạo từ chính tài nguyên bộ nhớ có sẵn trên chip FPGA (như các khối Block RAM). Bộ nhớ này được dùng để lưu trữ mã lệnh cho vi xử lý thực thi, đồng thời làm nơi chứa dữ liệu tạm thời (Data Memory, Stack, Heap). Nhờ được tích hợp ngay trên chip nên tốc độ truy xuất dữ liệu giữa Nios II và bộ nhớ này cực kỳ nhanh.
* **d) AES (Khối mã hóa phần cứng):** Đây là một khối IP chuyên dụng được thiết kế để xử lý thuật toán mã hóa và giải mã theo chuẩn AES bằng phần cứng. Việc đưa thuật toán AES xuống xử lý độc lập bằng phần cứng giúp hệ thống tránh được tình trạng quá tải, vì nếu chạy bằng phần mềm trên Nios II sẽ rất tốn thời gian và tài nguyên CPU. Nios II chỉ cần chuyển dữ liệu thô vào đây, khối AES sẽ xử lý song song với tốc độ cao rồi trả lại kết quả, giúp tối ưu hiệu suất cho các ứng dụng bảo mật.
* **e) JTAG - UART:** Đây là giao tiếp nối tiếp phục vụ chủ yếu cho quá trình gỡ lỗi (debug) và tương tác với người dùng. Khối này cho phép vi xử lý truyền các chuỗi ký tự (ví dụ qua hàm printf trong ngôn ngữ C) qua cáp JTAG để hiển thị lên màn hình máy tính (thông qua phần mềm Nios II SBT for Eclipse). Nhờ đó, người lập trình có thể theo dõi trạng thái hoạt động của hệ thống.
* **f) Timer (Bộ định thời):** Là khối đếm thời gian bằng phần cứng, giúp vi xử lý đo lường các khoảng thời gian hoặc tạo độ trễ (delay) chính xác. Timer cũng được dùng để tạo ra các tín hiệu ngắt định kỳ (timer interrupts). Thành phần này rất quan trọng khi hệ thống cần chạy hệ điều hành thời gian thực (RTOS) hoặc cần thực hiện các tác vụ lặp lại theo chu kỳ.
* **g) DMA_0 & DMA_1 (Truy cập bộ nhớ trực tiếp):** Hai khối này chịu trách nhiệm di chuyển các khối dữ liệu dung lượng lớn giữa bộ nhớ nội và các ngoại vi (như khối AES) một cách tự động. Quá trình này diễn ra hoàn toàn độc lập và không cần sự can thiệp liên tục từ vi xử lý Nios II. Việc trang bị hai bộ DMA cho phép hệ thống truyền nhận dữ liệu song song: một bộ chuyên đẩy dữ liệu thô vào khối AES và bộ còn lại đồng thời lấy dữ liệu đã mã hóa trả về bộ nhớ. Cơ chế này giúp giải phóng hoàn toàn băng thông cho CPU để tập trung xử lý các công việc quản lý khác, từ đó tối ưu hiệu suất tổng thể của hệ thống.

### 3. Qsys

<img width="965" height="536" alt="image" src="https://github.com/user-attachments/assets/d8856eef-7f64-4f11-a78e-c8b496f0ddb4" />

---

## II. Tài nguyên hệ thống

<img width="1034" height="523" alt="image" src="https://github.com/user-attachments/assets/6929f5b4-786b-4c81-a132-5d08017ae765" />

---

## III. So sánh kết quả nạp KIT giữa AES phần mềm và phần cứng

### 1. Phần mềm

<img width="1034" height="409" alt="image" src="https://github.com/user-attachments/assets/da27f6a9-67c4-4556-a7e1-d6206a0f284c" />

### 2. Phần cứng 

<img width="946" height="286" alt="image" src="https://github.com/user-attachments/assets/09e6be77-f7a9-45db-8d46-1b4bc92e5443" />


* **Kết luận:** Speedup khoảng trên 150 lần
