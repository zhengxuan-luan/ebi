package ebi_pkg;
import rvh_l1d_pkg::*;

// single channel information
localparam AR_MESSAGE_LENGTH = $bits(cache_mem_if_ar_t);
localparam AW_MESSAGE_LENGTH = $bits(cache_mem_if_aw_t);
localparam W_BEAT_LENGTH = $bits(cache_mem_if_w_t);
localparam W_MESSAGE_LENGTH =  BURST_SIZE * W_BEAT_LENGTH;
localparam B_MESSAGE_LENGTH = $bits(cache_mem_if_b_t);
localparam R_BEAT_LENGTH = $bits(cache_mem_if_r_t);
localparam R_MESSAGE_LENGTH =  BURST_SIZE * R_BEAT_LENGTH;
localparam AC_MESSAGE_LENGTH = $bits(cache_mem_if_ac_t);
localparam CR_MESSAGE_LENGTH = $bits(cache_mem_if_cr_t);
localparam CD_BEAT_LENGTH = $bits(cache_mem_if_cd_t);
localparam CD_MESSAGE_LENGTH = BURST_SIZE * CD_BEAT_LENGTH;

// total channels information
localparam M1_M2_CHANNEL_NUM = 5;
localparam M1_M2_CHANNEL_NUM_WIDTH = $clog2(M1_M2_CHANNEL_NUM);
localparam M2_M1_CHANNEL_NUM = 3;
localparam M2_M1_CHANNEL_NUM_WIDTH = $clog2(M2_M1_CHANNEL_NUM);

typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_AR, ID_AW, ID_W, ID_CR, ID_CD} m1_m2_channel_id_t;
typedef enum logic [M1_M2_CHANNEL_NUM_WIDTH-1:0] {ID_B, ID_R, ID_AC} m2_m1_channel_id_t;

parameter int unsigned M1_M2_CHANNEL_LENGTH_LIST[M1_M2_CHANNEL_NUM] = '{AR_MESSAGE_LENGTH, AW_MESSAGE_LENGTH, W_MESSAGE_LENGTH, CR_MESSAGE_LENGTH, CD_MESSAGE_LENGTH};
parameter int unsigned M2_M1_CHANNEL_LENGTH_LIST[M2_M1_CHANNEL_NUM] = '{B_MESSAGE_LENGTH, R_MESSAGE_LENGTH, AC_MESSAGE_LENGTH};

// localparam MAX_M1_M2_MESSAGE_LENGTH = M1_M2_CHANNEL_LENGTH_LIST.max();
localparam MAX_M1_M2_MESSAGE_LENGTH = W_MESSAGE_LENGTH;
localparam MAX_M1_M2_MESSAGE_WIDTH = $clog2(MAX_M1_M2_MESSAGE_LENGTH);

// localparam MAX_M2_M1_MESSAGE_LENGTH = M2_M1_CHANNEL_LENGTH_LIST.max();
localparam MAX_M2_M1_MESSAGE_LENGTH = R_MESSAGE_LENGTH;
localparam MAX_M2_M1_MESSAGE_WIDTH = $clog2(MAX_M1_M2_MESSAGE_LENGTH);

// transmition config
localparam PARITY_LENGTH = 8;
localparam PARITY_WIDTH = $clog2(PARITY_LENGTH);
localparam CREDIT_LENGTH = 2;
localparam CREDIT_WIDTH = 2;
localparam VC_BUFFER_DEPTH = 4;

// type definition
typedef enum logic [2:0] {RCREDIT_IDLE, RRECV_CREDIT, RCREDIT_CHECK} recv_credit_state_t;
typedef enum logic [CREDIT_WIDTH-1:0] {NO_CREDIT, SUCCESS, FAILURE} credit_t;
typedef enum logic[3:0] {SEND_IDLE, START_BIT, MESSAGE_SEND, INSERT_PARITY, END_BIT, WAIT_CREDIT} send_state_t;
typedef enum logic [3:0] {RECV_IDLE, GET_VC_NUM, RECV_MESSSAGE, MAKE_CREDIT} recv_state_t;
typedef enum logic [2:0] {SCREDIT_IDLE, SCREDIT_START_BIT, SCREDIT_VALUE_SEND}send_credit_state_t;

endpackage