#include <stdio.h>
#include <string.h>
#include <system.h>
#include <io.h>
#include <alt_types.h>
#include <sys/alt_timestamp.h>

#define AES_REG_CTRL          (0 * 4)
#define AES_REG_KEY0          (1 * 4)
#define AES_REG_DATA_IN       (13 * 4)
#define AES_REG_DATA_OUT      (14 * 4)

#define AES_CTRL_MODE_ENC     1
#define AES_CTRL_RESET_CNT    (1 << 6)
#define KEY_128 0
#define MODE_ECB 0

void aes_configure(alt_u8 mode, alt_u8 key_len, alt_u8 block_mode) {
    alt_u32 ctrl = AES_CTRL_RESET_CNT | ((block_mode & 0x07) << 3) | ((key_len & 0x03) << 1) | (mode & 0x01);
    IOWR_32DIRECT(AES_0_BASE, AES_REG_CTRL, ctrl);
    ctrl &= ~AES_CTRL_RESET_CNT;
    IOWR_32DIRECT(AES_0_BASE, AES_REG_CTRL, ctrl);
}

void aes_set_key(const alt_u8 *key_bytes, alt_u8 key_len) {
    int i;
    for (i = 0; i < 4; i++) {
        // Đóng gói Byte theo chuẩn Big-Endian
        alt_u32 word = (key_bytes[i * 4 + 0] << 24) |
                       (key_bytes[i * 4 + 1] << 16) |
                       (key_bytes[i * 4 + 2] << 8)  |
                       (key_bytes[i * 4 + 3]);

        IOWR_32DIRECT(AES_0_BASE, AES_REG_KEY0 + ((3 - i) * 4), word);
    }
}

int aes_process_data_cpu_polling_timed(const alt_u32 *src_addr, alt_u32 *dst_addr, alt_u32 num_blocks, alt_u64 *execution_ticks) {
    alt_u32 b;
    alt_u64 start_time, end_time;

    start_time = alt_timestamp();

    for (b = 0; b < num_blocks; b++) {
        // THAY ĐỔI: Nạp Data_In theo chiều ngược lại (Word 3 -> 0)
        IOWR_32DIRECT(AES_0_BASE, AES_REG_DATA_IN, src_addr[b*4 + 3]);
        IOWR_32DIRECT(AES_0_BASE, AES_REG_DATA_IN, src_addr[b*4 + 2]);
        IOWR_32DIRECT(AES_0_BASE, AES_REG_DATA_IN, src_addr[b*4 + 1]);
        IOWR_32DIRECT(AES_0_BASE, AES_REG_DATA_IN, src_addr[b*4 + 0]);

        alt_u32 status;
        volatile int timeout = 5000000;
        do {
            status = IORD_32DIRECT(AES_0_BASE, AES_REG_CTRL);
            timeout--;
        } while (((status & (1 << 17)) == 0) && timeout > 0);

        if (timeout <= 0) {
            return -1;
        }

        // THAY ĐỔI: Đọc Data_Out theo chiều ngược lại (Word 3 -> 0)
        dst_addr[b*4 + 3] = IORD_32DIRECT(AES_0_BASE, AES_REG_DATA_OUT);
        dst_addr[b*4 + 2] = IORD_32DIRECT(AES_0_BASE, AES_REG_DATA_OUT);
        dst_addr[b*4 + 1] = IORD_32DIRECT(AES_0_BASE, AES_REG_DATA_OUT);
        dst_addr[b*4 + 0] = IORD_32DIRECT(AES_0_BASE, AES_REG_DATA_OUT);
    }

    end_time = alt_timestamp();
    *execution_ticks = (end_time - start_time);
    return 0;
}

alt_u32 apply_pkcs7_padding(const char* input_str, alt_u32* padded_buffer) {
    alt_u32 input_len = strlen(input_str);
    alt_u32 padded_len = ((input_len / 16) + 1) * 16;
    alt_u8 pad_value = padded_len - input_len;
    alt_u32 i, j;

    memset(padded_buffer, 0, padded_len);

    for (i = 0; i < padded_len; i += 4) {
        alt_u32 word = 0;
        for (j = 0; j < 4; j++) {
            alt_u8 b = (i + j < input_len) ? (alt_u8)input_str[i + j] : pad_value;
            word |= ((alt_u32)b << ((3 - j) * 8));
        }
        padded_buffer[i / 4] = word;
    }
    return padded_len / 16;
}

