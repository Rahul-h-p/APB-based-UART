module io_interface(ext_clk_pad_i,out_pad_o,oen_padoe_o,in_pad_i,io_pad,gpio_eclk);

input ext_clk_pad_i;
output [31:0] in_pad_i;
input [31:0] oen_padoe_o, out_pad_o;
inout [31:0] io_pad;
output gpio_eclk;

assign in_pad_i=io_pad; //all pins are input by default

assign gpio_eclk=ext_clk_pad_i;

generate
genvar i;
for(i=0;i<32;i=i+1)
begin: o_pad_data
assign io_pad[i]=oen_padoe_o[i]? out_pad_o[i]:1'bz;
end
endgenerate

endmodule