`timescale 1ns / 1ps

module axis_data_generator_cntr_tb;

    localparam integer             DATA_WIDTH          = 32;
    localparam integer             CLOCK_PERIOD        = 100;
    localparam integer             PACK_SIZE           = 1024;
    localparam integer             PACK_NUMBER         = 1024;
    localparam integer             WAIT_READY_TICK_NUM = 100;
    localparam integer             ITERATION_NUMBER    = PACK_SIZE * PACK_NUMBER;
    localparam integer             KEEP_WIDTH          = DATA_WIDTH / 8;
    localparam [KEEP_WIDTH- 1 : 0] KEEP_VALUE          = {KEEP_WIDTH{1'h1}};
  
    wire                          counter_enable; 
    wire                          counter_trmnt;
    
    wire                          axis_tvalid;
    wire                          axis_tlast;
    wire [DATA_WIDTH - 1 : 0]     axis_tdata;
    wire [DATA_WIDTH / 8 - 1 : 0] axis_tkeep;
 
    wire [DATA_WIDTH - 1 : 0]     data;
    
    reg  axis_tready;
    reg  clk;
    reg  rst_n;
    reg  enable;
  
    COUNTER_TC_MACRO #
    (
        .COUNT_BY      (48'h1     ),
        .DEVICE        ("7SERIES" ), 
        .DIRECTION     ("UP"      ),
        .RESET_UPON_TC ("TRUE"    ),
        .TC_VALUE      (PACK_SIZE ),
        .WIDTH_DATA    (DATA_WIDTH)
    ) 
    COUNTER_TC_MACRO_inst_0 
    (
        .Q             (data          ),
        .TC            (counter_trmnt ),
        .CLK           (clk           ),
        .CE            (counter_enable),
        .RST           (!rst_n        )
    );

    axis_data_generator_cntr #
    (
        .AXIS_DATA_WIDTH (DATA_WIDTH),
        .AXIS_TKEEP      (KEEP_VALUE)
    )
    axis_data_generator_cntr_dut_0
    (
        .clk_i              (clk           ),
        .s_rst_n_i          (rst_n         ),
        .enable_i           (enable        ),                    
                         
        .m_axis_tdata_o     (axis_tdata    ),
        .m_axis_tkeep_o     (axis_tkeep    ),
        .m_axis_tvalid_o    (axis_tvalid   ),
        .m_axis_tlast_o     (axis_tlast    ),
        .m_axis_tready_i    (axis_tready   ),
                         
        .data_i             (data          ),
        .counter_terminal_i (counter_trmnt ),
        .counter_enable_o   (counter_enable)
    );
    
    task check_data; begin
        enable <= 1'h1;
        rst_n  <= 1'h1;
        @(posedge clk);
      
        wait (axis_tvalid);
      
        repeat(WAIT_READY_TICK_NUM) begin 
            if ({DATA_WIDTH{1'h0}} !== axis_tdata) begin
                $display($time, "The ready signal error.");
                $stop();
            end
            
            @(posedge clk); 
        end
      
        repeat(ITERATION_NUMBER) begin 
            axis_tready <= $urandom % 2; 
            @(posedge clk); 
        end

        enable <= 1'h0;
    end
    endtask 
    
    initial begin
        clk = 1'h0;

        forever begin
            #(CLOCK_PERIOD / 2) clk = !clk;
        end 
    end 
    
    initial begin
        rst_n  = 1'h0;
        enable = 1'h0;
        
        @(posedge clk);
        check_data;

        $display($time, "The test has finished.");  

        $stop();            
    end

endmodule
