module psram_top_apb (
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

  output qspi_sck,
  output qspi_ce_n,
  inout  [3:0] qspi_dio
);

  wire [3:0] din, dout, douten;

  wire [3:0]  dout_u0;

  wire qspi_sck_u0;

  wire qspi_ce_n_u0;
  wire ack;

  EF_PSRAM_CTRL_wb u0 (
    .clk_i(clock),
    .rst_i(reset),
    .adr_i(in_paddr),
    .dat_i(in_pwdata),
    .dat_o(in_prdata),
    .sel_i(in_pstrb),
    .cyc_i(in_psel),
    .stb_i(in_psel),
    .ack_o(ack),
    .we_i(in_pwrite),
  
    .sck(qspi_sck_u0),
    .ce_n(qspi_ce_n_u0),
    .din(din),
    .dout(dout_u0),
    .douten(douten)
  );

  // output declaration of module PSRAM_SWITCH
    reg ms_sck;
    reg ms_ce_n;
    wire [3:0] ms_dout;
    wire ms_douten;
    
    PSRAM_SWITCH u_PSRAM_SWITCH(
        .clk    	(clock      ),
        .rst_n  	(~reset     ),
        .sck    	(ms_sck  ),
        .ce_n   	(ms_ce_n    ),
        .dout   	(ms_dout    ),
        .douten 	(ms_douten  )
    );

  assign  qspi_ce_n = qspi_ce_n_u0 & ms_ce_n;
  assign  qspi_sck = (ms_ce_n == 1'b1) ? qspi_sck_u0 : ms_sck;
    
  
  assign in_pready = ack && in_psel;
  assign in_pslverr = 1'b0;
  assign qspi_dio[0] = (ms_ce_n == 1'b0) ? ms_dout [0] : (douten[0] ? dout_u0[0] : 1'bz);
  assign qspi_dio[1] = (ms_ce_n == 1'b0) ? ms_dout [1] : (douten[1] ? dout_u0[1] : 1'bz);
  assign qspi_dio[2] = (ms_ce_n == 1'b0) ? ms_dout [2] : (douten[2] ? dout_u0[2] : 1'bz);
  assign qspi_dio[3] = (ms_ce_n == 1'b0) ? ms_dout [3] : (douten[3] ? dout_u0[3] : 1'bz);
  assign din = qspi_dio;

endmodule
