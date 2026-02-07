module axi4_delayer(
  input         clock,
  input         reset,

  output        in_arready,
  input         in_arvalid,
  input  [3:0]  in_arid,
  input  [31:0] in_araddr,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [3:0]  in_rid,
  output [31:0] in_rdata,
  output [1:0]  in_rresp,
  output        in_rlast,
  output        in_awready,
  input         in_awvalid,
  input  [3:0]  in_awid,
  input  [31:0] in_awaddr,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
                in_bready,
  output        in_bvalid,
  output [3:0]  in_bid,
  output [1:0]  in_bresp,

  input         out_arready,
  output        out_arvalid,
  output [3:0]  out_arid,
  output [31:0] out_araddr,
  output [7:0]  out_arlen,
  output [2:0]  out_arsize,
  output [1:0]  out_arburst,
  output        out_rready,
  input         out_rvalid,
  input  [3:0]  out_rid,
  input  [31:0] out_rdata,
  input  [1:0]  out_rresp,
  input         out_rlast,
  input         out_awready,
  output        out_awvalid,
  output [3:0]  out_awid,
  output [31:0] out_awaddr,
  output [7:0]  out_awlen,
  output [2:0]  out_awsize,
  output [1:0]  out_awburst,
  input         out_wready,
  output        out_wvalid,
  output [31:0] out_wdata,
  output [3:0]  out_wstrb,
  output        out_wlast,
                out_bready,
  input         out_bvalid,
  input  [3:0]  out_bid,
  input  [1:0]  out_bresp
);

  assign in_arready = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid = in_arid;
  assign out_araddr = in_araddr;
  assign out_arlen = in_arlen;
  assign out_arsize = in_arsize;
  assign out_arburst = in_arburst;
  // assign out_rready = in_rready;
  // assign in_rvalid = out_rvalid;
  // assign in_rid = out_rid;
  // assign in_rdata = out_rdata;
  assign in_rresp = out_rresp;
  // assign in_rlast = out_rlast;
  assign in_awready = out_awready;
  assign out_awvalid = in_awvalid;
  assign out_awid = in_awid;
  assign out_awaddr = in_awaddr;
  assign out_awlen = in_awlen;
  assign out_awsize = in_awsize;
  assign out_awburst = in_awburst;
  assign in_wready = out_wready;
  assign out_wvalid = in_wvalid;
  assign out_wdata = in_wdata;
  assign out_wstrb = in_wstrb;
  assign out_wlast = in_wlast;
  // assign out_bready = in_bready;
  // assign in_bvalid = out_bvalid;
  // assign in_bid = out_bid;
  // assign in_bresp = out_bresp;

  // read
  reg   [31:0]    total_read;
  reg   [31:0]    counter_read;

  // write
  reg   [31:0]    total_wr;
  reg   [31:0]    counter_wr;

  localparam  R   = 8;

  localparam  IDLE_READ     = 0;
  // localparam  WAIT_RDATA    = 1;
  localparam  BACK_READ     = 1;

  localparam  IDLE_WR       = 0;
  localparam  BACK_WR       = 1;

  reg   [31:0]  latency_read  [7:0];
  reg   [31:0]  fifo_rdata    [7:0];
  reg   [3:0]   fifo_rid      [7:0];
  reg   [0:0]   fifo_rlast    [7:0];
  reg   [7:0]   read_len;
  reg   [2:0]   wpt_r;
  reg   [2:0]   rpt_r;
  reg   [1:0]   current_read;
  reg   [1:0]   next_read;
  reg   [1:0]   state_wr;

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      current_read  <= IDLE_READ;
    end
    else begin
      current_read  <= next_read;
    end
  end

  always @(*) begin // rid = 0

    case(current_read)
      
      IDLE_READ: begin // address 
        if(in_arvalid == 1'b1) begin
          next_read    = BACK_READ;
        end
        else begin
          next_read    = IDLE_READ;
        end
      end

      BACK_READ: begin
        if(in_rlast) begin
          next_read    = IDLE_READ;
        end
        else begin
          next_read    = BACK_READ;
        end
      end

      default: begin
        next_read   = IDLE_READ;
      end
    endcase
  end

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      read_len   <= 8'h00;
    end
    else begin
      if(in_arvalid == 1'b1 && in_arready == 1'b1) begin
        read_len   <= in_arlen;
      end
    end
  end

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      wpt_r   <= 3'h0;
    end
    else begin
      if(out_rvalid && out_rready) begin
        wpt_r               <= wpt_r + 1;
        fifo_rdata[wpt_r]   <= out_rdata;
        latency_read[wpt_r] <= total_read;
        fifo_rid[wpt_r]     <= out_rid;
        fifo_rlast[wpt_r]   <= out_rlast;
      end
    end
  end

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      rpt_r   <= 3'h0;
    end
    else begin
      if((latency_read[rpt_r] == counter_read) && (counter_read != 0)) begin
        rpt_r <= rpt_r + 1;
      end
    end
  end

  always @(posedge clock) begin
    if(rpt_r == wpt_r + 1) begin
      $display("%h, %h", rpt_r, wpt_r);
      assert(0);
    end
    // assert(rpt_r == wpt_r + 1);
  end

  assign  in_rdata    = fifo_rdata[rpt_r];
  assign  in_rvalid   = (latency_read[rpt_r] == counter_read) && (counter_read != 0);
  assign  in_rid      = fifo_rid[rpt_r];
  assign  in_rlast    = ((latency_read[rpt_r] == counter_read) && (counter_read != 0)) ? fifo_rlast[rpt_r] : 1'b0;
  assign  out_rready  = (current_read == BACK_READ);

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      total_read    <= 32'h0;
      counter_read  <= 32'h0;
    end
    else begin
      if(current_read == BACK_READ) begin
        total_read     <= total_read + R;
        counter_read   <= counter_read + 1;
      end
      else if (current_read == IDLE_READ) begin
        total_read   <= 32'h0;
        counter_read <= 32'h0;
      end
    end
  end

  reg   [31:0]  latency_wr;
  reg   [1:0]   fifo_bresp;
  reg   [3:0]   fifo_bid;
  // reg   [0:0]   fifo_wlast;

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      state_wr    <= IDLE_WR;
    end 
    else begin
      case(state_wr)
        IDLE_WR: begin
          if(in_awvalid) begin
            state_wr    <= BACK_WR;
          end
          else begin
            state_wr    <= IDLE_WR;
          end 
        end

        BACK_WR: begin
          if(in_bvalid) begin
            state_wr    <= IDLE_WR;
          end
          else begin
            state_wr    <= BACK_WR;
          end
        end

        default: begin
          state_wr    <= IDLE_WR;
        end

      endcase
    end
  end

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      total_wr    <= 32'h0;
      counter_wr  <= 32'h0;
    end
    else begin
      if(state_wr == BACK_WR) begin
        total_wr     <= total_wr + R;
        counter_wr   <= counter_wr + 1;
      end
      else if (state_wr == IDLE_WR) begin
        total_wr   <= 32'h0;
        counter_wr <= 32'h0;
      end
    end
  end

  always @(posedge clock or posedge reset) begin
    if(out_bvalid && out_bready) begin
      fifo_bresp   <= out_bresp;
      latency_wr   <= total_wr;
      fifo_bid     <= out_bid;
      // fifo_wlast   <= out_wlast;
    end
  end

  assign  in_bresp    = fifo_bresp;
  assign  in_bvalid   = (latency_wr == counter_wr) && (counter_wr != 0);
  assign  in_bid      = fifo_bid;
  // assign  in_wlast    = ((latency_wr == counter_wr) && (counter_wr != 0)) ? fifo_wlast : 1'b0;
  assign  out_bready  = (state_wr == BACK_WR);


endmodule
