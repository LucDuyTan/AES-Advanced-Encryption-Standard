`timescale 1ns / 1ps

module mix_single_column(in, out, mode);
    input  wire        mode;
    input  wire [31:0] in;
    output wire [31:0] out;
  
    function [7:0] mb2;
        input [7:0] x; 
        begin
            mb2 = (x[7] == 1'b1) ? ((x << 1) ^ 8'h1B) : (x << 1);
        end
    endfunction
    
    function [7:0] mb4;
        input [7:0] x; 
        begin
            mb4 = mb2(mb2(x));
        end
    endfunction
    
    function [7:0] mb8;
        input [7:0] x; 
        begin
            mb8 = mb2(mb4(x));
        end
    endfunction
    
    function [7:0] mb9;
        input [7:0] x; 
        begin
            mb9 = mb8(x) ^ x;
        end
    endfunction
    
    function [7:0] mbB;
        input [7:0] x; 
        begin
            mbB = mb8(x) ^ mb2(x) ^ x;
        end
    endfunction
    
    function [7:0] mbD;
        input [7:0] x; 
        begin
            mbD = mb8(x) ^ mb4(x) ^ x;
        end
    endfunction
    
    function [7:0] mbE;
        input [7:0] x; 
        begin
            mbE = mb8(x) ^ mb4(x) ^ mb2(x);
        end
    endfunction

    wire [31:0] en_out;
    wire [31:0] de_out;

    assign en_out[31:24] = mb2(in[31:24]) ^ (mb2(in[23:16]) ^ in[23:16]) ^ in[15:8] ^ in[7:0];
    assign en_out[23:16] = in[31:24] ^ mb2(in[23:16]) ^ (mb2(in[15:8]) ^ in[15:8]) ^ in[7:0];
    assign en_out[15:8]  = in[31:24] ^ in[23:16] ^ mb2(in[15:8]) ^ (mb2(in[7:0]) ^ in[7:0]);
    assign en_out[7:0]   = (mb2(in[31:24]) ^ in[31:24]) ^ in[23:16] ^ in[15:8] ^ mb2(in[7:0]);

    assign de_out[31:24] = mbE(in[31:24]) ^ mbB(in[23:16]) ^ mbD(in[15:8]) ^ mb9(in[7:0]);
    assign de_out[23:16] = mb9(in[31:24]) ^ mbE(in[23:16]) ^ mbB(in[15:8]) ^ mbD(in[7:0]);
    assign de_out[15:8]  = mbD(in[31:24]) ^ mb9(in[23:16]) ^ mbE(in[15:8]) ^ mbB(in[7:0]);
    assign de_out[7:0]   = mbB(in[31:24]) ^ mbD(in[23:16]) ^ mb9(in[15:8]) ^ mbE(in[7:0]);

    assign out = mode ? en_out : de_out;

endmodule