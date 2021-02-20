`timescale 1ns / 1ps

// just coommet it if needed only a test due to a counter
`define INIT_FROM_FILE  

module axis_data_generator_tb;

    localparam integer             DATA_WIDTH = 32;
    localparam integer             KEEP_WIDTH = DATA_WIDTH / 8;
    localparam [KEEP_WIDTH- 1 : 0] KEEP_VALUE = {KEEP_WIDTH{1'h1}};
  
`ifdef INIT_FROM_FIL
    localparam                     INIT_FILE  = "/media/shimko/2E0A00DD0A00A445/workspace_vivado_2018_3/xc7z045_1ge/tb/data.txt";
`else
    localparam                     INIT_FILE  = "";
`endif

    localparam integer             BURST_SIZE   = 99; //
    localparam integer             CLOCK_PERIOD = 100;
    localparam integer             RPTING_NMBER = 1024 * (BURST_SIZE + 1);
    
    wire                          axis_tvalid;
    wire                          axis_tlast;
    wire [DATA_WIDTH - 1 : 0]     axis_tdata;
    wire [DATA_WIDTH / 8 - 1 : 0] axis_tkeep;
    
    wire                          termint;
    wire [DATA_WIDTH - 1 : 0]     ref_data;
    
    reg                      clk;
    reg                      rst_n;
    reg                      enable;
    reg                      axis_tready;

    integer errors  = 0;
    
 `ifdef INIT_FROM_FILE    
    integer file_dc = 0; 
    integer i       = 0;
 `endif

    COUNTER_TC_MACRO #
    (
        .COUNT_BY      (48'h1     ),
        .DEVICE        ("7SERIES" ), 
        .DIRECTION     ("UP"      ),
        .RESET_UPON_TC ("TRUE"    ),
        .TC_VALUE      (BURST_SIZE),
        .WIDTH_DATA    (DATA_WIDTH)
    ) 
    COUNTER_TC_MACRO_reference_inst_0
    (
        .Q             (ref_data     ),
        .TC            (termint),
        .CLK           (clk          ),
        .CE            (axis_tready  ),
        .RST           (!rst_n       )
    );

    axis_data_generator #
    (
       .AXIS_DATA_WIDTH (DATA_WIDTH),
       .AXIS_TKEEP      (KEEP_VALUE),
       .INIT_FILE       (INIT_FILE ),
       .BURST_SIZE      (BURST_SIZE)
    )
    axis_data_generator_dut_0
    (
       .clk_i           (clk        ),
       .s_rst_n_i       (rst_n      ),
       .enable_i        (enable     ),                    
                        
       .m_axis_tdata_o  (axis_tdata ),
       .m_axis_tkeep_o  (axis_tkeep ),
       .m_axis_tvalid_o (axis_tvalid),
       .m_axis_tlast_o  (axis_tlast ),
       .m_axis_tready_i (axis_tready)
    );
    
`ifdef INIT_FROM_FILE
    initial begin
        file_dc = $fopen(INIT_FILE, "w"); 
        
        if (0 != file_dc) begin

            for (i = 0; i < BURST_SIZE; i = i + 1) begin
                $fwrite(file_dc,"%h\n", i);
            end
            
            $fclose(file_dc);
        end
        else begin
            $error($time, " The file open error\n");
        end
    end
`endif
    
   task compare_data; begin
        rst_n           <= 1'h1;
        enable          <= 1'h1;
        axis_tready     <= 1'h1; 
        @(posedge clk);
        
        if (1'h1 !== axis_tvalid) begin
            $error($time, " The tvalid signal error\n");
            errors = errors + 1;
        end
        else begin
            repeat(RPTING_NMBER) begin
                axis_tready <= $urandom % 2; 

                if ((ref_data !== axis_tdata) && (1'h1 == axis_tlast)) begin
                    $error($time, " The tdata error. It has to be %d, but is %d\nTest failed\n", ref_data, axis_tdata);
                    errors = errors + 1;
                end
                 
                @(posedge clk);
            end
            
        if (termint !== axis_tlast) begin
            $error($time, " The tlast signal error\nTest failed\n");
            errors = errors + 1;
        end    
            
        end  
    end
    endtask
    
    initial begin
        clk = 1'h0;

        forever begin
            #(CLOCK_PERIOD / 2) clk = !clk;
        end 
    end    
  
    
    initial begin
`ifdef INIT_FROM_FILE 
        #BURST_SIZE;
`endif
        rst_n       = 1'h0;
        enable      = 1'h0;
        axis_tready = 1'h0;
        @(posedge clk);
        
        compare_data;

        if (0 == errors) begin
            $display($time, " The test successfully finished\n");  
        end
        else begin
            $display($time, " The test failed with %d errors\n", errors); 
        end

        $stop();            
    end
    

endmodule

































