`timescale 1ns / 1ps

module KeyExpansion(clk, rst, key, key_len, start, rkey, ready, round_idx, done);
    input wire clk;
    input wire rst;
    input wire [1:0] key_len;
    input wire start;
    input wire [255:0] key;
    output reg [127:0] rkey;
    output reg ready;
    output reg [3:0] round_idx;
    output reg done;
  
    function [31:0] rc(input [3:0] idx);
        case (idx)
            4'd1:  rc = {8'h01, 24'h000000};
            4'd2:  rc = {8'h02, 24'h000000};
            4'd3:  rc = {8'h04, 24'h000000};
            4'd4:  rc = {8'h08, 24'h000000};
            4'd5:  rc = {8'h10, 24'h000000};
            4'd6:  rc = {8'h20, 24'h000000};
            4'd7:  rc = {8'h40, 24'h000000};
            4'd8:  rc = {8'h80, 24'h000000};
            4'd9:  rc = {8'h1B, 24'h000000};
            4'd10: rc = {8'h36, 24'h000000};
            default: rc = 32'h00000000;
        endcase
    endfunction
  
    localparam IDLE  = 2'b00;
    localparam INIT0 = 2'b01; 
    localparam INIT1 = 2'b10; 
    localparam GEN   = 2'b11; 
  
    reg [1:0] cur;
    reg [31:0] w [0:7];
    reg [5:0] i;
    
    reg [2:0] nk_cnt;
    reg [3:0] ridx;
    wire [2:0] nk_max = (key_len == 2'b00) ? 3'd3 : (key_len == 2'b01) ? 3'd5 : 3'd7;
  
    wire [31:0] rot_w;
    RotWord rw(.in(w[7]), .out(rot_w));
  
    wire is_nk   = (nk_cnt == 3'd0);
    wire is_nk_4 = (key_len == 2'b10 && nk_cnt == 3'd4);

    wire [31:0] sub_in = is_nk ? rot_w : w[7];
    wire [31:0] sub_w;
    SubWord sw(.in(sub_in), .out(sub_w));

    wire [31:0] rcon = rc(ridx);
  
    wire [31:0] w_old = (key_len == 2'b00) ? w[4] :
                        (key_len == 2'b01) ? w[2] :
                        w[0];

    wire [31:0] w_next = is_nk   ? (w_old ^ sub_w ^ rcon) :
                         is_nk_4 ? (w_old ^ sub_w) :
                                   (w_old ^ w[7]);
                  
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            cur <= IDLE;
            i <= 6'd0;
            ready <= 1'b0;
            rkey <= 128'd0;
            round_idx <= 4'd0;
            done <= 1'b0;
        end else begin
            ready <= 1'b0;
            done <= 1'b0;
            case(cur)
                IDLE: begin
                    if(start) begin
                        nk_cnt <= 3'd0;    
                        ridx <= 4'd1;
                        if (key_len == 2'b00) begin
                            {w[4], w[5], w[6], w[7]} <= key[127:0];
                            i <= 6'd4;
                        end else if (key_len == 2'b01) begin
                            {w[2], w[3], w[4], w[5], w[6], w[7]} <= key[191:0];
                            i <= 6'd6;
                        end else begin
                            {w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7]} <= key[255:0];
                            i <= 6'd8;
                        end
                        cur <= INIT0;
                    end
                end
        
                INIT0: begin
                    if (key_len == 2'b00) rkey <= {w[4], w[5], w[6], w[7]};
                    else if (key_len == 2'b01) rkey <= {w[2], w[3], w[4], w[5]};
                    else rkey <= {w[0], w[1], w[2], w[3]};
                    ready <= 1'b1;
                    round_idx <= 4'd0;
                    
                    if (key_len == 2'b10) cur <= INIT1;
                    else cur <= GEN;
                end
        
                INIT1: begin
                    rkey <= {w[4], w[5], w[6], w[7]};
                    ready <= 1'b1;
                    round_idx <= 4'd1;
                    cur <= GEN;
                end  
        
                GEN: begin
                    w[0] <= w[1]; w[1] <= w[2]; w[2] <= w[3]; w[3] <= w[4];
                    w[4] <= w[5]; w[5] <= w[6]; w[6] <= w[7]; w[7] <= w_next;  
                    
                    if (nk_cnt == nk_max) begin
                        nk_cnt <= 3'd0;
                        ridx <= ridx + 1'b1; 
                    end else begin
                        nk_cnt <= nk_cnt + 1'b1;
                    end
                    
                    if(i[1:0] == 2'b11) begin
                        rkey <= {w[5], w[6], w[7], w_next};
                        ready <= 1'b1;
                        round_idx <= round_idx + 1'b1;
                    end
                    
                    if( (key_len == 2'b00 && i == 6'd43) ||
                        (key_len == 2'b01 && i == 6'd51) ||
                        (key_len == 2'b10 && i == 6'd59) ) begin
                        cur <= IDLE;
                        done <= 1'b1;
                    end
                    else i <= i + 1'b1;
                end
            endcase
        end 
    end
endmodule