void test_string_performance(const char* input_str, const alt_u8* key, alt_u32 timer_freq) {
    alt_u32 plain_text_buffer[64] = {0};
    alt_u32 cipher_text_buffer[64] = {0};
    alt_u64 total_ticks = 0;

    alt_u32 num_blocks = apply_pkcs7_padding(input_str, plain_text_buffer);

    aes_configure(AES_CTRL_MODE_ENC, KEY_128, MODE_ECB);
    aes_set_key(key, KEY_128);

    int status = aes_process_data_cpu_polling_timed(plain_text_buffer, cipher_text_buffer, num_blocks, &total_ticks);

    if (status != 0) {
        printf("Loi: Ket phan cung!\n\n");
        return;
    }

    double time_in_seconds = (double)total_ticks / (double)timer_freq;

    printf("Du lieu dau vao: %s\n", input_str);
    printf("Du lieu dau ra: ");

    alt_u32 i;
    for (i = 0; i < num_blocks * 4; i++) {
        alt_u32 word = cipher_text_buffer[i];
        printf("%02X%02X%02X%02X",
               (unsigned int)((word >> 24) & 0xFF),
               (unsigned int)((word >> 16) & 0xFF),
               (unsigned int)((word >> 8) & 0xFF),
               (unsigned int)(word & 0xFF));
    }
    printf("\n");
    printf("Hieu suat: %llu ticks (%.6f s)\n\n", total_ticks, time_in_seconds);
}

int main() {
    if (alt_timestamp_start() < 0) {
        printf("Loi: Khong the khoi tao High-Resolution Timestamp Timer!\n");
        return -1;
    }
    alt_u32 timer_freq = alt_timestamp_freq();

    alt_u8 test_key[16] = { 0x2b, 0x7e, 0x15, 0x16,
                            0x28, 0xae, 0xd2, 0xa6,
                            0xab, 0xf7, 0x15, 0x88,
                            0x09, 0xcf, 0x4f, 0x3c };

    test_string_performance("truo", test_key, timer_freq);
    test_string_performance("truongdaihoccongnghethongtin", test_key, timer_freq);

    return 0;
}
*/

/*
#include <stdio.h>
#include <string.h>
#include "system.h"
#include <sys/alt_timestamp.h>
#include "aes.h"

uint32_t apply_pkcs7_padding_sw(const char* input_str, uint8_t* padded_buffer) {
    uint32_t input_len = strlen(input_str);
    uint32_t padded_len = ((input_len / 16) + 1) * 16;
    uint8_t pad_value = padded_len - input_len;

    uint32_t i;
    for (i = 0; i < input_len; i++) {
        padded_buffer[i] = (uint8_t)input_str[i];
    }

    for (i = input_len; i < padded_len; i++) {
        padded_buffer[i] = pad_value;
    }

    return padded_len;
}

void test_aes_software_string(const char* input_str, uint8_t* key) {
    uint8_t buffer[512] = {0};

    uint32_t total_bytes = apply_pkcs7_padding_sw(input_str, buffer);

    struct AES_ctx ctx;
    AES_init_ctx(&ctx, key);

    alt_u32 time_start, time_end, total_ticks;
    alt_u32 timer_freq = alt_timestamp_freq();

    time_start = alt_timestamp();

    uint32_t b;
    for (b = 0; b < (total_bytes / 16); ++b) {
        AES_ECB_encrypt(&ctx, buffer + (b * 16));
    }

    time_end = alt_timestamp();

    total_ticks = time_end - time_start;
    double time_in_seconds = (double)total_ticks / (double)timer_freq;

    printf("Du lieu dau vao: %s\n", input_str);

    printf("Du lieu dau ra: ");
    uint32_t i;
    for (i = 0; i < total_bytes; i++) {
        printf("%02X", buffer[i]);
    }
    printf("\n");

    printf("Hieu suat: %lu ticks (%.6f s)\n\n", total_ticks, time_in_seconds);
}

int main() {
    if (alt_timestamp_start() < 0) {
        printf("Loi: Khong the khoi tao Timestamp Timer!\n");
        return 1;
    }

    uint8_t key[16] = { 0x2b, 0x7e, 0x15, 0x16,
                        0x28, 0xae, 0xd2, 0xa6,
                        0xab, 0xf7, 0x15, 0x88,
                        0x09, 0xcf, 0x4f, 0x3c };

    test_aes_software_string("truongdaihoccongnghethongtin", key);
    test_aes_software_string("truo", key);

    return 0;
}
*/

