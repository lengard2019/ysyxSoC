module XIP( // APB转SPI
    input               clk,
    input               reset,
    
    input  [31:0]       in_paddr,
    input               in_psel,
    input               in_penable, //
    input  [2:0]        in_pprot,   // 001
    input               in_pwrite,  // 1表示写任务
    input  [31:0]       in_pwdata,
    input  [3:0]        in_pstrb,
    output              in_pready,
    output [31:0]       in_prdata,
    output              in_pslverr,

    // input               wb_rst_i,         // synchronous active high reset
    output [4:0]        wb_adr_i,         // lower address bits
    output [32-1:0]     wb_dat_i,         // databus input
    input  [32-1:0]     wb_dat_o,         // databus output
    output [3:0]        wb_sel_i,         // byte select inputs
    output              wb_we_i,          // write enable input
    output              wb_stb_i,         // stobe/core select signal // in_psel
    output              wb_cyc_i,         // valid bus cycle input
    input               wb_ack_o,         // bus cycle acknowledge output // in_pready
    input               wb_err_o,         // termination w/ error // 
    input               wb_int_o,         // interrupt request signal output

    input   [7:0]       ss_pad_o          // 传输是否完成 
);

    assign  in_pslverr  = wb_err_o;

    reg     [3:0]       current_state;
    reg     [3:0]       next_state;

    localparam  IDLE            = 0;
    // localparam  GET_ADDR    = 1;
    localparam  SPI_TX0         = 2;
    localparam  SPI_DIV         = 4;
    localparam  SPI_SS          = 5;
    localparam  SPI_CTRL        = 6;
    localparam  WAIT_DATA       = 7;
    localparam  READ_INST       = 8;


    always @(posedge clk or posedge reset) begin
        if(reset == 1'b1) begin
            current_state       <= IDLE;
        end
        else begin
            current_state       <= next_state;
        end
    end

    always @(*) begin

        case(current_state)

            IDLE: begin
                if(in_psel == 1'b1 && in_paddr >= 32'h30000000 && in_paddr < 32'h40000000) begin
                    next_state          = SPI_TX0;
                end
                else begin
                    next_state          = IDLE;
                end
            end

            SPI_TX0: begin
                if(wb_ack_o == 1'b1) begin
                    next_state              = SPI_DIV;
                end
                else begin
                    next_state              = SPI_TX0;
                end
            end

            SPI_DIV: begin
                if(wb_ack_o == 1'b1) begin
                    next_state              = SPI_SS;    
                end
                else begin
                    next_state              = SPI_DIV;
                end
            end

            SPI_SS: begin
                if(wb_ack_o == 1'b1) begin
                    next_state              = SPI_CTRL;    
                end
                else begin
                    next_state              = SPI_SS;
                end
            end

            SPI_CTRL: begin
                if(wb_ack_o == 1'b1) begin
                    next_state              = WAIT_DATA;    
                end
                else begin
                    next_state              = SPI_CTRL;
                end
            end

            WAIT_DATA: begin
                if(ss_pad_o == 8'hFF) begin
                    next_state              = READ_INST;
                end
                else begin
                    next_state              = WAIT_DATA;  
                end
            end

            READ_INST: begin
                next_state              = IDLE;
            end

            default: next_state              = IDLE;

        endcase
    end

    // reg     [31:0]          addr_r;
    wire    [31:0]          spi_cmd;
    reg     [31:0]          inst_r;
    reg     [4:0]           wb_adr_r;
    reg     [31:0]          wb_dat_r;

    assign  wb_dat_i        = wb_dat_r;
    assign  wb_adr_i        = wb_adr_r;

    assign  in_prdata       = wb_dat_o;

    assign  in_pready        = (current_state == READ_INST) ? 1'b1 : 1'b0;

    always @(*) begin
        case(current_state)
            IDLE:    wb_adr_r       = 5'b00000;
            SPI_TX0: wb_adr_r       = 5'b00100; // 0
            SPI_DIV: wb_adr_r       = 5'b10100; // 
            SPI_SS:  wb_adr_r       = 5'b11000;
            SPI_CTRL: wb_adr_r      = 5'b10000;
            WAIT_DATA: wb_adr_r      = 5'b00000;
            READ_INST: wb_adr_r      = 5'b00000;
            default: wb_adr_r       = 5'b00000;
        endcase
    end

    assign  wb_we_i         = ((current_state == SPI_TX0) || (current_state == SPI_DIV) || (current_state == SPI_SS) || (current_state == SPI_CTRL)) ? 1'b1 : 1'b0;
    assign  wb_stb_i        = ((current_state == IDLE)) ? 1'b0 : 1'b1;
    assign  wb_cyc_i        = ((current_state == IDLE)) ? 1'b0 : 1'b1;

    always @(*) begin
        case(current_state)
            SPI_TX0:  wb_dat_r     = spi_cmd;       // 0
            SPI_DIV:  wb_dat_r     = 32'h00000000;  // 
            SPI_SS:   wb_dat_r     = 32'h00000001;
            SPI_CTRL: wb_dat_r     = 32'h00002740;
            default:  wb_dat_r     = 32'h00000000;
        endcase
    end

    assign  spi_cmd         = (reset == 1'b1) ? 32'h0 : { 8'h03, in_paddr[23:0]};


    reg     [3:0]       wb_sel_r;

    assign  wb_sel_i = wb_sel_r;


    always @(*) begin
        case(current_state)
            IDLE:       wb_sel_r    = 4'b0000;
            SPI_TX0:    wb_sel_r    = 4'b1111;
            SPI_DIV:    wb_sel_r    = 4'b0001;
            SPI_SS:     wb_sel_r    = 4'b0001;
            SPI_CTRL:   wb_sel_r    = 4'b0011;
            WAIT_DATA:  wb_sel_r    = 4'b1111;
            READ_INST:  wb_sel_r    = 4'b1111;
            default: wb_sel_r    = 4'b0000;
        endcase 
    end





endmodule
