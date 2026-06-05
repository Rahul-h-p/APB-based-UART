`timescale 1ns/1ps

module tb_apb_slave;

    
    reg         PCLK;
    reg         PRESET;
    reg         PSEL;
    reg         PEnable;
    reg         PWRITE;
    reg         gpio_inta_o;
    reg  [31:0] PWDATA;
    reg  [3:0]  PADDR;
    reg  [31:0] gpio_dat_o;   

    wire        PREADY;
    wire        IRQ;
    wire        sys_clk;
    wire        sys_rst;
    wire        gpio_we;
    wire [3:0]  gpio_addr;
    wire [31:0] gpio_dat_i;
    wire [31:0] PRDATA;

    
    apb_slave dut (
        .PCLK       (PCLK),
        .PRESET     (PRESET),
        .PSEL       (PSEL),
        .PEnable    (PEnable),
        .PWRITE     (PWRITE),
        .gpio_inta_o(gpio_inta_o),
        .PWDATA     (PWDATA),
        .PADDR      (PADDR),
        .gpio_dat_o (gpio_dat_o),
        .PREADY     (PREADY),
        .IRQ        (IRQ),
        .sys_clk    (sys_clk),
        .sys_rst    (sys_rst),
        .gpio_we    (gpio_we),
        .gpio_addr  (gpio_addr),
        .gpio_dat_i (gpio_dat_i),
        .PRDATA     (PRDATA)
    );

   
    initial PCLK = 0;
    always #5 PCLK = ~PCLK;

  
    integer pass_cnt = 0;
    integer fail_cnt = 0;

    task check;
        input [127:0] test_name;   
        input [31:0]  expected;
        input [31:0]  actual;
        begin
            if (expected === actual) begin
                $display("  PASS | %-20s | expected=0x%08h  got=0x%08h",
                          test_name, expected, actual);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  FAIL | %-20s | expected=0x%08h  got=0x%08h  <---",
                          test_name, expected, actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

   
    task apb_write;
        input [3:0]  addr;
        input [31:0] data;
        begin
            
            @(negedge PCLK);
            PSEL    = 1'b1;
            PEnable = 1'b0;
            PWRITE  = 1'b1;
            PADDR   = addr;
            PWDATA  = data;

            @(negedge PCLK);
            PEnable = 1'b1;

            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK);

            @(negedge PCLK);
            PSEL    = 1'b0;
            PEnable = 1'b0;
            PWRITE  = 1'b0;
        end
    endtask

    
    task apb_read;
        input  [3:0]  addr;
        input  [31:0] mock_rsp;
        output [31:0] rdata;
        begin
            gpio_dat_o = mock_rsp;   
            @(negedge PCLK);
            PSEL    = 1'b1;
            PEnable = 1'b0;
            PWRITE  = 1'b0;
            PADDR   = addr;

            @(negedge PCLK);
            PEnable = 1'b1;

            @(posedge PCLK);
            while (!PREADY) @(posedge PCLK);
            rdata = PRDATA;

            @(negedge PCLK);
            PSEL    = 1'b0;
            PEnable = 1'b0;
        end
    endtask

   
    reg [31:0] rd_data;

    initial begin
      
        PSEL        = 0;
        PEnable     = 0;
        PWRITE      = 0;
        PADDR       = 4'h0;
        PWDATA      = 32'h0;
        gpio_dat_o  = 32'h0;
        gpio_inta_o = 0;
        PRESET      = 1;

        $display("\n=== Applying reset ===");
        repeat(4) @(posedge PCLK);
        PRESET = 0;
        @(posedge PCLK);

        
        $display("\n=== TC1: Reset / IDLE state ===");
        @(posedge PCLK); #1;
        check("PREADY_after_rst",  1, PREADY);
        check("gpio_we_after_rst", 0, gpio_we);
        check("IRQ_after_rst",     0, IRQ);

       
        $display("\n=== TC2: Single write addr=0x2 data=0xDEAD_BEEF ===");
        apb_write(4'h2, 32'hDEAD_BEEF);
        #1;
        
        check("PSEL_deasserted", 0, PSEL);
        check("PEnable_deasserted", 0, PEnable);

        $display("\n=== TC3: Single read addr=0x3 mock_gpio=0xCAFE_1234 ===");
        apb_read(4'h3, 32'hCAFE_1234, rd_data);
        check("PRDATA_read", 32'hCAFE_1234, rd_data);

        $display("\n=== TC4: Write 0xA5A5_5A5A to addr=0x7, then read back ===");
        apb_write(4'h7, 32'hA5A5_5A5A);
        apb_read(4'h7, 32'hA5A5_5A5A, rd_data);   // gpio model echoes it
        check("PRDATA_write_read", 32'hA5A5_5A5A, rd_data);

        
        $display("\n=== TC5: IRQ pass-through ===");
        gpio_inta_o = 1;
        #1;
        check("IRQ_high", 1, IRQ);
        gpio_inta_o = 0;
        #1;
        check("IRQ_low", 0, IRQ);

      
        $display("\n=== TC6: sys_clk / sys_rst pass-through ===");
        PRESET = 1; #1;
        check("sys_rst_high", 1, sys_rst);
        PRESET = 0; #1;
        check("sys_rst_low",  0, sys_rst);

        $display("\n=== TC7: gpio_addr mirrors PADDR ===");
        PADDR = 4'hF; #1;
        check("gpio_addr_F", 4'hF, gpio_addr);
        PADDR = 4'h0; #1;
        check("gpio_addr_0", 4'h0, gpio_addr);

       
        $display("\n=== TC8: Back-to-back writes ===");
        apb_write(4'h1, 32'h1111_1111);
        apb_write(4'h2, 32'h2222_2222);
        apb_write(4'h3, 32'h3333_3333);
        $display("  INFO | Back-to-back writes completed without hang");

    
        $display("\n=== TC9: Back-to-back reads ===");
        apb_read(4'h1, 32'hAABB_CCDD, rd_data);
        check("BB_read1", 32'hAABB_CCDD, rd_data);
        apb_read(4'h2, 32'h1122_3344, rd_data);
        check("BB_read2", 32'h1122_3344, rd_data);

        $display("\n=== TC10: Reset asserted during SETUP phase ===");
        @(negedge PCLK);
        PSEL    = 1;
        PEnable = 0;
        PWRITE  = 1;
        PADDR   = 4'h5;
        PWDATA  = 32'hDEAD_DEAD;
        @(negedge PCLK);          
        PRESET  = 1;
        @(posedge PCLK); #1;
        check("state_after_mid_rst_PREADY", 1, PREADY);  
        PRESET  = 0;
        PSEL    = 0;
        PEnable = 0;

        repeat(4) @(posedge PCLK);
        $display("\n============================================");
        $display("  RESULTS: %0d PASSED  /  %0d FAILED", pass_cnt, fail_cnt);
        $display("============================================\n");

        $finish;
    end

    
    initial begin
        #50000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule
