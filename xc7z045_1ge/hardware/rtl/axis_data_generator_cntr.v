`timescale 1ns / 1ps

module axis_data_generator_cntr #
(
    parameter integer                        AXIS_DATA_WIDTH = 32,
    parameter [(AXIS_DATA_WIDTH / 8) - 1:0]  AXIS_TKEEP      = ({(AXIS_DATA_WIDTH / 8){1'h0}} + 4'hf)
)
(
    input  wire                                  clk_i,
    input  wire                                  s_rst_n_i,
    input  wire                                  enable_i,                    

    output wire  [AXIS_DATA_WIDTH - 1 : 0]       m_axis_tdata_o,
    output wire  [(AXIS_DATA_WIDTH / 8) - 1 : 0] m_axis_tkeep_o,
    output wire                                  m_axis_tvalid_o,
    output wire                                  m_axis_tlast_o,
    input  wire                                  m_axis_tready_i,
    
    input  wire  [AXIS_DATA_WIDTH - 1 : 0]       data_i,
    input  wire                                  counter_terminal_i,
    output wire                                  counter_enable_o
);

    localparam integer               STATE_NUM     = 3;
    localparam integer               STATE_WIDTH   = $clog2(STATE_NUM);
    
    localparam [STATE_WIDTH - 1 : 0] IDLE_STATE    = 0;
    localparam [STATE_WIDTH - 1 : 0] SENDING_STATE = 1;
    localparam [STATE_WIDTH - 1 : 0] STOP_STATE    = 2;  
    
    reg [STATE_WIDTH - 1 : 0] fsm_state;
    reg [STATE_WIDTH - 1 : 0] next_fsm_state;
    
    assign m_axis_tvalid_o  = enable_i;
    assign m_axis_tkeep_o   = AXIS_TKEEP;
    assign m_axis_tlast_o   = counter_terminal_i;
    
    assign counter_enable_o = (/*(SENDING_STATE == fsm_state) &&*/ (1'h1 == m_axis_tready_i));
    assign m_axis_tdata_o   = data_i;
    
    always @( posedge clk_i ) begin
        if (1'h0 == s_rst_n_i) begin
            fsm_state <= IDLE_STATE;
        end
        else begin
            fsm_state <= next_fsm_state;
        end
    end

    always @ (*) begin
        next_fsm_state = fsm_state;
        
        if (1'h1 == enable_i) begin
            case (fsm_state)
                IDLE_STATE: begin
                    if (1'h1 == m_axis_tready_i) begin
                        next_fsm_state = SENDING_STATE;
                    end
                end
                SENDING_STATE: begin
                    if (1'h1 == counter_terminal_i) begin
                        next_fsm_state = STOP_STATE;
                    end
                end
                STOP_STATE: begin
                    next_fsm_state = IDLE_STATE;
                end
            endcase
        end
    end

endmodule
