`define GPIO_RGPIO_IN 32'h00 
`define GPIO_RGPIO_OUT 32'h04
`define GPIO_RGPIO_OE 32'h08 
`define GPIO_RGPIO_INTE 32'h0c 
`define GPIO_RGPIO_PTRIG 32'h10 
`define GPIO_RGPIO_AUX 32'h14
`define GPIO_RGPIO_CTRL 32'h18
`define GPIO_RGPIO_INTS 32'h1c 
`define GPIO_RGPIO_ECLK 32'h20 
`define GPIO_RGPIO_NEC 32'h24 
`define GPIO_RGPIO_CTRL_INTE 0 
`define GPIO_RGPIO_CTRL_INTS 1 


module gpio_register(sys_clk,sys_rst,gpio_we,gpio_dat_i,gpio_addr,gpio_dat_o,gpio_inta_o,out_pad_o,gpio_eclk,in_pad_i,oen_padoe_o,aux_i);

input sys_clk,sys_rst,gpio_we;
input [31:0]gpio_addr;
input [31:0]gpio_dat_i;
output reg [31:0]gpio_dat_o;
output gpio_inta_o;
input [31:0] aux_i;
input [31:0] in_pad_i;
input gpio_eclk;
output [31:0] out_pad_o;
output [31:0] oen_padoe_o;

reg [31:0] rgpio_in;
reg [31:0] rgpio_out;
reg [31:0] rgpio_oe;
reg [31:0] rgpio_inte;
reg [31:0] rgpio_ptrig;
reg [31:0] rgpio_aux;
reg [31:0] rgpio_ctrl;
reg [31:0] rgpio_ints;
reg [31:0] rgpio_eclk;

reg [31:0] rgpio_nec;
reg [31:0] dat_reg;

wire [31:0] extc_in;
reg [31:0] pextc_sampled;
reg [31:0] nextc_sampled;


always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_ctrl<=32'b0;
else if((gpio_addr==`GPIO_RGPIO_CTRL)&&gpio_we)
rgpio_ctrl[1:0]<=gpio_dat_i[1:0];
else if(rgpio_ctrl[`GPIO_RGPIO_CTRL_INTE])
rgpio_ctrl[`GPIO_RGPIO_CTRL_INTS] <= rgpio_ctrl[`GPIO_RGPIO_CTRL_INTS] | gpio_inta_o;


always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_out<=32'b0;
else if((gpio_addr==`GPIO_RGPIO_OUT) && gpio_we)
rgpio_out <= gpio_dat_i[31:0];
else 
rgpio_out <= rgpio_out;


always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_oe <= 32'b0;
else if ((gpio_addr==`GPIO_RGPIO_OE) && gpio_we)
rgpio_oe <= gpio_dat_i[31:0];


always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_inte <= 32'b0;
else if ((gpio_addr==`GPIO_RGPIO_INTE)&&gpio_we)
rgpio_inte<=gpio_dat_i[31:0];

always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_ptrig <= 32'b0;
else if((gpio_addr == `GPIO_RGPIO_PTRIG) && gpio_we)
rgpio_ptrig<=gpio_dat_i[31:0];


always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_aux<=32'b0;
else if((gpio_addr == `GPIO_RGPIO_AUX) && gpio_we)
rgpio_aux<=gpio_dat_i[31:0];

always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_eclk <= 32'b0;
else if((gpio_addr == `GPIO_RGPIO_ECLK) && gpio_we)
rgpio_eclk<=gpio_dat_i[31:0];


always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_nec<=32'b0;
else if((gpio_addr == `GPIO_RGPIO_NEC) && gpio_we)
rgpio_nec<=gpio_dat_i[31:0];


wire [31:0]in_muxed;

always@(posedge sys_clk or posedge sys_rst)
if(sys_rst)
rgpio_in<=32'b0;
else 
rgpio_in<=in_muxed;


assign in_muxed = (rgpio_eclk & extc_in) | (~rgpio_eclk & in_pad_i);
assign extc_in=(~rgpio_nec & pextc_sampled) | (rgpio_nec & nextc_sampled);

always@(posedge gpio_eclk or posedge sys_rst)
if(sys_rst)
begin
pextc_sampled<=32'b0;
end
else 
begin
pextc_sampled<=in_pad_i;
end

always@(negedge gpio_eclk or posedge sys_rst)
if(sys_rst)
begin
nextc_sampled<=32'b0;
end
else 
begin
nextc_sampled<=in_pad_i;
end


always@(*)
	case(gpio_addr)
	`GPIO_RGPIO_IN: begin	
	dat_reg=rgpio_in;
	end
	
	`GPIO_RGPIO_OUT: begin	
	dat_reg=rgpio_out;
	end
	
	`GPIO_RGPIO_OE: begin	
	dat_reg=rgpio_oe;
	end	

	`GPIO_RGPIO_INTE: begin	
	dat_reg=rgpio_inte;
	end

	`GPIO_RGPIO_PTRIG: begin	
	dat_reg=rgpio_ptrig;
	end

	`GPIO_RGPIO_NEC: begin	
	dat_reg=rgpio_nec;
	end

	`GPIO_RGPIO_ECLK: begin	
	dat_reg=rgpio_eclk;
	end

	`GPIO_RGPIO_AUX: begin	
	dat_reg=rgpio_aux;
	end

	`GPIO_RGPIO_CTRL: begin	
	dat_reg[1:0]=rgpio_ctrl[1:0];
	dat_reg[31:2]=30'b0;
	end
	`GPIO_RGPIO_INTS: begin	
	dat_reg=rgpio_ints;
	end

	default: begin
	dat_reg=rgpio_in;
	end
	endcase
	
	always@(posedge sys_clk or posedge sys_rst)
	if(sys_rst)
	gpio_dat_o<=32'b0;
	else
	gpio_dat_o<=dat_reg;
	
	
	always@(posedge sys_clk or posedge sys_rst)
	if(sys_rst)
	rgpio_ints<=32'b0;
	else if((gpio_addr==`GPIO_RGPIO_INTS) && gpio_we)
	rgpio_ints<=gpio_dat_i;
	else if (rgpio_ctrl[`GPIO_RGPIO_CTRL_INTE])
		rgpio_ints <= (rgpio_ints | ((in_muxed^rgpio_in) & ~(in_muxed^rgpio_ptrig)) & rgpio_inte);
	
	
	assign gpio_inta_o = |rgpio_ints ? rgpio_ctrl[`GPIO_RGPIO_CTRL_INTE]: 1'b0;
	assign oen_padoe_o=rgpio_oe;
	assign out_pad_o= rgpio_out & ~rgpio_aux | aux_i & rgpio_aux;
	
	endmodule