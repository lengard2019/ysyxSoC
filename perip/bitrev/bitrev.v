module bitrev (
  input  sck,
  input  ss,
  input  mosi,
  output miso
);

  reg [7:0]   spi_reg;

  always @(negedge sck or ss) begin

  end

  assign miso = 1'b1;
endmodule
