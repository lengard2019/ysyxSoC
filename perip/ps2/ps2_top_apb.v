module ps2_top_apb(
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

  input         ps2_clk,
  input         ps2_data
);

  localparam IDLE     = 0;
  localparam READ     = 1;

  reg     [31:0] fifo  [7:0];

  reg     [3:0]       current_state;
  reg     [3:0]       next_state;

  reg     [2:0]       rpt, wpt;

  wire    [7:0]       data;
  wire                ready_sampling;
  wire                overflow;

  reg                 key_up;

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
                 next_state   = READ; 
              end
              else begin
                  next_state   = IDLE;
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
    if(reset == 1'b1) begin
      key_up    <= 1'b1;
    end
    else begin
      if(ready_sampling == 1'b1) begin
        if(data == 8'hf0) begin
          key_up    <= 1'b0;
        end
        else begin
          key_up    <= 1'b1;
        end
      end
    end
  end

  always @(posedge clock or posedge reset) begin
    if(reset == 1'b1) begin
      wpt   <= 3'h0;
    end
    else begin
      if(ready_sampling == 1'b1) begin
        if(data != 8'hf0) begin
          fifo[wpt]   <= {16'h0000, key_up, 7'h00, data};
          wpt         <= wpt + 1'b1;
          // $display("data = %h", data);
        end
      end
    end 
  end

  always @(posedge clock or posedge reset) begin
    if(reset == 1'b1) begin
      rpt   <= 3'h0;
    end
    else begin
      if(in_pready == 1'b1) begin
        if(wpt == rpt) begin
          rpt <= rpt;
        end
        else begin
          rpt <= rpt + 1'b1;
          // $display("rpt = %d", rpt);
        end
      end
    end
  end

  ps2_keyboard u_ps2_keyboard(
    .clk      	      (clock     ),
    .clrn   	        (~reset    ),
    .ps2_clk  	      (ps2_clk   ),
    .ps2_data 	      (ps2_data  ),
    .data             (data),
    .ready_sampling   (ready_sampling),
    .overflow         (overflow)
  );

  assign in_pready = (current_state == READ);
  assign in_pslverr = 1'b0;
  assign in_prdata = (wpt == rpt) ? 32'h00000000 : fifo[rpt];
  
endmodule


module ps2_keyboard(clk,ps2_clk,ps2_data,data,clrn,ready_sampling,
                    // ready,nextdata_n,
                    overflow);
    input clk,ps2_clk,ps2_data;
    // input nextdata_n;
    input clrn;
    output [7:0] data;
    reg [3:0] count;
    output ready_sampling;
    // output start;
    // output reg ready;
    output reg overflow;     // fifo overflow
    // internal signal, for test
    reg [9:0] buffer;        // ps2_data bits
    reg [7:0] fifo[7:0];     // data fifo
    reg [2:0] w_ptr,r_ptr;   // fifo write and read pointers
    reg [2:0] ps2_clk_sync;

    reg ready;

    // detect pose edge of ps2_clk
    reg [2:0] ready_sync;
    wire nextdata_n;

    reg [7:0] cnt;

    always @(posedge clk) begin
        ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
    end

    wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

    always @(posedge clk) begin
        if (clrn == 0) begin // reset
            count <= 0; w_ptr <= 0; r_ptr <= 3'b0; overflow <= 0; ready<= 0;
            cnt <= 0; ready_sync <= 0;
        end
        else begin
            if ( ready ) begin // read to output next data
                if(nextdata_n == 1'b0) //read next data
                begin
                    r_ptr <= r_ptr + 3'b1;
                    if(w_ptr==(r_ptr+3'b001)) //empty
                        ready <= 1'b0;
                end
            end
            if (sampling) begin
              if (count == 4'd10) begin
                if ((buffer[0] == 0) &&  // start bit
                    (ps2_data)       &&  // stop bit
                    (^buffer[9:1])) begin      // odd  parity
                    fifo[w_ptr] <= buffer[8:1];  // kbd scan code
                    w_ptr <= w_ptr+3'b1;
                    ready <= 1'b1;
                    overflow <= overflow | (r_ptr == (w_ptr + 3'b1));
                end
                count <= 0;     // for next
              end else begin
                buffer[count] <= ps2_data;  // store ps2_data
                count <= count + 3'b1;
              end
            end
        end
    end
    // assign data = (count == 0'h00) ? 0'h00 : fifo[r_ptr]; //always set output data
    assign data = fifo[r_ptr];
    //自动复位
    always @(posedge clk) begin
        ready_sync <=  {ready_sync[1:0], ready};
    end

    assign ready_sampling = ready_sync[0] & ~ready_sync[1];

    always @(posedge clk) begin
        if(ready_sampling) begin
            cnt <= 0;
        end
        else begin
            if(cnt < 8'h1e) begin
                cnt <= cnt + 1'b1;
            end
        end
    end

    assign nextdata_n = (cnt > 8'h14)&&(cnt < 8'h1e) ? 0 : 1; 

endmodule
