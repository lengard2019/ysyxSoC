module gpio_top_apb(
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output [15:0] gpio_out, // 16位数据, 分别驱动16个LED灯
  input  [15:0] gpio_in,  // 16位数据, 分别获得16个拨码开关的状态
  output [7:0]  gpio_seg_0, // 32位数据, 其中每4位驱动1个7段数码管
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);

  localparam IDLE     = 0;
  localparam WRITE    = 1;
  localparam READ     = 2;

    // reg     [31:0]      m_time_low;
    // reg     [31:0]      m_time_high;
    reg     [15:0]      led_r; // 0
    // reg     [15:0]      sw_r; // 4
    reg     [31:0]      seg_r;


    reg     [3:0]       current_state;
    reg     [3:0]       next_state;

    reg     [31:0]      r_data;

    wire    [3:0]       addr = in_paddr[3:0];

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            current_state   <= IDLE;
        end
        else begin
            current_state   <= next_state;
        end
    end

    always @(*) begin

        case(current_state)
            
            IDLE: begin
                if(in_psel == 1'b1 && in_pwrite == 1'b1) begin
                   next_state   = WRITE; 
                end
                else if(in_psel == 1'b1 && in_pwrite == 1'b0) begin
                    next_state   = READ;
                end
                else begin
                    next_state   = IDLE;
                end
            end

            WRITE: begin
                if(in_penable) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = WRITE;
                end 
            end

            READ: begin
                if(in_penable) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = READ;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clock or posedge reset) begin
        if(reset) begin
            led_r  <= 16'h0000;
        end
        else  begin
            if(current_state == WRITE) begin
                if(addr == 4'h0) begin // led
                    led_r  <= in_pwdata[15:0];
                end
                else if(addr == 4'h8) begin // seg
                    seg_r  <= in_pwdata;
                end
            end
            else begin

            end
        end
    end

    assign  gpio_out  = led_r;

    always @(*) begin
        if(current_state == READ) begin
            if(addr == 4'h4) begin
                r_data = {16'h0000, gpio_in};
            end
                r_data = 32'h0000;
            end
        else begin
            r_data = 32'h0000;
        end
    end

    bcd7seg u_seg0(
      .b        (seg_r[3:0]),
      .seg1     (gpio_seg_0[7:1])
    );

    bcd7seg u_seg1(
      .b        (seg_r[7:4]),
      .seg1     (gpio_seg_1[7:1])
    );

    bcd7seg u_seg2(
      .b        (seg_r[11:8]),
      .seg1     (gpio_seg_2[7:1])
    );

    bcd7seg u_seg3(
      .b        (seg_r[15:12]),
      .seg1     (gpio_seg_3[7:1])
    );

    bcd7seg u_seg4(
      .b        (seg_r[19:16]),
      .seg1     (gpio_seg_4[7:1])
    );

    bcd7seg u_seg5(
      .b        (seg_r[23:20]),
      .seg1     (gpio_seg_5[7:1])
    );

    bcd7seg u_seg6(
      .b        (seg_r[27:24]),
      .seg1     (gpio_seg_6[7:1])
    );

    bcd7seg u_seg7(
      .b        (seg_r[31:28]),
      .seg1     (gpio_seg_7[7:1])
    );

    assign in_pready = (current_state == WRITE || current_state == READ);
    assign in_pslverr = 1'b0;
    assign in_prdata = r_data;

    assign gpio_seg_0[0]  = 1'b1;
    assign gpio_seg_1[0]  = 1'b1;
    assign gpio_seg_2[0]  = 1'b1;
    assign gpio_seg_3[0]  = 1'b1;
    assign gpio_seg_4[0]  = 1'b1;
    assign gpio_seg_5[0]  = 1'b1;
    assign gpio_seg_6[0]  = 1'b1;
    assign gpio_seg_7[0]  = 1'b1;

endmodule


module bcd7seg(
  input  [3:0] b,
  output reg [6:0] seg1
);
// detailed implementation ...
  always @(*) begin
    case (b)
      4'b0000 : seg1 = 7'b0000001;
      4'b0001 : seg1 = 7'b1001111;
      4'b0010 : seg1 = 7'b0010010;
      4'b0011 : seg1 = 7'b0000110;
      4'b0100 : seg1 = 7'b1001100;
      4'b0101 : seg1 = 7'b0100100;
      4'b0110 : seg1 = 7'b0100000;
      4'b0111 : seg1 = 7'b0001111;
      4'b1000 : seg1 = 7'b0000000;
      4'b1001 : seg1 = 7'b0000100;
      4'b1010 : seg1 = 7'b0001000;
      4'b1011 : seg1 = 7'b1100000;
      4'b1100 : seg1 = 7'b0110001;
      4'b1101 : seg1 = 7'b1000010;
      4'b1110 : seg1 = 7'b1100000;
      4'b1111 : seg1 = 7'b0111000;
      default : seg1 = 7'b1111111;
    endcase
  end
endmodule
