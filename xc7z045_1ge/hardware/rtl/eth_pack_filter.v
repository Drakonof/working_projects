`timescale 1ns / 1ps

module eth_pack_filter #
( 
    parameter integer STREAM_DATA_WIDTH = 32,
    parameter [47:0]  MAC_ADDRESS       = 48'hda0102030405,
    parameter [31:0]  IP_ADDRESS        = 32'hc0a81201, //192.168.18.1
    parameter integer PAYLOAD_MAX_SIZE  = 1600
)
(
    input  wire                                    clk_i,
    input  wire                                    s_rst_n_i,
    
    //--------------------------------------------------AXIS Master to axi DMA
    output wire  [STREAM_DATA_WIDTH - 1 : 0]       m_axis_tdata_o,
    output wire  [(STREAM_DATA_WIDTH / 8) - 1 : 0] m_axis_tkeep_o,
    output wire                                    m_axis_tvalid_o,
    output wire                                    m_axis_tlast_o,
    input  wire                                    m_axis_tready_i,
    
    //--------------------------------------------------AXIS Slave from axi DMA
    input  wire  [STREAM_DATA_WIDTH - 1 : 0]       s_axis_tdata_i,
    input  wire  [(STREAM_DATA_WIDTH / 8) - 1 : 0] s_axis_tkeep_i,
    input  wire                                    s_axis_tvalid_i,
    input  wire                                    s_axis_tlast_i,
    output wire                                    s_axis_tready_o  
);  

    localparam integer               STATE_NUM     = 15;
    localparam integer               STATE_WIDTH   = $clog2(STATE_NUM);
    localparam integer               PAYLOAD_WIDTH = $clog2(PAYLOAD_MAX_SIZE);
    
    localparam [STATE_WIDTH - 1 : 0] IDLE_STATE = 0;
    localparam [STATE_WIDTH - 1 : 0] SRC_MAC_STATE  = 1;
    localparam [STATE_WIDTH - 1 : 0] SRC_MAC_TL_STATE  = 2;
    localparam [STATE_WIDTH - 1 : 0] DST_MAC_STATE  = 3;
    localparam [STATE_WIDTH - 1 : 0] ETH_TYPE_STATE = 4;
    localparam [STATE_WIDTH - 1 : 0] LENGHT_STATE = 5;
    localparam [STATE_WIDTH - 1 : 0] PROTOCOL_STATE = 6;
    localparam [STATE_WIDTH - 1 : 0] SRC_IP_STATE = 7;
    localparam [STATE_WIDTH - 1 : 0] DST_IP_STATE = 8;
    localparam [STATE_WIDTH - 1 : 0] OPTIONS1_STATE = 9;
    localparam [STATE_WIDTH - 1 : 0] OPTIONS2_STATE = 10;
    localparam [STATE_WIDTH - 1 : 0] IP1_STATE = 11;
    localparam [STATE_WIDTH - 1 : 0] IP2_STATE = 12;
    localparam [STATE_WIDTH - 1 : 0] PAYLOAD_STATE = 13;
    localparam [STATE_WIDTH - 1 : 0] CRC_STATE = 14;
    
    localparam [15 : 0]              IP_HEADER_SIZE = 16'h16;
    localparam [7  : 0]              UDP_PROTOCOL   = 8'h11;
    
    wire          counter_en;
    wire [10 : 0] counter_value;
    wire          counter_rst;
    
    wire dst_mac_valid;
    wire [47 : 0] addr;


    reg                                 s_axis_tready;
   // reg [(STREAM_DATA_WIDTH / 8) - 1:0] s_axis_tkeep;
    
    reg [PAYLOAD_WIDTH - 1 : 0]         payload_lenght;
    reg [STATE_WIDTH - 1 : 0]           fsm_state;
    reg [15 : 0]                        dst_mac_head;
    
    assign counter_en      = (fsm_state == PAYLOAD_STATE);
    assign counter_rst     = ((fsm_state == CRC_STATE) || !s_rst_n_i);
 
    assign m_axis_tkeep_o  = s_axis_tkeep_i;
    assign m_axis_tvalid_o = (fsm_state == PAYLOAD_STATE);
    assign m_axis_tlast_o  = s_axis_tlast_i;
    assign s_axis_tready_o = s_axis_tready && m_axis_tready_i;
    
    assign addr         = {dst_mac_head, s_axis_tdata_i};
    assign dst_mac_valid = (48'hda0102030405 == addr);
    
    assign m_axis_tdata_o = (fsm_state == PAYLOAD_STATE) ? s_axis_tdata_i : 0;

    COUNTER_TC_MACRO #
    (
      .COUNT_BY      (48'h1),
      .DEVICE        ("7SERIES"),
      .DIRECTION     ("UP"),
      .RESET_UPON_TC ("TRUE"),
      .TC_VALUE      (11'h640),
      .WIDTH_DATA    (11)
    ) 
    COUNTER_TC_MACRO_inst 
    (
      .Q             (counter_value),
      //.TC            (TC),
      .CLK           (clk_i),
      .CE            (counter_en),
      .RST           (counter_rst)
    );
    
  // last??
  // baud width
    always @ (posedge clk_i) begin
        if (1'h0 == s_rst_n_i) begin
            fsm_state      <= IDLE_STATE;
            s_axis_tready  <= 1'h0;
            dst_mac_head   <= 16'h0;
            payload_lenght <= 16'h0;
     //       s_axis_tkeep   <= {(STREAM_DATA_WIDTH / 8),{1'h1}};
      //      s_axis_tlast   <= 1'h0;
        end
        else begin  
            case (fsm_state)
                IDLE_STATE: begin
              //      s_axis_tlast <= 1'h0;
                    s_axis_tready <= 1'h1;
                    
                    dst_mac_head <= s_axis_tdata_i[15 : 0];
                    if (s_axis_tvalid_i && m_axis_tready_i && dst_mac_valid) begin
                        fsm_state     <= LENGHT_STATE;
                        
                    end
                end
      /*          SRC_MAC_STATE: begin
                    fsm_state    <= SRC_MAC_TL_STATE;
           //         s_axis_tkeep <= s_axis_tkeep_i;
                end
                SRC_MAC_TL_STATE: begin
                    fsm_state    <= DST_MAC_STATE;
                    dst_mac_head <= s_axis_tdata_i[31 : 16];
                end
                DST_MAC_STATE: begin 
                    if (MAC_ADDRESS == {dst_mac_head, s_axis_tdata_i}) begin
                        fsm_state <= ETH_TYPE_STATE;
                    end
                    else begin
                        fsm_state     <= IDLE_STATE;
                        s_axis_tready <= 1'h0;
                    end
                end*/
           //     LENGHT_STATE: begin
           //         fsm_state <= LENGHT_STATE;
           //     end  
                LENGHT_STATE: begin
                    fsm_state      <= IP1_STATE;
                    payload_lenght <= (s_axis_tdata_i[15 : 0] - IP_HEADER_SIZE);
                end
                IP1_STATE: begin
                    fsm_state <= IP2_STATE;
                end
                IP2_STATE: begin
                    fsm_state <= PROTOCOL_STATE;
                end
                PROTOCOL_STATE:  begin
                    if (UDP_PROTOCOL == s_axis_tdata_i[15 : 8]) begin
                        fsm_state <= SRC_IP_STATE;
                    end
                    else begin
                        fsm_state     <= IDLE_STATE;
                        s_axis_tready <= 1'h0;
                    end
                end
                SRC_IP_STATE: begin
                    fsm_state <= DST_IP_STATE;
                end
                DST_IP_STATE: begin
                    if (IP_ADDRESS == s_axis_tdata_i) begin
                        fsm_state <= OPTIONS1_STATE;
                    end
                    else begin
                        fsm_state     <= IDLE_STATE;
                        s_axis_tready <= 1'h0;
                    end
                end
                OPTIONS1_STATE: begin
                    fsm_state <= OPTIONS2_STATE;
                end
                OPTIONS2_STATE: begin
                    fsm_state <= PAYLOAD_STATE;
                end
                PAYLOAD_STATE: begin
                    if (payload_lenght == (counter_value - 1'h1))  begin
                        fsm_state <= CRC_STATE;
                    end
                end    
                CRC_STATE: begin
                  //  if (1'h1 == fifo_empty) begin
                        fsm_state     <= IDLE_STATE;
                  //      s_axis_tready <= 1'h0;
                //        s_axis_tkeep  <= 0;
                 //       s_axis_tlast  <= 1'h1;
          
                end
                default: begin
                    fsm_state      <= IDLE_STATE;
                    s_axis_tready  <= 1'h0;
                    dst_mac_head   <= 16'h0;
                    payload_lenght <= 16'h0;
            //        s_axis_tkeep   <= {(STREAM_DATA_WIDTH / 8),{1'h1}};
            //        s_axis_tlast   <= 1'h0;
                end
            endcase
        end
    end

endmodule
