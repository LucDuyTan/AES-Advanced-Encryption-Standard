`timescale 1ns / 1ps

module AddRoundKey(in, key, out);
    input [127:0] in;
    input [127:0] key;
    output [127:0] out;

    assign out = in ^ key;
endmodule