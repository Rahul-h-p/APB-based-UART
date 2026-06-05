
module apb_slave(
    input  wire        PCLK,
    input  wire        PRESET,
    input  wire        PSEL,
    input  wire        PEnable,
    input  wire        PWRITE,
    input  wire        gpio_inta_o,
    input  wire [31:0] PWDATA,
    input  wire [3:0]  PADDR,
    input  wire [31:0] gpio_dat_o,

    output reg         PREADY,
    output wire        IRQ,
    output wire        sys_clk,
    output wire        sys_rst,
    output reg         gpio_we,
    output wire [3:0]  gpio_addr,
    output reg  [31:0] gpio_dat_i,
    output reg  [31:0] PRDATA
);

    // Combinational pass-throughs (wire outputs only)
    assign IRQ       = gpio_inta_o;
    assign gpio_addr = PADDR;
    assign sys_rst   = PRESET;
    assign sys_clk   = PCLK;

 
    // FSM state encoding

    parameter IDLE   = 2'b00;
    parameter Setup  = 2'b01;
    parameter Enable = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge PCLK or posedge PRESET) begin
        if (PRESET)
            state <= IDLE;
        else
            state <= next_state;
    end

   
    always @(*) begin
        case (state)
            IDLE: begin
                if (PSEL && !PEnable)
                    next_state = Setup;
                else
                    next_state = IDLE;
            end

            Setup: begin
                if (PSEL && PEnable)
                    next_state = Enable;
                else if (PSEL && !PEnable)
                    next_state = Setup;
                else
                    next_state = IDLE;
            end

            Enable: begin
                if (PSEL && !PEnable)
                    next_state = Setup;   
                else if (!PSEL)
                    next_state = IDLE;
                else
                    next_state = Enable;  // PSEL high, PEnable high: stay
            end

            default: next_state = IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        

        case (state)
            IDLE: begin
                PREADY = 1'b1;
            end

            Setup: begin
                PREADY = 1'b0;
            end

            Enable: begin
                PREADY = 1'b1;
                if (!PWRITE) begin
                    // Read transfer: drive PRDATA from GPIO block
                    PRDATA = gpio_dat_o;
					gpio_we    = 1'b0;
                end else begin
                    // Write transfer: strobe write-enable and data
                    gpio_we    = 1'b1;
                    gpio_dat_i = PWDATA;
                end
            end

            default: PREADY = 1'b1;
        endcase
    end


endmodule
