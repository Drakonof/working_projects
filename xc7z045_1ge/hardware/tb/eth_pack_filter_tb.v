`define  UDP_PACK_FILE     "/media/shimko/2E0A00DD0A00A445/workspace_vivado_2018_3/xc7z045_1ge/tb/udp_pack.txt"
`define  FILTRED_DATA_FILE "/media/shimko/2E0A00DD0A00A445/workspace_vivado_2018_3/xc7z045_1ge/tb/filtred_data.txt"

`timescale 1ns / 1ps

module eth_pack_filter_tb; 

    localparam integer               DATA_WIDTH   = 32;
    localparam integer               BURST_SIZE   = 27;
    localparam integer               CLOCK_PERIOD = 100;
    localparam integer               TKEEP_WIDTH  = DATA_WIDTH / 8;
    localparam [TKEEP_WIDTH - 1 : 0] TKEEP_VALUE  = {TKEEP_WIDTH{1'h1}};
    
    wire                       m_axis_tvalid;
    wire                       m_axis_tlast;
    wire                       m_axis_tready;
    wire [DATA_WIDTH - 1 : 0]  m_axis_tdata;
    wire [TKEEP_WIDTH - 1 : 0] m_axis_tkeep;
    
    wire                       wf_axis_tvalid;
    wire                       wf_axis_tlast;
    wire [DATA_WIDTH - 1 : 0]  wf_axis_tdata;
    wire [TKEEP_WIDTH - 1 : 0] wf_axis_tkeep;
    
    reg clk;
    reg rst_n;
    reg enable;
    
    reg wf_axis_tready;
    
    reg [DATA_WIDTH - 1 : 0]  arr [16 : 0];
    
    integer i       = 0;
    integer file_dc = 0;
    
    axis_data_generator #
    (
        .AXIS_DATA_WIDTH (DATA_WIDTH    ),
        .AXIS_TKEEP      (TKEEP_VALUE   ),
        .INIT_FILE       (`UDP_PACK_FILE),
        .BURST_SIZE      (BURST_SIZE    )
    )
    axis_data_generator_inst_0
    (
        .clk_i           (clk),
        .s_rst_n_i       (rst_n),
        .enable_i        (enable),                    
                         
        .m_axis_tdata_o  (m_axis_tdata ),
        .m_axis_tkeep_o  (m_axis_tkeep ),
        .m_axis_tvalid_o (m_axis_tvalid),
        .m_axis_tlast_o  (m_axis_tlast ),
        .m_axis_tready_i (m_axis_tready)
    );

    eth_pack_filter #
    ( 
        .STREAM_DATA_WIDTH (32              ),
        .MAC_ADDRESS       (48'h5a0102030405),
        .IP_ADDRESS        (32'hc0a81201    ), //192.168.18.1
        .PAYLOAD_MAX_SIZE  (1600            )
    )
    eth_pack_filter_dut_0
    (
        .clk_i           (clk),
        .s_rst_n_i       (rst_n),
                         
        .m_axis_tdata_o  (wf_axis_tdata ),
        .m_axis_tkeep_o  (wf_axis_tkeep ),  //not used
        .m_axis_tvalid_o (wf_axis_tvalid),
        .m_axis_tlast_o  (wf_axis_tlast ),
        .m_axis_tready_i (wf_axis_tready),
                         
        .s_axis_tdata_i  (m_axis_tdata  ),
        .s_axis_tkeep_i  (m_axis_tkeep  ),
        .s_axis_tvalid_i (m_axis_tvalid ),
        .s_axis_tlast_i  (m_axis_tlast  ),
        .s_axis_tready_o (m_axis_tready )  
    );
    
    task filter_data; begin
        rst_n          <= 1'h1;
        enable         <= 1'h1;
        wf_axis_tready <= 1'h1;
        @(posedge clk);
        
        wait(wf_axis_tvalid);
        
       // file_dc = $fopen(`FILTRED_DATA_FILE, "w"); 
        
      //  if (0 != file_dc) begin

            //wait (wf_axis_tlast) begin
            for (i = 0; 1'h0 == wf_axis_tlast; i = i + 1) begin
                //$fwrite(file_dc, "%h\n", wf_axis_tdata);
                arr[i] <= wf_axis_tdata;
                @(posedge clk);
            end
            
        //    $fclose(file_dc);
        //end
     //   else begin
        //    $error($time, " The file open error\n");
      //  end
        
    end
    endtask
    
    initial begin
        clk = 1'h0;

        forever begin
            #(CLOCK_PERIOD / 2) clk = !clk;
        end 
    end
    
    initial begin
        rst_n          = 1'h0;
        enable         = 1'h0;
        wf_axis_tready = 1'h0;
        @(posedge clk);
        
        filter_data;

        $display($time, "The test has finished.");  

        $stop();            
    end

endmodule
