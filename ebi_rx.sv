module ebi_rx
    import ebi_pkg::*;
    import rvh_l1d_pkg::*;
#(
    parameter CHANNEL_NUM,
    parameter CHANNEL_NUM_WIDTH,
    parameter MAX_MESSAGE_LENGTH,
    parameter MAX_MESSAGE_WIDTH,
    parameter int unsigned CHANNEL_LENGTH_LIST[CHANNEL_NUM]
)(
    input if_clk,
    input bus_clk,
    input rst,

    output logic [CHANNEL_NUM-1:0][MAX_MESSAGE_LENGTH-1:0]          vc_entry_list,  // wire here
    output logic [CHANNEL_NUM-1:0]                                  vc_valid,  
    input  logic [CHANNEL_NUM-1:0]                                  entry_if_recv_success,
    input  logic                                                    bus_in,
    output logic                                                    credit_out

);

logic send_bus_q;
always_ff @(posedge bus_clk) begin
    if(rst) begin
        send_bus_q <= 1'b1;
    end else begin
        send_bus_q <= bus_in;
    end
end

logic [MAX_MESSAGE_LENGTH + CHANNEL_NUM_WIDTH-1:0] recv_message_slot;
recv_state_t next_recv_state, recv_state;
logic en_recv_parity_check, en_recv_count, recv_complete;
logic [CHANNEL_NUM_WIDTH-1:0] recv_channel_id;
logic [MAX_MESSAGE_WIDTH-1:0] recv_count;
logic [CREDIT_WIDTH-1:0] send_credit_count;
credit_t send_credit_value;
logic recv_success, recv_failure;
logic recv_parity_bit;
logic en_send_credit_count;
send_credit_state_t send_credit_state, next_send_credit_state;
logic [PARITY_WIDTH:0] recv_parity_count;
logic [MAX_MESSAGE_LENGTH + CHANNEL_NUM_WIDTH-1:0] synced_recv_message;
logic async_message_recv_fifo_empty;
logic [CHANNEL_NUM-1:0] channel_push_ready;
// logic [CHANNEL_NUM-1:0][MAX_MESSAGE_LENGTH-1:0] vc_entry_list; // they are wire here

assign recv_channel_id = recv_message_slot[CHANNEL_NUM_WIDTH-1:0]; // The direction is relative to the cache  
assign recv_complete = recv_count == CHANNEL_LENGTH_LIST[recv_channel_id] + CHANNEL_NUM_WIDTH;

