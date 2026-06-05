`timescale 1ns/1ps

module AUX_interface_tb;

reg sys_clk;
reg sys_rst;
reg [31:0] aux_in;
wire [31:0] aux_i;

AUX_interface DUT(.sys_clk(sys_clk),.sys_rst(sys_rst),.aux_in(aux_in),.aux_i(aux_i));


always #5 sys_clk=~sys_clk;

initial begin
sys_clk=0;
sys_rst=1;
aux_in=0;
@(posedge sys_clk);
#10;
@(negedge sys_clk);
sys_rst=0;
@(negedge sys_clk);
aux_in=32'hFFFFFFFF;
#10;
@(negedge sys_clk);
aux_in=32'h00000000;
#100;
$finish;
end

endmodule