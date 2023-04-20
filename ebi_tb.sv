module ebi_tb;

import ebi_pkg::*;
import rvh_l1d_pkg::*;

initial begin
    $fsdbDumpfile("./logs/waves.fsdb");
    $fsdbDumpvars(0,ebi_tb);
    $fsdbDumpvars("+struct");
    $fsdbDumpvars("+mda");
    $fsdbDumpvars("+all");
    $fsdbDumpon;
end 

localparam HALF_CAHCHE_CLK_PERIORD = 10;	
localparam HALF_BUS_CLK_PERIORD = 30;	
logic cache_clk, bus_clk, rst;
always #(HALF_BUS_CLK_PERIORD) bus_clk = ~bus_clk;
always #(HALF_CAHCHE_CLK_PERIORD) cache_clk = ~cache_clk;

logic l1d_l2_req_arvalid, l1d_l2_req_arready, m1_m2_bus, m1_m2_credit, l1d_scu_req_arready, l1d_scu_req_arvalid, l1d_l2_req_awvalid, l1d_l2_req_awready, l1d_scu_req_awvalid, l1d_scu_req_awready;
logic l2_snp_req_if_acvalid, l2_snp_req_if_acready, l1_snp_req_if_acready, l1_snp_req_if_acvalid, scu_l1d_resp_bvalid, scu_l1d_resp_bready, l2_l1d_resp_bvalid, l2_l1d_resp_bready;
logic m2_m1_bus, m2_m1_credit;

cache_mem_if_ar_t l1d_l2_req_ar;
cache_mem_if_aw_t l1d_l2_req_aw;
cache_mem_if_ac_t l2_snp_req_if_ac;
cache_mem_if_b_t scu_l1d_resp_b;

initial begin
    cache_clk = 0;
    bus_clk = 0;
    rst = 1;
    #205
    rst = 0;
    #40000
    $finish;
end

m1_ebi u_cache_ebi(
    .m1_clk(cache_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    
    .l1d_l2_req_arvalid_i(l1d_l2_req_arvalid),
    .l1d_l2_req_arready_o(l1d_l2_req_arready),
    .l1d_l2_req_ar_i(l1d_l2_req_ar),
    
    .l1d_l2_req_awvalid_i(l1d_l2_req_awvalid),
    .l1d_l2_req_awready_o(l1d_l2_req_awready),
    .l1d_l2_req_aw_i(l1d_l2_req_aw),
    
    .l1d_l2_req_wvalid_i(),
    .l1d_l2_req_wready_o(),
    .l1d_l2_req_w_i(),
    
    .l2_l1d_resp_bvalid_o(l2_l1d_resp_bvalid),
    .l2_l1d_resp_bready_i(l2_l1d_resp_bready),
    .l2_l1d_resp_b_o(),
    
    .l2_l1d_resp_rvalid_o(),
    .l2_l1d_resp_rready_i(),
    .l2_l1d_resp_r_o(),
    
    .l2_snp_req_if_acvalid_o(l1_snp_req_if_acvalid),
    .l2_snp_req_if_acready_i(l1_snp_req_if_acready),
    .l2_snp_req_if_ac_o(),
    
    .l2_snp_resp_if_crvalid_i(),
    .l2_snp_resp_if_crready_o(),
    .l2_snp_resp_if_cr_i(),
    
    .l2_snp_resp_if_cdvalid_i(),
    .l2_snp_resp_if_cdready_o(),
    .l2_snp_resp_if_cd_i(),
    
    .m1_m2_bus_o(m1_m2_bus),
    .m2_m1_credit_i(m1_m2_credit),
    .m2_m1_bus_i(m2_m1_bus),
    .m1_m2_credit_o(m2_m1_credit)
);

m2_ebi u_scu_ebi(
    .m2_clk(cache_clk),
    .bus_clk(bus_clk),
    .rst(rst),
    .l1d_scu_req_arvalid_o(l1d_scu_req_arvalid),
    .l1d_scu_req_arready_i(l1d_scu_req_arready),
    .l1d_scu_req_ar_o(),
    .l1d_scu_req_awvalid_o(l1d_scu_req_awvalid),
    .l1d_scu_req_awready_i(l1d_scu_req_awready),
    .l1d_scu_req_aw_o(),
    .l1d_scu_req_wvalid_o(),
    .l1d_scu_req_wready_i(),
    .l1d_scu_req_w_o(),
    .scu_l1d_resp_bvalid_i(scu_l1d_resp_bvalid),
    .scu_l1d_resp_bready_o(scu_l1d_resp_bready),
    .scu_l1d_resp_b_i(scu_l1d_resp_b),
    .scu_l1d_resp_rvalid_i(),
    .scu_l1d_resp_rready_o(),
    .scu_l1d_resp_r_i(),
    .l2_snp_req_if_acvalid_i(l2_snp_req_if_acvalid),
    .l2_snp_req_if_acready_o(l2_snp_req_if_acready),
    .l2_snp_req_if_ac_i(l2_snp_req_if_ac),
    .l2_snp_resp_if_crvalid_o(),
    .l2_snp_resp_if_crready_i(),
    .l2_snp_resp_if_cr_o(),
    .l2_snp_resp_if_cdvalid_o(),
    .l2_snp_resp_if_cdready_i(),
    .l2_snp_resp_if_cd_o(),
    .m1_m2_bus_i(m1_m2_bus),
    .m2_m1_credit_o(m1_m2_credit),
    .m2_m1_bus_o(m2_m1_bus),
    .m1_m2_credit_i(m2_m1_credit)
);

initial begin
    l1d_l2_req_arvalid = 1'b0;
    l1d_l2_req_ar = {8'h13, 8'hae, 3'b010, 2'b11, 40'h123456789a};
    #205;
    l1d_l2_req_arvalid = 1'b1;
    l1d_scu_req_arready = 1'b1;

    @(l1d_l2_req_arvalid & l1d_l2_req_arready);
    @(posedge cache_clk)
    l1d_l2_req_arvalid = 1'b0;

end

initial begin
    l1d_l2_req_awvalid = 1'b0;
    l1d_l2_req_aw = {8'h12, 40'h33356789a, 8'h3a, 3'b0, 2'b11};
    #205;
    l1d_l2_req_awvalid = 1'b1;
    l1d_scu_req_awready = 1'b1;

    @(l1d_l2_req_arvalid & l1d_l2_req_arready);
    @(posedge cache_clk)
    l1d_l2_req_awvalid = 1'b0;
end

initial begin
    l2_snp_req_if_acvalid = 1'b0;
    l2_snp_req_if_ac = {40'h3d35674e, 4'ha, 3'h4};
    #205;
    l2_snp_req_if_acvalid = 1'b1;
    l1_snp_req_if_acready = 1'b1;

    @(l2_snp_req_if_acvalid & l2_snp_req_if_acready);
    @(posedge cache_clk)
    l2_snp_req_if_acvalid = 1'b0;
end

initial begin
    scu_l1d_resp_bvalid = 1'b0;
    scu_l1d_resp_b = {8'hcc, AXI_RESP_OKAY};
    #205;
    scu_l1d_resp_bvalid = 1'b1;
    l2_l1d_resp_bready = 1'b1;

    @(scu_l1d_resp_bvalid & scu_l1d_resp_bready);
    @(posedge cache_clk)
    scu_l1d_resp_bvalid = 1'b0;
end

endmodule: ebi_tb