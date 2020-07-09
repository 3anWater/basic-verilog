//------------------------------------------------------------------------------
// delay.v
// Konstantin Pavlov, pavlovconst@gmail.com
//------------------------------------------------------------------------------

// INFO -------------------------------------------------------------------------
// Static Delay for arbitrary signal, v2
// Another equivalent names for this module:
//          conveyor.sv
//          synchronizer.sv
//
// Tip for Xilinx-based implementations: Leave nrst=1'b1 and ena=1'b1 on
// purpose of inferring Xilinx`s SRL16E/SRL32E primitives
//
//
// CAUTION: delay module is widely used for synchronizing signals across clock
//   domains. When synchronizing, please exclude input data paths from timing
//   analisys manually by writing appropriate set_false_path SDC constraint
//
// Version 2 introduces "ALTERA_BLOCK_RAM" option to implement delays using
//   block RAM. Quartus can make shifters on block RAM aautomatically
//   using 'altshift_taps' internal module when "Auto Shift Register
//   Replacement" option is ON


/* --- INSTANTIATION TEMPLATE BEGIN ---

delay #(
    .LENGTH( 2 ),
    .WIDTH( 1 ),
    .TYPE( "CELLS" )
) S1 (
    .clk( clk ),
    .nrst( 1'b1 ),
    .ena( 1'b1 ),

    .in(  ),
    .out(  )
);

--- INSTANTIATION TEMPLATE END ---*/


module delay #( parameter
  LENGTH = 2,          // delay/synchronizer chain length
  WIDTH = 1,           // signal width
  TYPE = "CELLS",      // "ALTERA_BLOCK_RAM" infers block ram fifo
                       //   all other values infer registers

  CNTR_W = $clog2(LENGTH)
)(
  input clk,
  input nrst,
  input ena,

  input [WIDTH-1:0] in,
  output [WIDTH-1:0] out
);

generate

  if ( LENGTH == 0 ) begin

    assign out[WIDTH-1:0] = in[WIDTH-1:0];

  end else if( LENGTH == 1 ) begin

    logic [WIDTH-1:0] data = '0;
    always_ff @(posedge clk) begin
      if( ~nrst ) begin
        data[WIDTH-1:0] <= '0;
      end else if( ena ) begin
        data[WIDTH-1:0] <= in[WIDTH-1:0];
      end
    end
    assign out[WIDTH-1:0] = data[WIDTH-1:0];

  end else begin
    if( TYPE=="ALTERA_BLOCK_RAM" && LENGTH>=4 ) begin

      logic [CNTR_W-1:0] delay_cntr = '0;

      logic fifo_output_ena;
      assign fifo_output_ena = (delay_cntr[CNTR_W-1:0] == LENGTH);

      always_ff @(posedge clk) begin
        if( ~nrst ) begin
          delay_cntr[CNTR_W-1:0] <= '0;
        end else begin
          if( ena && ~fifo_output_ena) begin
            delay_cntr[CNTR_W-1:0] <= delay_cntr[CNTR_W-1:0] + 1'b1;
          end
        end
      end

      logic [WIDTH-1:0] fifo_out;
      scfifo #(
        .LPM_WIDTH( WIDTH ),
        .LPM_NUMWORDS( LENGTH ),   // must be at least 4
        .LPM_WIDTHU( CNTR_W ),
        .LPM_SHOWAHEAD( "ON" ),
        .UNDERFLOW_CHECKING( "ON" ),
        .OVERFLOW_CHECKING( "ON" ),
        .ALMOST_FULL_VALUE( 0 ),
        .ALMOST_EMPTY_VALUE( 0 ),
        .ENABLE_ECC( "FALSE" ),
        .ALLOW_RWCYCLE_WHEN_FULL( "ON" ),
        .USE_EAB( "ON" ),
        .MAXIMIZE_SPEED( 5 ),
        .DEVICE_FAMILY( "Cyclone V" )
      ) internal_fifo (
        .clock( clk ),
        .aclr( 1'b0 ),
        .sclr( ~nrst ),

        .data( in[WIDTH-1:0] ),
        .wrreq( ena ),
        .rdreq( ena && fifo_output_ena ),

        .q( fifo_out[WIDTH-1:0] ),
        .empty(  ),
        .full(  ),
        .almost_full(  ),
        .almost_empty(  ),
        .usedw(  ),
        .eccstatus(  )
      );

      assign out[WIDTH-1:0] = (fifo_output_ena)?(fifo_out[WIDTH-1:0]):('0);

    end else begin

      logic [LENGTH:1][WIDTH-1:0] data = '0;
      always_ff @(posedge clk) begin
        integer i;
        if( ~nrst ) begin
          data <= '0;
        end else if( ena ) begin
          for(i=LENGTH-1; i>0; i--) begin
            data[i+1][WIDTH-1:0] <= data[i][WIDTH-1:0];
          end
          data[1][WIDTH-1:0] <= in[WIDTH-1:0];
        end
      end
      assign out[WIDTH-1:0] = data[LENGTH][WIDTH-1:0];

    end // if TYPE
  end // if LENGTH

endgenerate

endmodule
