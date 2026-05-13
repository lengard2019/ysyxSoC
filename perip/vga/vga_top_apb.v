module vga_top_apb(
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

  output [7:0]  vga_r,
  output [7:0]  vga_g,
  output [7:0]  vga_b,
  output        vga_hsync,
  output        vga_vsync,
  output        vga_valid
);

  assign  in_pslverr    = 0;
  // assign  in_prdata     = {31'h0, sync};

  // reg     sync;

  reg [23:0] vga_mem [524287:0];
  wire  draw_finish;

  assign  in_pready   = (in_penable == 1'b1);

  always @(posedge clock) begin
    if(in_pwrite == 1'b1 && in_pready == 1'b1) begin
      vga_mem[in_paddr[20:2]]     <= in_pwdata[23:0];
      // $display("in_pwdata = %h, in_addr = %h", in_pwdata, in_paddr[20:2]);
    end
  end

  // always @(posedge clock) begin
  //   if(reset == 1'b1) begin
  //     sync    <= 1'b0;
  //   end
  //   else begin
  //     if(in_pwrite == 1'b1 && in_pready == 1'b1 && in_paddr[19:16] == 4'b1000) begin
  //       sync    <= 1'b1;
  //     end
  //     else begin
  //       if(draw_finish) begin
  //         sync  <= 1'b0;
  //       end
  //     end
  //   end
  // end

  // output declaration of module vga_ctrl
  // wire  [9:0] h_addr;
  // wire  [9:0] v_addr;
  reg   [18:0]  mem_addr;

  // assign  mem_addr  = {8'h00, h_addr} + {8'h00, v_addr};

  always @(posedge clock) begin
    if(reset == 1'b1) begin
      mem_addr    <= 0;
    end
    else begin
      if(vga_valid) begin
        mem_addr  <= mem_addr + 1;
        // $display("mem_addr = %8h", mem_addr);
      end
      else begin
        if(draw_finish) begin
          mem_addr  <= 0;
        end
      end
    end
  end

  wire  [23:0]  vga_data;

  assign vga_data = vga_mem[mem_addr];

  vga_ctrl #(
    .h_frontporch 	(96   ),
    .h_active     	(144  ),
    .h_backporch  	(784  ),
    .h_total      	(800  ),
    .v_frontporch 	(2    ),
    .v_active     	(35   ),
    .v_backporch  	(515  ),
    .v_total      	(525  ))
  u_vga_ctrl(
    .pclk     	  (clock     ),
    .reset    	  (reset     ),
    .vga_data 	  (vga_data  ),
    // .draw_start   (sync       ),
    .draw_finish  (draw_finish),
    .h_addr   	  (    ),
    .v_addr   	  (    ),
    .hsync    	  (vga_hsync ),
    .vsync    	  (vga_vsync ),
    .valid    	  (vga_valid ),
    .vga_r    	  (vga_r     ),
    .vga_g    	  (vga_g     ),
    .vga_b    	  (vga_b     )
  );  

endmodule

module vga_ctrl (
    input pclk,
    input reset,
    input [23:0] vga_data,
    // input   draw_start,
    output  draw_finish,
    output [9:0] h_addr,
    output [9:0] v_addr,
    output hsync,
    output vsync,
    output valid,
    output [7:0] vga_r,
    output [7:0] vga_g,
    output [7:0] vga_b
);

parameter h_frontporch = 96;
parameter h_active = 144;
parameter h_backporch = 784;
parameter h_total = 800;

parameter v_frontporch = 2;
parameter v_active = 35;
parameter v_backporch = 515;
parameter v_total = 525;

reg [9:0] x_cnt;
reg [9:0] y_cnt;
wire h_valid;
wire v_valid;

always @(posedge pclk) begin
    if(reset == 1'b1) begin
        x_cnt <= 1;
        y_cnt <= 1;
    end
    else begin
      // if(draw_start) begin
        if(x_cnt == h_total)begin
            x_cnt <= 1;
            if(y_cnt == v_total) y_cnt <= 1;
            else y_cnt <= y_cnt + 1;
        end
        else x_cnt <= x_cnt + 1;
      // end
    end
end

assign  draw_finish = (y_cnt == v_total);

  // always @(posedge pclk) begin
  //   if(y_cnt == v_total) begin
  //     $display("y_cnt == v_total");
  //   end
  // end

//生成同步信号    
assign hsync = (x_cnt > h_frontporch);
assign vsync = (y_cnt > v_frontporch);
//生成消隐信号
assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
assign valid = h_valid & v_valid;
//计算当前有效像素坐标
assign h_addr = h_valid ? (x_cnt - 10'd145) : 10'd0;
assign v_addr = v_valid ? (y_cnt - 10'd36) : 10'd0;
//设置输出的颜色值
assign {vga_r, vga_g, vga_b} = vga_data;
endmodule
