/*----------------------------------------------------------------------------------------------------
 | engineer:        Artyom Shimko (soikadigital@gmail.com)
 |
 | created:         14.01.21  
 |
 | device:          cross-platform
 |
 | description:     A loaded DSP48 counter.
 |
 | dependencies:    non
 |
 | doc:             non
 |
 | rtl:             load_counter_dr.v
 |
 | tb:              load_counter_dr_tb.v
 |
 | version:         1.0
 |
 | revisions:       14.01.21    - There was createde the base vertion file;   
 |   
 */

 /* 
  load_counter_dr #
  (
    .COUNTER_WIDTH ()
  )
  load_counter_dr_inst_0
  (
    .clk_i         (),
    .s_rst_n_i     (),
    .enable_i      (),
    .direction_i   (), // 1 == increment; 0 == decrement;
    .load_enable_i (),
    .load_data_i   (), // width: COUNTER_WIDTH      
    .increment_i   (), // width: COUNTER_WIDTH
    .value_o       ()  // width: COUNTER_WIDTH
  );
 */

`timescale 1ns / 1ps

(* use_dsp48 = "yes" *) 
module load_counter_dr #
(
  parameter integer COUNTER_WIDTH = 8
)
(
  input  wire                         clk_i,
  input  wire                         s_rst_n_i,
  input  wire                         enable_i,
  input  wire                         direction_i,  // 1 == +; 0 ==-;
  input  wire                         load_enable_i,
  input  wire [COUNTER_WIDTH - 1 : 0] load_data_i,      
  input  wire [COUNTER_WIDTH - 1 : 0] increment_i,
  
  output wire [COUNTER_WIDTH - 1 : 0] value_o
);
  reg [COUNTER_WIDTH - 1 : 0] counter_value; // a distributed memory

  assign value_o = counter_value;

  always @ (posedge clk_i)
    begin
      if (1'h0 == s_rst_n_i)
        begin
          counter_value   <= {COUNTER_WIDTH{1'h0}};
        end
      else if (1'h1 == load_enable_i)
        begin 
          counter_value <= load_data_i;
        end
      else if (1'h1 == enable_i)
        begin 
          if (1'h1 == direction_i)
            begin
              counter_value <= counter_value + increment_i;
            end
          else
            begin
              counter_value <= counter_value - increment_i; // if < 0
            end
        end
    end
endmodule