`timescale 1ns / 1ps

module SubWord(in, out);
    input  wire [31:0] in;
    output wire [31:0] out; 

    s_box s3 (.in(in[31:24]), .out(out[31:24]), .mode(1'b1));
    s_box s2 (.in(in[23:16]), .out(out[23:16]), .mode(1'b1));
    s_box s1 (.in(in[15:8]),  .out(out[15:8]),  .mode(1'b1));
    s_box s0 (.in(in[7:0]),   .out(out[7:0]),   .mode(1'b1));
    
endmodule
