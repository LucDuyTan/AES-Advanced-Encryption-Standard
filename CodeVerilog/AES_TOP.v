module AES_TOP(
    input wire clk,
    input wire rst,
    input wire start,
    input wire mode,
    input wire [1:0] key_len,
    input wire [2:0] block_mode,
    input wire init_iv,
    input wire [255:0] key,
    input wire [127:0] iv,
    input wire [127:0] data_in,
    output wire [127:0] data_out,
    output wire valid_out,
    output wire ready
);

    wire key_start, key_ready, key_done;
    wire [3:0] key_round_idx;
    wire [127:0] key_rkey;

    reg [127:0] key_mem [0:14];

    always @(posedge clk) begin
        if (key_ready) begin
            key_mem[key_round_idx] <= key_rkey;
        end
    end

    KeyExpansion key_exp_inst (
        .clk(clk),
        .rst(rst),
        .key(key),
        .key_len(key_len),
        .start(key_start),
        .rkey(key_rkey),
        .ready(key_ready),
        .round_idx(key_round_idx),
        .done(key_done)
    );

    wire load_data, run_rounds, is_final, update_iv;
    wire [3:0] round_num;

    wire [3:0] Nr = (key_len == 2'b00) ? 4'd10 : (key_len == 2'b01) ? 4'd12 : 4'd14;
    wire aes_mode = (block_mode >= 3'b010) ? 1'b1 : mode;
    wire [3:0] fetch_idx = aes_mode ? round_num : (Nr - round_num);
    wire [127:0] round_key = key_mem[fetch_idx];

    AES_CU cu_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .key_done(key_done),
        .key_len(key_len),
        .key_start(key_start),
        .load_data(load_data),
        .run_rounds(run_rounds),
        .is_final(is_final),
        .update_iv(update_iv),
        .valid_out(valid_out),
        .ready(ready),
        .round_num(round_num)
    );

    AES_DP dp_inst (
        .clk(clk),
        .rst(rst),
        .mode(mode),
        .block_mode(block_mode),
        .init_iv(init_iv),
        .load_data(load_data),
        .run_rounds(run_rounds),
        .is_final(is_final),
        .update_iv(update_iv),
        .data_in(data_in),
        .round_key(round_key),
        .iv_in(iv),
        .data_out(data_out)
    );

endmodule