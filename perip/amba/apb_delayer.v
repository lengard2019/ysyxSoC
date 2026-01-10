module apb_delayer(
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

  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

  assign out_paddr   = in_paddr;
  // assign out_psel    = in_psel;
  // assign out_penable = in_penable;
  assign out_pprot   = in_pprot;
  // assign out_pwrite  = in_pwrite;
  assign out_pwdata  = in_pwdata;
  assign out_pstrb   = in_pstrb;
  // assign in_pready   = out_pready;
  // assign in_prdata   = out_prdata;
  // assign in_pslverr  = out_pslverr;

  localparam  R   = 128; // 8*16

  reg   [31:0]    total;
  reg   [31:0]    counter;

  reg   [31:0]    prdata;
  reg             pslverr;

  localparam  IDLE      = 0;
  localparam  PABLE     = 1;
  localparam  WAIT_DATA = 2;
  localparam  DIV       = 3;
  localparam  SENT_DATA = 4;

  reg [3:0] current_state;
  reg [3:0] next_state;

  always @(posedge clock or posedge reset) begin
    if(reset == 1'b1) begin
      current_state   <= IDLE;
    end
    else begin
      current_state   <= next_state;
    end
  end

  always @(*) begin
    case(current_state)
      IDLE: begin
        if(in_psel == 1'b1) begin
          next_state = PABLE;
        end
        else begin
          next_state = IDLE;
        end
      end

      PABLE: begin
        next_state = WAIT_DATA;
      end

      WAIT_DATA: begin
        if(out_pready == 1'b1) begin
          next_state = DIV;
        end
        else begin
          next_state = WAIT_DATA;
        end
      end

      DIV: begin
        next_state = SENT_DATA;
      end

      SENT_DATA: begin
        if(counter == total) begin
          next_state = IDLE;
        end
        else begin
          next_state = SENT_DATA;
        end
      end

      default: next_state = IDLE;
    endcase
  end

  always @(posedge clock or posedge reset) begin
    if(reset == 1'b1) begin
      prdata    <= 32'h0000;
      pslverr   <= 1'b0;
    end
    else begin
      if(in_psel == 1'b1 && out_pready == 1'b1) begin
        prdata    <= out_prdata;
        pslverr   <= out_pslverr;
      end
    end
  end

  always @(posedge clock or posedge reset) begin
    if(reset == 1'b1) begin
      counter   <= 32'h0001;
      total     <= 32'h0068;
    end
    else begin
      case(current_state)
        IDLE: begin
          counter   <= 32'h0001;
          total     <= 32'h0068;
        end 
        PABLE: begin
          total     <= total + R;
          counter   <= counter + 1;
        end
        WAIT_DATA: begin
          total     <= total + R;
          counter   <= counter + 1;
        end
        DIV: begin
          total     <= total >> 4;
          counter   <= counter + 1;
        end       
        SENT_DATA: begin
          counter   <= counter + 1;
          total     <= total;
        end 
        default: begin
          counter   <= 32'h0001;
          total     <= 32'h0068;
        end   
      endcase
    end
  end

  assign  out_psel    = (current_state == WAIT_DATA || current_state == PABLE);
  assign  out_penable = (current_state == WAIT_DATA);
  assign  out_pwrite  = (in_pwrite && (current_state == WAIT_DATA || current_state == PABLE));
  assign  in_pready = (current_state == SENT_DATA && counter == total) ? 1'b1 : 1'b0;
  assign  in_prdata = prdata;
  assign  in_pslverr = pslverr;

endmodule
