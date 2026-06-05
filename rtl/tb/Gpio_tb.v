`timescale 1ns/1ps

`define GPIO_RGPIO_IN    32'h00
`define GPIO_RGPIO_OUT   32'h04
`define GPIO_RGPIO_OE    32'h08
`define GPIO_RGPIO_INTE  32'h0c
`define GPIO_RGPIO_PTRIG 32'h10
`define GPIO_RGPIO_AUX   32'h14
`define GPIO_RGPIO_CTRL  32'h18
`define GPIO_RGPIO_INTS  32'h1c
`define GPIO_RGPIO_ECLK  32'h20
`define GPIO_RGPIO_NEC   32'h24

module gpio_register_tb;

    reg sys_clk;
    reg sys_rst;
    reg gpio_eclk;

    initial sys_clk  = 0;
    initial gpio_eclk = 0;
    always #5  sys_clk  = ~sys_clk;   // 100 MHz
    always #20 gpio_eclk = ~gpio_eclk; // 25 MHz external clock

    reg         gpio_we;
    reg  [31:0] gpio_addr;
    reg  [31:0] gpio_dat_i;
    wire [31:0] gpio_dat_o;
    wire        gpio_inta_o;
    reg  [31:0] aux_i;
    reg  [31:0] in_pad_i;
    wire [31:0] out_pad_o;
    wire [31:0] oen_padoe_o;

   
    gpio_register DUT (
        .sys_clk    (sys_clk),
        .sys_rst    (sys_rst),
        .gpio_we    (gpio_we),
        .gpio_dat_i (gpio_dat_i),
        .gpio_addr  (gpio_addr),
        .gpio_dat_o (gpio_dat_o),
        .gpio_inta_o(gpio_inta_o),
        .out_pad_o  (out_pad_o),
        .gpio_eclk  (gpio_eclk),
        .in_pad_i   (in_pad_i),
        .oen_padoe_o(oen_padoe_o),
        .aux_i      (aux_i)
    );

    integer pass_cnt;
    integer fail_cnt;

    
    reg [31:0] rdata;

  
    task reg_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge sys_clk);
            gpio_addr  = addr;
            gpio_dat_i = data;
            gpio_we    = 1;
            @(posedge sys_clk); #1;
            @(negedge sys_clk);
            gpio_we    = 0;
            gpio_addr  = 32'hx;
            gpio_dat_i = 32'hx;
        end
    endtask

   
    task reg_read;
        input [31:0] addr;
        begin
            @(negedge sys_clk);
            gpio_addr = addr;
            gpio_we   = 0;
            @(posedge sys_clk); #1;
            @(posedge sys_clk); #1;  
            rdata = gpio_dat_o;
            @(negedge sys_clk);
            gpio_addr = 32'hx;
        end
    endtask

   
    task check;
        input [255:0] test_name;  
        input [31:0]  got;
        input [31:0]  exp;
        begin
            if (got === exp) begin
                $display("  PASS | got=%h  exp=%h  | %s", got, exp, test_name);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL | got=%h  exp=%h  | %s  *** MISMATCH ***",
                         got, exp, test_name);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

   
    initial begin
        sys_rst    = 1;
        gpio_we    = 0;
        gpio_addr  = 32'h0;
        gpio_dat_i = 32'h0;
        aux_i      = 32'h0;
        in_pad_i   = 32'h0;
        pass_cnt   = 0;
        fail_cnt   = 0;

       
        $display("\n=== TC-01: Reset ===");
        repeat(4) @(posedge sys_clk); #1;
        check("gpio_dat_o  after reset",  gpio_dat_o,  32'h0);
        check("gpio_inta_o after reset",  gpio_inta_o, 1'b0);
        check("out_pad_o   after reset",  out_pad_o,   32'h0);
        check("oen_padoe_o after reset",  oen_padoe_o, 32'h0);

        @(negedge sys_clk);
        sys_rst = 0;
        @(posedge sys_clk); #1;

        $display("\n=== TC-02: RGPIO_OUT write/read ===");
        reg_write(`GPIO_RGPIO_OUT, 32'hDEADBEEF);
        reg_read (`GPIO_RGPIO_OUT);
        check("RGPIO_OUT read-back", rdata, 32'hDEADBEEF);


        $display("\n=== TC-03: RGPIO_OE / oen_padoe_o ===");
        reg_write(`GPIO_RGPIO_OE, 32'hA5A5A5A5);
        reg_read (`GPIO_RGPIO_OE);
        check("RGPIO_OE read-back", rdata,       32'hA5A5A5A5);
        check("oen_padoe_o",        oen_padoe_o, 32'hA5A5A5A5);

        $display("\n=== TC-04: RGPIO_INTE ===");
        reg_write(`GPIO_RGPIO_INTE, 32'hFFFF0000);
        reg_read (`GPIO_RGPIO_INTE);
        check("RGPIO_INTE read-back", rdata, 32'hFFFF0000);

        $display("\n=== TC-05: RGPIO_PTRIG ===");
        reg_write(`GPIO_RGPIO_PTRIG, 32'h12345678);
        reg_read (`GPIO_RGPIO_PTRIG);
        check("RGPIO_PTRIG read-back", rdata, 32'h12345678);

     
        $display("\n=== TC-06: RGPIO_AUX ===");
        reg_write(`GPIO_RGPIO_AUX, 32'h000000FF);
        reg_read (`GPIO_RGPIO_AUX);
        check("RGPIO_AUX read-back", rdata, 32'h000000FF);

       
        $display("\n=== TC-07: RGPIO_ECLK ===");
        reg_write(`GPIO_RGPIO_ECLK, 32'hF0F0F0F0);
        reg_read (`GPIO_RGPIO_ECLK);
        check("RGPIO_ECLK read-back", rdata, 32'hF0F0F0F0);

     
        $display("\n=== TC-08: RGPIO_NEC ===");
        reg_write(`GPIO_RGPIO_NEC, 32'h0F0F0F0F);
        reg_read (`GPIO_RGPIO_NEC);
        check("RGPIO_NEC read-back", rdata, 32'h0F0F0F0F);

        $display("\n=== TC-09: RGPIO_CTRL ===");
        reg_write(`GPIO_RGPIO_CTRL, 32'h00000001); // INTE=1
        reg_read (`GPIO_RGPIO_CTRL);
        check("RGPIO_CTRL[0] INTE set",    rdata[0],    1'b1);
        check("RGPIO_CTRL[1] INTS clear",  rdata[1],    1'b0);
        check("RGPIO_CTRL upper bits zero", rdata[31:2], 30'h0);
       
        reg_write(`GPIO_RGPIO_CTRL, 32'h00000000);
        reg_read (`GPIO_RGPIO_CTRL);
        check("RGPIO_CTRL INTE cleared", rdata[0], 1'b0);

   
        $display("\n=== TC-10: out_pad_o mux ===");
        reg_write(`GPIO_RGPIO_OUT, 32'hFF00FF00);
        reg_write(`GPIO_RGPIO_AUX, 32'hFFFF0000);
        aux_i = 32'hABCDEF01;
        @(posedge sys_clk); #1;
     
        check("out_pad_o mixed AUX", out_pad_o, 32'hABCDFF00);

        reg_write(`GPIO_RGPIO_AUX, 32'h00000000);
        @(posedge sys_clk); #1;
        check("out_pad_o AUX=0 (all sys)", out_pad_o, 32'hFF00FF00);

        reg_write(`GPIO_RGPIO_AUX, 32'hFFFFFFFF);
        @(posedge sys_clk); #1;
        check("out_pad_o AUX=1 (all aux)", out_pad_o, 32'hABCDEF01);

        
        $display("\n=== TC-11: RGPIO_IN sys_clk path ===");
        reg_write(`GPIO_RGPIO_ECLK, 32'h00000000);
        in_pad_i = 32'hCAFEBABE;
        @(posedge sys_clk); #1;
        reg_read(`GPIO_RGPIO_IN);
        check("RGPIO_IN sys_clk sample", rdata, 32'hCAFEBABE);

        $display("\n=== TC-12: Ext clk posedge sample ===");
        reg_write(`GPIO_RGPIO_ECLK, 32'hFFFFFFFF);
        reg_write(`GPIO_RGPIO_NEC,  32'h00000000);
        in_pad_i = 32'h11111111;
        @(posedge gpio_eclk); #1;
        @(posedge sys_clk);   #1;
        reg_read(`GPIO_RGPIO_IN);
        check("RGPIO_IN extclk posedge", rdata, 32'h11111111);

        $display("\n=== TC-13: Ext clk negedge sample ===");
        reg_write(`GPIO_RGPIO_NEC, 32'hFFFFFFFF);
        in_pad_i = 32'h22222222;
        @(negedge gpio_eclk); #1;
        @(posedge sys_clk);   #1;
        reg_read(`GPIO_RGPIO_IN);
        check("RGPIO_IN extclk negedge", rdata, 32'h22222222);

      
        reg_write(`GPIO_RGPIO_ECLK, 32'h00000000);

      
        $display("\n=== TC-14: Interrupt generation ===");
        reg_write(`GPIO_RGPIO_CTRL,  32'h00000001); 
        reg_write(`GPIO_RGPIO_INTS,  32'h00000000); 
        reg_write(`GPIO_RGPIO_INTE,  32'hFFFFFFFF); 
        reg_write(`GPIO_RGPIO_PTRIG, 32'h00000000); 

       
        in_pad_i = 32'hFFFFFFFF;
        @(posedge sys_clk); #1;
        in_pad_i = 32'h00000000;
        @(posedge sys_clk); #1;

      
        reg_write(`GPIO_RGPIO_CTRL, 32'h00000001);
        repeat(3) @(posedge sys_clk); #1;
        check("gpio_inta_o asserted", gpio_inta_o, 1'b1);

        $display("\n=== TC-15: INTS CPU clear ===");
        reg_write(`GPIO_RGPIO_INTS, 32'h00000000);
        in_pad_i = 32'h00000000; 
        repeat(3) @(posedge sys_clk); #1;
        check("gpio_inta_o deasserted", gpio_inta_o, 1'b0);

        $display("\n=== TC-16: Default read mux ===");
        reg_write(`GPIO_RGPIO_ECLK, 32'h00000000);
        in_pad_i = 32'hBEEFCAFE;
        @(posedge sys_clk); #1;
        reg_read(32'hFF); 
        check("Default mux returns RGPIO_IN", rdata, 32'hBEEFCAFE);

        
        $display("\n=== TC-17: Register isolation ===");
        reg_write(`GPIO_RGPIO_OUT,   32'hAAAAAAAA);
        reg_write(`GPIO_RGPIO_OE,    32'hBBBBBBBB);
        reg_write(`GPIO_RGPIO_INTE,  32'hCCCCCCCC);
        reg_write(`GPIO_RGPIO_PTRIG, 32'hDDDDDDDD);
        reg_read(`GPIO_RGPIO_OUT);   check("ISO RGPIO_OUT",   rdata, 32'hAAAAAAAA);
        reg_read(`GPIO_RGPIO_OE);    check("ISO RGPIO_OE",    rdata, 32'hBBBBBBBB);
        reg_read(`GPIO_RGPIO_INTE);  check("ISO RGPIO_INTE",  rdata, 32'hCCCCCCCC);
        reg_read(`GPIO_RGPIO_PTRIG); check("ISO RGPIO_PTRIG", rdata, 32'hDDDDDDDD);

     
        $display("\n=== TC-18: Mid-operation reset ===");
        sys_rst = 1;
        repeat(4) @(posedge sys_clk); #1;
        check("Post-reset gpio_dat_o",  gpio_dat_o,  32'h0);
        check("Post-reset gpio_inta_o", gpio_inta_o, 1'b0);
        check("Post-reset out_pad_o",   out_pad_o,   32'h0);
        check("Post-reset oen_padoe_o", oen_padoe_o, 32'h0);
        sys_rst = 0;

       
        $display("\n============================================");
        $display("  Simulation complete");
        $display("  PASSED : %0d", pass_cnt);
        $display("  FAILED : %0d", fail_cnt);
        $display("============================================");
        if (fail_cnt == 0)
            $display("  *** ALL TESTS PASSED ***\n");
        else
            $display("  *** %0d TEST(S) FAILED ***\n", fail_cnt);

        $finish;
    end

    
    initial begin
        #500000;
        $display("TIMEOUT");
        $finish;
    end

   
endmodule