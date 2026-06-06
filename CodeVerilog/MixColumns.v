`timescale 1ns / 1ps

module MixColumns(in, out, mode);
  input  wire         mode;
  input  wire [127:0] in;
  output wire [127:0] out;
  
  mix_single_column c0(.in(in[127:96]), .out(out[127:96]), .mode(mode));
  mix_single_column c1(.in(in[95:64]), .out(out[95:64]), .mode(mode)); 
  mix_single_column c2(.in(in[63:32]), .out(out[63:32]), .mode(mode)); 
  mix_single_column c3(.in(in[31:0]), .out(out[31:0]), .mode(mode));  
endmodule