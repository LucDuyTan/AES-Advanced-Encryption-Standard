`timescale 1ns / 1ps

module AES_DP(
    input wire clk,
    input wire rst,
    input wire mode,
    input wire [2:0] block_mode,
    input wire init_iv,
    input wire load_data,
    input wire run_rounds,
    input wire is_final,
    input wire update_iv,
    input wire [127:0] data_in,
    input wire [127:0] round_key,
    input wire [127:0] iv_in,
    output wire [127:0] data_out
);

    reg [127:0] state_reg;
    reg [127:0] iv_reg;

    wire [127:0] next_iv = (block_mode == 3'b000) ? iv_reg :
                           (block_mode == 3'b001) ? (mode ? state_reg : data_in) :
                           (block_mode == 3'b010) ? (mode ? (state_reg ^ data_in) : data_in) :
                           (block_mode == 3'b011) ? state_reg :
                           (iv_reg + 1'b1);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            iv_reg <= 128'd0;
        end else if (load_data && init_iv) begin
            iv_reg <= iv_in;
        end else if (update_iv) begin
            iv_reg <= next_iv;
        end
    end
    
    wire [127:0] active_iv = (load_data && init_iv) ? iv_in : iv_reg;
    wire aes_mode = (block_mode >= 3'b010) ? 1'b1 : mode;

    wire [127:0] init_data = (block_mode == 3'b000) ? data_in :
                             (block_mode == 3'b001) ? (mode ? (data_in ^ active_iv) : data_in) :
                             active_iv;
                             
    wire [127:0] init_state = init_data ^ round_key;

    wire [127:0] sub_in, sub_out;
    wire [127:0] shift_in, shift_out;
    wire [127:0] mix_in, mix_out;
    wire [127:0] add_in, add_out;
    wire [127:0] next_state;

    assign sub_in = aes_mode ? state_reg : shift_out;
    SubBytes sub_inst (
        .in(sub_in),
        .out(sub_out),
        .mode(aes_mode)
    );

    assign shift_in = aes_mode ? sub_out : state_reg;
    ShiftRows shift_inst (
        .in(shift_in),
        .out(shift_out),
        .mode(aes_mode)
    );

    assign add_in = aes_mode ? (is_final ? shift_out : mix_out) : sub_out;
    AddRoundKey add_inst (
        .in(add_in),
        .key(round_key),
        .out(add_out)
    );

    assign mix_in = aes_mode ? shift_out : add_out;
    MixColumns mix_inst (
        .in(mix_in),
        .out(mix_out),
        .mode(aes_mode)
    );

    assign next_state = aes_mode ? add_out : (is_final ? add_out : mix_out);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state_reg <= 128'd0;
        end else if (load_data) begin
            state_reg <= init_state;
        end else if (run_rounds) begin
            state_reg <= next_state;
        end
    end

    assign data_out = (block_mode == 3'b000) ? state_reg :
                      (block_mode == 3'b001) ? (mode ? state_reg : (state_reg ^ iv_reg)) :
                      (state_reg ^ data_in);

endmodule