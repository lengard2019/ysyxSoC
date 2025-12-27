`timescale 1ns / 10ps

module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);

  // assign dio = 4'bz;
  wire reset = ce_n;

  typedef enum [2:0] { cmd_t, addr_t, delay_t, rdata_t, wdata_t, switch_t, err_t } state_t;
  reg [2:0]  state;
  reg [7:0]  counter;
  reg [7:0]  cmd;
  reg [23:0] addr;
  reg [31:0] data;
  reg [7:0]  data_wr;
  reg [23:0] waddr;

  wire [31:0] addr_w = {8'h00, waddr};

  wire ren = (state == addr_t) && (counter == 8'd5) && (cmd == 8'hEB);
  wire wen = (state == wdata_t) && ((counter == 8'd7) || (counter == 8'd1) || (counter == 8'd3) || (counter == 8'd5));
  wire [31:0] rdata;
  wire [31:0] raddr = (state == addr_t) ? {8'b0, addr[19:0], dio[3:0]} : {8'b0, addr};
  wire [7:0] wdata = {dio[3:0], data_wr[7:4] };

  reg [2:0] op_state;
  reg mode = 1'b0;

  always @(posedge sck) begin
    if(state == switch_t) begin
      mode <= 1'b1;
    end
  end

  always @(*) begin
    if(cmd == 8'heb) begin
      op_state = delay_t;
    end
    else if(cmd == 8'h38) begin
      op_state = wdata_t;
    end
    else if(cmd == 8'haa) begin
      op_state = switch_t;
    end
    else begin
      op_state = err_t;
    end
  end

  reg [7:0] cmd_cnt;
  always @(*) begin
    if(mode == 1'b1) begin
      cmd_cnt = 8'd1;
    end
    else begin
      cmd_cnt = 8'd7;
    end
  end

  always@(posedge sck or posedge reset) begin
    if (reset) state <= cmd_t;
    else begin
      case (state)
        cmd_t:  state <= (counter == cmd_cnt) ? addr_t : state;
        addr_t: state <= (counter == 8'd5) ? op_state : state;
        delay_t: state <= (counter == 8'd5) ? rdata_t : state;
        rdata_t: state <= state;
        wdata_t: state <= state;
        switch_t: state <= state;

        default: begin
          state <= state;
          $fwrite(32'h80000002, "Assertion failed: Unsupported command `%xh`, only support `EBh` read command\n", cmd);
          $fatal;
        end
      endcase
    end
  end


  always@(posedge sck or posedge reset) begin
    if (reset) counter <= 8'd0;
    else begin
      case (state)
        cmd_t:   counter <= (counter < cmd_cnt) ? counter + 8'd1 : 8'd0;
        addr_t:  counter <= (counter < 8'd5) ? counter + 8'd1 : 8'd0;
        delay_t:  counter <= (counter < 8'd5) ? counter + 8'd1 : 8'd0;
        default: counter <= counter + 8'd1;
      endcase
    end
  end

  always@(posedge sck or posedge reset) begin
    if (reset)               cmd <= 8'd0;
    else if (state == cmd_t && mode == 1'b0) cmd <= { cmd[6:0], dio[0] };
    else if (state == cmd_t && mode == 1'b1) cmd <= { cmd[3:0], dio[3:0] };
  end

  always@(posedge sck or posedge reset) begin
    if (reset) begin
      addr <= 24'd0;
      waddr <= 24'd0;
    end
    else if (state == addr_t && counter <= 8'd5) begin
      addr <= { addr[19:0], dio[3:0] };
      waddr <= { waddr[19:0], dio[3:0] };
    end
    else if (state == wdata_t && (counter == 8'd2)) begin
      waddr <= waddr + 1'b1;
    end
    else if (state == wdata_t && (counter == 8'd4)) begin
      waddr <= waddr + 1'b1;
    end
    else if (state == wdata_t && (counter == 8'd6)) begin
      waddr <= waddr + 1'b1;
    end
  end

  always@(posedge sck or posedge reset) begin
    if (reset) data_wr <= 8'd0;
    else if (state == wdata_t && counter <= 8'd7)
      data_wr <= { dio[3:0], data_wr[7:4] };
  end

  wire [31:0] data_bswap = rdata;
  // wire [31:0] data_bswap = {rdata[7:0], rdata[15:8], rdata[23:16], rdata[31:24]};
  always@(posedge sck or posedge reset) begin
    if (reset) data <= 32'd0;
    else if (state == rdata_t) begin
      data <= { 4'b0, {counter == 8'd0 ? data_bswap : data}[31:4] };
    end
  end


  assign dio = (state == rdata_t) ? ({(counter == 8'd0) ? data_bswap : data}[3:0]) : 4'bzzzz;
  // assign  dio = 4'bzzzz;

  psram_cmd psram_cmd_i(
    .clock(sck),
    .valid(ren),
    .cmd(cmd),
    .wen(wen),
    .data_wr(wdata),
    .waddr(addr_w),
    .addr(raddr),
    .data(rdata)
  );

endmodule


import "DPI-C" function void psram_read(input int addr, output int data);
import "DPI-C" function void psram_write(input int addr, input byte data);

  module psram_cmd(
    input             clock,
    input             valid,
    input             wen,
    input       [7:0] cmd,
    input      [7:0]  data_wr,
    input      [31:0] addr,
    input      [31:0] waddr,
    output reg [31:0] data
  );
  always@(posedge clock) begin
    if (valid)
      if (cmd == 8'hEB) psram_read(addr, data);
      else begin
        $fwrite(32'h80000002, "Assertion failed: Unsupport command `%xh`, only support `03h` read command\n", cmd);
        $fatal;
      end
  end

  always @(posedge clock) begin
    if (wen)
      if (cmd == 8'h38) psram_write(waddr, data_wr);
      else begin
        $fwrite(32'h80000002, "Assertion failed: Unsupport command `%xh`, only support `03h` read command\n", cmd);
        $fatal;
      end
  end

endmodule

