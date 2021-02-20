`timescale 1ns / 1ps

module axis_data_generator #
(
    parameter integer                       AXIS_DATA_WIDTH = 32,
    parameter [(AXIS_DATA_WIDTH / 8) - 1:0] AXIS_TKEEP      = 4'hf,
    parameter                               INIT_FILE       = "",
    parameter integer                       BURST_SIZE      = 1024
)
(
    input  wire                                clk_i,
    input  wire                                s_rst_n_i,
    input  wire                                enable_i,                    

    output wire  [AXIS_DATA_WIDTH - 1 : 0]     m_axis_tdata_o,
    output wire  [(AXIS_DATA_WIDTH / 8) - 1:0] m_axis_tkeep_o,
    output wire                                m_axis_tvalid_o,
    output wire                                m_axis_tlast_o,
    input  wire                                m_axis_tready_i
);

    wire                           counter_terminate;
    wire                           counter_enable;
    wire [AXIS_DATA_WIDTH - 1 : 0] data;
    wire [AXIS_DATA_WIDTH - 1 : 0] counter_value;
    
    COUNTER_TC_MACRO #
    (
        .COUNT_BY      (48'h1              ),
        .DEVICE        ("7SERIES"         ), 
        .DIRECTION     ("UP"              ),
        .RESET_UPON_TC ("TRUE"            ),
        .TC_VALUE      (BURST_SIZE        ),
        .WIDTH_DATA    (AXIS_DATA_WIDTH   )
    ) 
    tc_counter_inst_0 
    (
        .Q             (counter_value    ),
        .TC            (counter_terminate),
        .CLK           (clk_i            ),
        .CE            (counter_enable   ),
        .RST           (!s_rst_n_i       )
    );
    
    generate
        if ("" != INIT_FILE) begin : init_from_file
            BRAM_SINGLE_MACRO #
            (
              .BRAM_SIZE   ("36Kb"                 ), 
              .DEVICE      ("7SERIES"              ), 
              .DO_REG      (0                      ), 
              .INIT        ({AXIS_DATA_WIDTH{1'h0}}),
              .INIT_FILE   (INIT_FILE              ),
              .WRITE_WIDTH (AXIS_DATA_WIDTH        ),
              .READ_WIDTH  (AXIS_DATA_WIDTH        ),
              .SRVAL       ({AXIS_DATA_WIDTH{1'h0}}),
              .WRITE_MODE  ("NO_CHANGE"            )
            ) 
            single_bram_inst_0
            (
              .DO    (data                           ),
              .ADDR  (counter_value                  ), //width?
              .CLK   (clk_i                          ),
              .DI    ({AXIS_DATA_WIDTH{1'h0}}        ),
              .EN    (enable_i                       ),
              .REGCE (1'h0                           ),
              .RST   (!s_rst_n_i                     ),
              .WE    ({$clog2(AXIS_DATA_WIDTH){1'h0}})
            );
        end
        else begin : data_from_counter_buf
            IBUF #
            (
              .IBUF_LOW_PWR ("TRUE"   ),  
              .IOSTANDARD   ("DEFAULT")  
            ) 
            ibuf_inst_array[AXIS_DATA_WIDTH - 1 : 0]
            (
             .O (data         ),    
             .I (counter_value)     
            );
        end
    endgenerate
    
    axis_data_generator_cntr #
    (
        .AXIS_DATA_WIDTH (AXIS_DATA_WIDTH),
        .AXIS_TKEEP      (AXIS_TKEEP     )
    )
    axis_data_generator_cntr_inst_0
    (
        .clk_i              (clk_i            ),
        .s_rst_n_i          (s_rst_n_i        ),
        .enable_i           (enable_i         ),                    
                           
        .m_axis_tdata_o     (m_axis_tdata_o   ),
        .m_axis_tkeep_o     (m_axis_tkeep_o   ),
        .m_axis_tvalid_o    (m_axis_tvalid_o  ),
        .m_axis_tlast_o     (m_axis_tlast_o   ),
        .m_axis_tready_i    (m_axis_tready_i  ),
                           
        .data_i             (data             ),
        .counter_terminal_i (counter_terminate),
        .counter_enable_o   (counter_enable   )
    );
  
endmodule
