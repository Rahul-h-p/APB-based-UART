module AUX_interface(sys_clk,sys_rst,aux_in,aux_i);

input sys_clk;
input sys_rst;
input [31:0] aux_in;
output reg [31:0] aux_i;

always@(posedge sys_clk or posedge sys_rst)
begin
if(sys_rst)
begin
aux_i<=32'b0;
end
else
begin
aux_i<=aux_in;
end
end
endmodule