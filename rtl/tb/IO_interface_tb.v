module io_interface_tb;

reg ext_clk_pad_i;
wire [31:0] in_pad_i;
reg [31:0] oen_padoe_o, out_pad_o;
wire [31:0] io_pad;
wire gpio_eclk;


io_interface DUT(.ext_clk_pad_i(ext_clk_pad_i),.out_pad_o(out_pad_o),.oen_padoe_o(oen_padoe_o),.in_pad_i(in_pad_i),.io_pad(io_pad),.gpio_eclk(gpio_eclk));

reg [31:0] io_pad_temp;


initial begin
ext_clk_pad_i=1'b0;
io_pad_temp= 32'h 5555aaaa;
oen_padoe_o=32'h aaaa5555;
out_pad_o=32'h aaaa5555;

#100;
$finish;
end
always #10 ext_clk_pad_i=~ext_clk_pad_i;

generate
genvar i;
for(i=0;i<32;i=i+1)
begin : tb_pad_driver
assign io_pad[i]=~oen_padoe_o[i]? io_pad_temp[i]:1'bz;
end
endgenerate

endmodule