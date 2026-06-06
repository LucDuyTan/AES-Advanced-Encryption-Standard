`timescale 1ns / 1ps

module SubBytes(in, out, mode);
    input  wire         mode;
    input  wire [127:0] in;
    output wire [127:0] out; 

    s_box s15 (.in(in[127:120]), .out(out[127:120]), .mode(mode));
    s_box s14 (.in(in[119:112]), .out(out[119:112]), .mode(mode));
    s_box s13 (.in(in[111:104]), .out(out[111:104]), .mode(mode));
    s_box s12 (.in(in[103:96]),  .out(out[103:96]),  .mode(mode));
    s_box s11 (.in(in[95:88]),   .out(out[95:88]),   .mode(mode));
    s_box s10 (.in(in[87:80]),   .out(out[87:80]),   .mode(mode));
    s_box s9  (.in(in[79:72]),   .out(out[79:72]),   .mode(mode));
    s_box s8  (.in(in[71:64]),   .out(out[71:64]),   .mode(mode));
    s_box s7  (.in(in[63:56]),   .out(out[63:56]),   .mode(mode));
    s_box s6  (.in(in[55:48]),   .out(out[55:48]),   .mode(mode));
    s_box s5  (.in(in[47:40]),   .out(out[47:40]),   .mode(mode));
    s_box s4  (.in(in[39:32]),   .out(out[39:32]),   .mode(mode));
    s_box s3  (.in(in[31:24]),   .out(out[31:24]),   .mode(mode));
    s_box s2  (.in(in[23:16]),   .out(out[23:16]),   .mode(mode));
    s_box s1  (.in(in[15:8]),    .out(out[15:8]),    .mode(mode));
    s_box s0  (.in(in[7:0]),     .out(out[7:0]),     .mode(mode));
    
endmodule