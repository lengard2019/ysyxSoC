module sdram(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [13:0] a,
  input [ 1:0] ba,
  input [ 3:0] dqm,
  inout [31:0] dq
);

  localparam  IDLE          = 0;
  localparam  ACTIVE        = 1;
  localparam  READ_LATENCY  = 2;
  // localparam  WRITE_LATENCY = 3;
  localparam  READ_BURST    = 4;
  localparam  WRITE_BURST   = 5;


  reg   [3:0]     burst_len;
  reg   [2:0]     cas_latency;

  reg   [13:0]    mode_reg;

  reg   [31:0]    data;
  wire  [31:0]    data_wr;

  reg   [3:0]     mode;

  wire   [3:0]    mask;

  assign  mask  = dqm;

  assign mode = {cs, ras, cas, we};

  reg   [3:0]     state;
  // reg   [3:0]     next_state;

  reg   [2:0]     latency_cnt;
  reg   [3:0]     burst_cnt;

  wire  [1:0]     bank;
  wire  [15:0]    col;

  reg   [15:0]    row_0;
  reg   [15:0]    row_1;
  reg   [15:0]    row_2;
  reg   [15:0]    row_3;
  reg   [15:0]    row;
  // reg   [15:0]    row_r;

  always @(*) begin
    case(mode_reg[2:0])  // burst_len
      3'b000: burst_len = 4'h1;
      3'b001: burst_len = 4'h2;
      3'b010: burst_len = 4'h4;
      3'b011: burst_len = 4'h8;
      3'b111: burst_len = 4'hf;
      default: burst_len = 4'h0;
    endcase
  end

  assign  cas_latency = mode_reg[6:4]; // cas_latency

  always @(posedge clk or negedge cke) begin
    if(!cke) begin
      mode_reg  <= 14'h0000;
    end
    else begin
      if(mode == 4'b0000) begin // LOAD MODE REGISTER
          mode_reg <= a;
      end
    end
  end

  always @(posedge clk or negedge cke) begin
    if(!cke) begin
      state       <= IDLE;
    end
    else begin
      case(state)

        IDLE: begin
          if(mode == 4'b0101) begin // read
            state   <= READ_LATENCY;
          end
          else if(mode == 4'b0100) begin // write
            state   <= WRITE_BURST;
          end
          else begin
            state   <= IDLE;
          end
        end

        READ_LATENCY: begin
          if(latency_cnt == cas_latency - 1) begin
            state   <= READ_BURST;
          end
          else begin
            state   <= READ_LATENCY;
          end
        end

        READ_BURST: begin
          if(burst_cnt == burst_len) begin
            state   <= IDLE;
          end
          else begin
            state   <= READ_BURST;
          end
        end

        WRITE_BURST: begin
          if(burst_cnt == burst_len) begin
            state   <= IDLE;
          end
          else begin
            state   <= WRITE_BURST;
          end
        end
      endcase
    end
  end

  always @(posedge clk or negedge cke) begin
    if(!cke) begin
      row_0 <= 16'h0000;
      row_1 <= 16'h0000;
      row_2 <= 16'h0000;
      row_3 <= 16'h0000;
    end
    else if(mode == 4'b0011) begin
      if(ba == 2'b00) begin
        row_0   <= {2'b00, a};
      end
      else if(ba == 2'b01) begin
        row_1   <= {2'b00, a};
      end
      else if(ba == 2'b10) begin
        row_2   <= {2'b00, a};
      end
      else if(ba == 2'b11) begin
        row_3   <= {2'b00, a};
      end
    end
  end

  always @(*) begin
    case(bank) 
      2'b00: row = row_0;
      2'b01: row = row_1;
      2'b10: row = row_2;
      2'b11: row = row_3;
    endcase
  end

  always @(posedge clk or negedge cke) begin // write
    if(!cke) begin
      // row   <= 16'h0000;
      // data_wr <= 32'h0000;
      burst_cnt <= 4'h0;
      latency_cnt <= 3'b000;
      // bank    <= 2'b00;
      // ren   <= 1'b0;
      // wen   <= 1'b0;
      // mask  <= 4'b0000;
      // bank  <= 2'b00;
      // col   <= 16'h0000;
    end
    else begin
      // if(mode == 4'b0011) begin // active
      //   // bank  <= ba;
      //   // row   <= {3'b000, a};
      // end
      if(mode == 4'b0100) begin // write
        // col     <= {3'b000, a};
        burst_cnt   <= burst_cnt + 1;
        // data_wr <= dq;
        // wen     <= 1'b1;
        // ren   <= 1'b0;
        // bank    <= ba;
        // mask  <= dqm;
      end
      else if(mode == 4'b0101) begin // read
        // col   <= {3'b000, a};
        latency_cnt <= latency_cnt + 1;
        burst_cnt   <= burst_cnt + 1;
        // wen   <= 1'b0;
        // bank  <= ba;
        // col   <= {3'b000, a};
      end
      else if(mode == 4'b0111 && state == WRITE_BURST) begin // NOP
        burst_cnt   <= burst_cnt + 1;
        // col         <= col + 1;
        // data_wr     <= dq;
        // wen   <= 1'b0;
        // mask  <= dqm;
      end
      else if(mode == 4'b0111 && state == READ_LATENCY) begin
        latency_cnt <= latency_cnt + 1;
        // col     <= {3'b000, a};
      end
      else if(mode == 4'b0111 && state == READ_BURST) begin
        burst_cnt   <= burst_cnt + 1;
        // col         <= col + 1;
        // ren         <= 1'b1;
      end
      else begin
        burst_cnt   <= 4'h0;
        latency_cnt <= 3'b000;
        // ren   <= 1'b0;
        // wen     <= 1'b0;
      //   bank    <= 2'b00;
      //   col     <= 16'h0000;
      end
    end
  end

  // reg   [31:0] data_out;

  // wire  [31:0] data_out_w;
  // assign  data_out_w  = data_out;

  // always @(posedge clk or negedge cke) begin
  //   if(!cke) begin
  //     data_out    <= 32'h0000;
  //   end
  //   else begin
  //     data_out    <= data;
  //   end
  // end

  assign  bank  = ba;
  assign  col   = (mode == 4'b0100 || mode == 4'b0101) ? {2'b00, a} : 16'h0000;

  // assign wen = (mode == 4'b0100) ? 1'b1 : 1'b0;

  // assign  ren = (state == READ_BURST) ? 1'b1 : 1'b0;
  // assign  wen = (state == WRITE_BURST);

  assign  dq = (mode == 4'b0100) ? 32'bz : data;
  assign  data_wr = (mode == 4'b0100) ? dq : 32'b0;
  sdram_cmd sdram_cmd_i(
    .clock        (clk      ),
    .mode         (mode     ),
    .bank         (bank     ),
    .mask         (mask     ),
    .col          (col      ),
    .row          (row      ),
    .data_wr      (data_wr  ),
    .data         (data     )
  );

endmodule

import "DPI-C" function void sdram0_read(input byte bank,  input shortint row, input shortint col, output int data);
import "DPI-C" function void sdram0_write(input byte bank, input shortint row, input shortint col, input byte mask, input int data);

module sdram_cmd(
    input               clock,
    // input               ren,
    // input               wen,
    input       [3:0]   mode,
    input       [3:0]   mask,
    input       [1:0]   bank,
    input       [15:0]  col, 
    input       [15:0]  row,
    input       [31:0]  data_wr,
    output reg  [31:0]  data
  );

  always@(posedge clock) begin // read
    if (mode == 4'b0101) begin 
      sdram0_read({6'b000000, bank}, row, col, data);
    end
  end

  always @(posedge clock) begin // write
    if(mode == 4'b0100) begin
      sdram0_write({6'b000000, bank}, row, col, {4'b0000, mask}, data_wr);
    end
  end

endmodule