always_comb begin
    if(rst) begin
    next_recv_state = RECV_IDLE;
    en_recv_parity_check = 1'b0;
    en_recv_count = 1'b0;
    recv_success = 1'b0;
    recv_failure = 1'b0;
    end else begin
        en_recv_count = 1'b0;
        en_recv_parity_check = 1'b0;
        recv_success = 1'b0;
        recv_failure = 1'b0;
        unique case(recv_state)
            RECV_IDLE: begin
                if(~send_bus_q) begin
                    next_recv_state = GET_VC_NUM;
                    en_recv_parity_check = 1'b1;
                end else begin
                    next_recv_state = RECV_IDLE;
                end
            end
            GET_VC_NUM: begin
                en_recv_parity_check = 1'b1;
                en_recv_count = 1'b1;
                if(recv_count == CHANNEL_NUM_WIDTH - 1'b1) begin
                    next_recv_state = RECV_MESSSAGE;
                end else begin
                    next_recv_state = GET_VC_NUM;
                end
            end
            RECV_MESSSAGE: begin
                en_recv_parity_check = 1'b1;
                if((!recv_complete) && (recv_parity_count != PARITY_LENGTH)) begin
                    en_recv_count = 1'b1;
                end else begin
                    en_recv_count = 1'b0;
                end
                if((recv_parity_count == PARITY_LENGTH) && (recv_parity_bit ^ send_bus_q)) begin
                    next_recv_state = MAKE_CREDIT;
                    recv_failure = 1'b1;
                end else if (recv_complete && (recv_parity_count == PARITY_LENGTH))begin 
                    next_recv_state = MAKE_CREDIT; 
                    recv_success = 1'b1;
                end else begin
                    next_recv_state = RECV_MESSSAGE;
                end
            end
            MAKE_CREDIT: begin
                next_recv_state = RECV_IDLE;
            end
        endcase
    end
end

always_ff @(posedge bus_clk) begin
    if(rst | (recv_state == RECV_IDLE)) begin
       recv_parity_bit <= 1'b0; 
       recv_parity_count <= {(PARITY_WIDTH+1){1'b0}};
    end else begin
        if(recv_parity_count == PARITY_LENGTH) begin
            recv_parity_count <= {(PARITY_WIDTH+1){1'b0}};
            recv_parity_bit <= 1'b0;
        end else if(en_recv_parity_check) begin
            recv_parity_bit <= recv_parity_bit ^ send_bus_q;
            recv_parity_count <= recv_parity_count + 1'b1;
        end
    end
end

always_ff @(posedge bus_clk) begin
    if(rst) begin
        send_credit_value <= NO_CREDIT;
        recv_state <= RECV_IDLE;
        recv_count <= {MAX_MESSAGE_WIDTH{1'b0}};
        recv_message_slot <= {MAX_MESSAGE_LENGTH{1'b0}};
    end else begin
        recv_state <= next_recv_state;
        if(recv_state == RECV_MESSSAGE) begin
            if(recv_failure) begin
                send_credit_value <= FAILURE;
                recv_count <= {MAX_MESSAGE_WIDTH{1'b0}};
            end else if(recv_success) begin
                send_credit_value <= SUCCESS;
                recv_count <= {MAX_MESSAGE_WIDTH{1'b0}};
            end
        end else if(recv_state == GET_VC_NUM) begin
            send_credit_value <= NO_CREDIT;
        end
        if(en_recv_count && !recv_complete) begin
            recv_count <= recv_count + 1'b1;
            recv_message_slot[recv_count] <= send_bus_q;  // the slot doesn't need to flush
        end
    end
end

// send credit

always_comb begin
    if(rst) begin
        next_send_credit_state = SCREDIT_IDLE;
        en_send_credit_count = 1'b0;
    end else begin
        en_send_credit_count = 1'b0;
        unique case(send_credit_state)
            SCREDIT_IDLE: begin
                if(recv_state == MAKE_CREDIT) begin
                    next_send_credit_state = SCREDIT_START_BIT;
                end else begin
                    next_send_credit_state = SCREDIT_IDLE;
                end
            end
            SCREDIT_START_BIT: begin
                next_send_credit_state = SCREDIT_VALUE_SEND;
            end
            SCREDIT_VALUE_SEND: begin
                en_send_credit_count = 1'b1;
                if(send_credit_count == CREDIT_WIDTH - 1'b1) begin
                    next_send_credit_state = SCREDIT_IDLE;
                end else begin
                    next_send_credit_state = SCREDIT_VALUE_SEND;
                end
            end
        endcase
    end
end

logic transmitting_credit_bit;
always_ff @(negedge bus_clk) begin
    if(rst) begin
        transmitting_credit_bit <= 1'b1;
    end else begin
        unique case(send_credit_state)
            SCREDIT_IDLE: begin
                transmitting_credit_bit <= 1'b1;
            end
            SCREDIT_START_BIT: begin
                transmitting_credit_bit <= 1'b0;
            end
            SCREDIT_VALUE_SEND: begin
                transmitting_credit_bit <= send_credit_value[send_credit_count];
            end
        endcase
    end
end

always_ff @(posedge bus_clk) begin
    if(rst) begin
        send_credit_state <= SCREDIT_IDLE;
        send_credit_count <= {CREDIT_WIDTH{1'b0}};
    end else begin
        send_credit_state <= next_send_credit_state;
        if(send_credit_state == SCREDIT_IDLE) begin
            send_credit_count <= {CREDIT_WIDTH{1'b0}};
        end else if (en_send_credit_count) begin
            send_credit_count <= send_credit_count + 1'b1;
        end
    end
end


// resp received signal to SCU
async_fifo#(
    .DSIZE(MAX_MESSAGE_LENGTH + CHANNEL_NUM_WIDTH),    // Memory data word width
    .ASIZE(2)
) async_message_recv_fifo(
    .wclk(bus_clk),
    .wrst_n(~rst),
    .winc(recv_success), //write in `MAKE_CREDIT cycle
    .wdata(recv_message_slot),
    .wfull(),
    .awfull(),
    .rclk(if_clk),
    .rrst_n(~rst),
    .rinc((|channel_push_ready) && (~async_message_recv_fifo_empty)),
    .rdata(synced_recv_message),
    .rempty(async_message_recv_fifo_empty),
    .arempty()
);

generate 
    for (genvar i = 0; i < CHANNEL_NUM ;i++) begin
        StreamFIFO #(
            .Depth(VC_BUFFER_DEPTH),
            .WordWidth(CHANNEL_LENGTH_LIST[i])
        ) u_recv_vc (
            .enq_vld_i((synced_recv_message[CHANNEL_NUM_WIDTH-1:0] == i[CHANNEL_NUM_WIDTH-1:0]) && (!async_message_recv_fifo_empty)),
            .enq_payload_i(synced_recv_message[CHANNEL_LENGTH_LIST[i] + CHANNEL_NUM_WIDTH -1: CHANNEL_NUM_WIDTH]),
            .enq_rdy_o(channel_push_ready[i]),
            .deq_vld_o(vc_valid[i]),
            .deq_payload_o(vc_entry_list[i]),
            .deq_rdy_i(entry_if_recv_success[i]),
            .flush_i(1'b0),
            .clk(if_clk),
            .rstn(~rst)
        );
    end
endgenerate

assign credit_out = transmitting_credit_bit;

endmodule: ebi_rx