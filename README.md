# 🛡️ SoC Hardware Accelerator for Advanced Encryption Standard (AES)

[![Platform - Intel Cyclone / Arria / Stratix](https://img.shields.io/badge/Platform-Intel_FPGA-blue.svg)]()
[![Processor - Nios II Soft-core](https://img.shields.io/badge/Processor-Nios_II-orange.svg)]()
[![Bus - Avalon-MM](https://img.shields.io/badge/Bus-Avalon--MM-green.svg)]()
[![Language - Verilog / C](https://img.shields.io/badge/Language-Verilog_%2F_C-red.svg)]()

## 📌 Tổng quan dự án
Dự án nghiên cứu và hiện thực hóa **Hệ thống SoC tăng tốc phần cứng đa chức năng cho thuật toán mã hóa khối đối xứng AES** (Advanced Encryption Standard). 

Hệ thống được tích hợp trên nền tảng FPGA sử dụng vi xử lý lõi mềm **Nios II**, kết nối qua hệ thống bus **Avalon-MM** và tăng tốc toàn diện bằng hai kênh bộ truyền dữ liệu trực tiếp **DMA**.

### 🌟 Tính năng cốt lõi:
* **Đa độ dài khóa:** Hỗ trợ linh hoạt cả 3 cấu hình khóa chuẩn mã hóa: **128-bit, 192-bit, và 256-bit**.
* **Đa chế độ hoạt động (Multi-mode):** Tích hợp đồng bộ cả 5 chế độ hoạt động chuẩn NIST nhằm đáp ứng các luồng dữ liệu thực tế:
  1. **ECB (Electronic Code Book):** Mã hóa/giải mã các khối dữ liệu độc lập hoàn toàn.
  2. **CBC (Cipher Block Chaining):** Cộng XOR khối rõ với khối mã trước đó, làm mờ bằng Vector khởi tạo (IV) 128-bit.
  3. **CFB (Cipher Feedback):** Hồi tiếp bản mã khối trước vào bộ mã hóa để biến mã khối thành mã dòng.
  4. **OFB (Output Feedback):** Mã hóa liên tục IV để tạo chuỗi khóa dòng độc lập với bản rõ.
  5. **CTR (Counter Mode):** Mã hóa bộ đếm (Counter + IV), tối ưu hóa kiến trúc phần cứng nhờ **tính song song tuyệt đối**.

---

## 🏗️ Kiến trúc hệ thống (System Architecture)

### 1. IP AES Core
Khối tính toán chuyên dụng xử lý thuật toán mã hóa và giải mã tuần tự/song song bằng phần cứng dưới dạng IP thuần cấu trúc mạch logic.

<img src="https://github.com/user-attachments/assets/7f1a6d4c-3929-48e0-a40f-82352181eed2" width="450" alt="AES IP Core Architecture"/>

### 2. Sơ đồ kết nối Bus Avalon-MM
Hệ thống SoC được thiết kế theo mô hình Master-Slave thông qua kết nối bus phân vị địa chỉ bộ nhớ (Memory-Mapped).

<img src="https://github.com/user-attachments/assets/bc475153-8628-458b-b135-de8025435ff5" width="650" alt="Avalon-MM Bus Topology"/>

#### Detailed Components:
* **Nios II (Vi xử lý trung tâm):** Lõi mềm xử lý (Master) thực thi mã lệnh điều phối (C/C++), quản lý ngắt và cấu hình các ngoại vi.
* **Avalon-MM (Avalon Memory-Mapped Interface):** Bus trung tâm tự động phân quyền ưu tiên, xử lý các lệnh đọc/ghi dữ liệu từ Master tới các Slave.
* **On-Chip Memory (Bộ nhớ nội):** Khởi tạo từ tài nguyên Block RAM nội bộ của FPGA, lưu trữ mã lệnh chương trình (Stack, Heap) với tốc độ truy xuất cực cao.
* **AES Hardware Accelerator:** Khối IP tăng tốc phần cứng độc lập, giải phóng năng lực xử lý cho Nios II Core khi gặp tác vụ mã hóa nặng.
* **JTAG - UART:** Giao tiếp nối tiếp kết nối với máy tính phục vụ công tác gỡ lỗi (Debug, `printf()`) thời gian thực thông qua Nios II SBT for Eclipse.
* **Timer (Bộ định thời):** Đo lường khoảng thời gian chính xác, tạo delay hệ thống và cấp tín hiệu ngắt định kỳ cho định thời hệ thống.
* **Dual-DMA (DMA_0 & DMA_1):** Cơ chế truy cập bộ nhớ trực tiếp kép. Một bộ chuyên đẩy dữ liệu thô vào IP AES và một bộ đồng thời lấy dữ liệu mã hóa trả lại RAM, chạy song song độc lập với CPU giúp tối ưu hóa tối đa băng thông.

### 3. Thiết kế hệ thống trên Platform Designer (Qsys)
Cấu hình kết nối phần cứng thực tế giữa vi xử lý Nios II, Bộ nhớ RAM nội bộ, các kênh DMA và IP Hardware Core của thuật toán AES.

<img src="https://github.com/user-attachments/assets/d8856eef-7f64-4f11-a78e-c8b496f0ddb4" width="900" alt="Qsys Design Hardware"/>

---

## 📊 Kết quả thực nghiệm trên KIT FPGA

### 1. Tài nguyên hệ thống tiêu thụ (Resource Utilization)
Báo cáo chi tiết sau khi thực hiện quá trình Tổng hợp mạch (Synthesis) và Định tuyến (Fitting/Routing):

<img src="https://github.com/user-attachments/assets/6929f5b4-786b-4c81-a132-5d08017ae765" width="900" alt="Fitter Resource Utilization Report"/>

### 2. So sánh hiệu năng: Mã hóa bằng Phần mềm vs Tăng tốc Phần cứng

> 🚀 **Kết luận thực nghiệm:** Quá trình đo đạc thời gian xử lý thực tế trên KIT cho thấy bộ tăng tốc phần cứng **(Hardware Accelerator)** đem lại tốc độ vượt trội gấp **hơn 150 lần** ($\approx 150\times \text{ Speedup}$) so với việc xử lý hoàn toàn bằng mã nguồn phần mềm thuần túy trên CPU lõi mềm.

#### Khởi chạy thuật toán bằng Phần mềm (Software Execution):
* Thực thi tuần tự trên tập lệnh của Nios II CPU, tiêu tốn lượng lớn chu kỳ xung nhịp cho mỗi vòng lặp mã hóa.
<img src="https://github.com/user-attachments/assets/da27f6a9-67c4-4556-a7e1-d6206a0f284c" width="900" alt="Software Execution Performance"/>

#### Khởi chạy bằng Bộ tăng tốc Phần cứng (Hardware-Accelerated):
* Dữ liệu luân chuyển trực tiếp thông qua Dual-DMA kết hợp tính toán song song tại tầng cấu trúc RTL giúp giảm thiểu tối đa độ trễ.
<img src="https://github.com/user-attachments/assets/6929f5b4-786b-4c81-a132-5d08017ae765" width="900" alt="Hardware Execution Performance"/>
