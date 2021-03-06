// IE309 - Projetos de DSP em FPGA 2013
// Autores: Daniel de Oliveira Tavares - RA107455
//          Jaime Junior Luque Quispe  - RA144411
// Data: 20/06/2013

`include "log2.v"

module cic_decim
#(
  parameter DATAIN_WIDTH = 16,
  parameter DATAOUT_WIDTH = DATAIN_WIDTH,
  parameter M = 2,
  parameter N = 5,
  parameter MAXRATE = 64,
  parameter bitgrowth = N*log2(M*MAXRATE)
)
(
  input  clk_i,
  input  rst_i,
  input  en_i,
  input  [DATAIN_WIDTH-1:0] data_i,
  output [DATAOUT_WIDTH-1:0] data_o,
  input  act_i,
  input  act_out_i,
  output val_o
);

  wire [DATAIN_WIDTH+bitgrowth-1:0] datain_extended;
  reg  [DATAIN_WIDTH+bitgrowth-1:0] integrator [0:N-1];
  reg  [DATAIN_WIDTH+bitgrowth-1:0] diffdelay [0:N-1][0:M-1];
  reg  [DATAIN_WIDTH+bitgrowth-1:0] pipe [0:N-1];
  reg  [DATAIN_WIDTH+bitgrowth-1:0] sampler;
  reg  val_reg0;
  
  integer i,j;

  assign datain_extended = {{(bitgrowth){data_i[DATAIN_WIDTH-1]}},data_i};

  // Integrator sections
  always @(posedge clk_i)
  if (rst_i)
    for (i=0; i<N; i=i+1)
      integrator[i] <= {{1'b0}};
  
  else if (en_i && act_i) begin
    integrator[0] <= integrator[0] + datain_extended;
    
    for (i=1; i<N; i=i+1)
      integrator[i] <= integrator[i] + integrator[i-1];
  end	

  // Comb sections
  always @(posedge clk_i) begin
    if (rst_i) begin
      sampler <= {{1'b0}};
      
      for (i=0; i<N; i=i+1) begin
        pipe[i] <= {{1'b0}};
        
        for (j=0; j<M; j=j+1)
          diffdelay[i][j] <= {{1'b0}};
      end
      
      val_reg0 <= 1'b0;
    end
    else if (en_i && act_out_i) begin
      sampler <= integrator[N-1];
      diffdelay[0][0] <= sampler;
      
      for (j=1; j<M; j=j+1)
        diffdelay[0][j] <= diffdelay[0][j-1];
      
      pipe[0] <= sampler - diffdelay[0][M-1];
      
      for (i=1; i<N; i=i+1) begin
        diffdelay[i][0] <= pipe[i-1];
      
        for (j=1; j<M; j=j+1)
          diffdelay[i][j] <= diffdelay[i][j-1];
      
        pipe[i] <= pipe[i-1] - diffdelay[i][M-1];
      end
    end
    
    val_reg0 <= act_out_i;
  end
  
  assign data_o = pipe[N-1][DATAIN_WIDTH+bitgrowth-1:DATAIN_WIDTH+bitgrowth-DATAOUT_WIDTH];
  assign val_o = val_reg0;

endmodule
