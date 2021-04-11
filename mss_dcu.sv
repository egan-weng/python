`ifdef ARM_FCOV_ON
`ifndef ARM_L1_COV_TESTS
`define ARM_L1_COV_TESTS 1
`endif
`endif

module yamin_dcu import yamin_pkg::*; import yamin_dcu_pkg::*; #(
    `include "yamin_decl.sv"
    , parameter STB_OPT = 0
) (
  //----------------------------------------------------------------------------
  // Clock and Reset
  //----------------------------------------------------------------------------

  input  wire logic               clk,
  input  wire logic               dclk,
  input  wire logic               csysreset_n,
  input  wire logic               cporeset_n,

  //----------------------------------------------------------------------------
  // DFT
  //----------------------------------------------------------------------------

  input  wire logic               ext_dftramhold_i,

  //----------------------------------------------------------------------------
  // LSU Interface
  //----------------------------------------------------------------------------

  input  wire logic               lsu_dcu_load_m1_i,
  input  wire logic               lsu_dcu_low_priority_load_m1_i,
  input  wire logic [31:0]        lsu_dcu_addr_m1_i,
  input  wire logic               lsu_dcu_sameline_m1_i,
  output wire logic               dcu_lsu_stall_m1_o,
  input  wire logic               lsu_dcu_leaving_ls1_i,
  input  wire logic               lsu_dcu_kill_ls1_i,
  output wire logic               dcu_lsu_load_hit_m2_o,
  output wire logic [31:0]        dcu_lsu_load_data_m2_o,
  output wire logic               dcu_lsu_ecc_err_m2_o,
  output wire logic               dcu_lsu_rd_imp_bus_fault_o,
  output wire logic               dcu_lsu_inv_imp_bus_fault_o,
  output wire logic [3:0]         dcu_lsu_victim_way_m2_o,
  output wire logic               dcu_lsu_ecc_cm_in_prog_o,
  output wire logic               dcu_lsu_dmev0_o,
  output wire logic               dcu_lsu_dmev1_o,
  output wire logic               dcu_lsu_dmev2_o,
  output wire logic [25:0]        dcu_lsu_dmei0_o,
  output wire logic [25:0]        dcu_lsu_dmei1_o,
  input  wire logic               lsu_watchcat_fire_i,
  output wire logic               dcu_lsu_watchcat_two_o,
  output wire logic               dcu_lsu_watchcat_three_o,
  output wire logic               dcu_lsu_watchcat_triple_o,

  //----------------------------------------------------------------------------
  // STB Interface
  //----------------------------------------------------------------------------

  output wire logic               dcu_stb_drain_entire_stb_o,
  input  wire logic               stb_dcu_ch_drained_i,
  input  wire logic               stb_dcu_tag_req_m0_i,
  input  wire logic               stb_dcu_tag_write_m0_i,
  input  wire logic [3:0]         stb_dcu_tag_way_m0_i,
  input  wire logic [31:5]        stb_dcu_tag_addr_m0_i,
  input  wire half_attr_t         stb_dcu_tag_write_attrs_m0_i,
  input  wire logic               stb_dcu_tag_write_ns_attr_m0_i,
  output wire logic               dcu_stb_tag_has_priority_m0_o,
  output wire logic               dcu_stb_tag_ack_m1_o,
  output wire logic [3:0]         dcu_stb_tag_hit_m2_o,
  output wire logic               dcu_stb_tag_ecc_err_m3_o,
  output wire logic [3:0]         dcu_stb_victim_way_m2_o,
  input  wire logic               stb_dcu_data_req_m0_i,
  input  wire logic               stb_dcu_data_write_m0_i,
  input  wire logic [13:2]        stb_dcu_data_addr_m0_i,
  input  wire logic [3:0]         stb_dcu_data_way_m0_i,
  input  wire logic [3:0]         stb_dcu_data_wstrb_m1_i,
  output wire logic               dcu_stb_data_has_priority_m0_o,
  output wire logic               dcu_stb_data_ack_m1_o,
  input  wire logic [31:0]        stb_dcu_data_write_data_m1_i,
  input  wire logic [6:0]         stb_dcu_data_write_ecc_m1_i,
  output wire logic [31:0]        dcu_stb_data_m2_o,
  output wire logic               dcu_stb_data_ecc_err_m3_o,
  output wire logic               dcu_stb_ecc_fsm_busy_o,
  output wire logic               dcu_stb_ecc_fsm_ev_hazard_o,

  //----------------------------------------------------------------------------
  // BIU Interface
  //----------------------------------------------------------------------------

  input  wire logic               biu_dcu_alloc_tag_req_m0_i,
  input  wire logic               biu_dcu_alloc_data_req_m0_i,
  input  wire logic               biu_dcu_alloc_mbistall_m0_i,
  input  wire logic [311:0]       biu_dcu_alloc_data_m1_i,
  input  wire logic [39:0]        biu_dcu_alloc_enables_m1_i,
  input  wire logic [33:0]        biu_dcu_alloc_tag_m1_i,
  input  wire logic               biu_dcu_ev_tag_req_m0_i,
  input  wire logic               biu_dcu_ev_data_req_m0_i,
  input  wire logic [13:5]        biu_dcu_tag_addr_m0_i,
  input  wire logic [3:0]         biu_dcu_tag_way_m0_i,
  input  wire logic [7:0]         biu_dcu_data_en_m0_i,
  input  wire logic [13:5]        biu_dcu_data_addr_m0_i,
  input  wire logic [3:0]         biu_dcu_data_way_m0_i,
  input  wire logic               biu_dcu_lf_in_progress_i,
  input  wire logic               biu_dcu_maint_ecc_ev_ack_i,
  input  wire logic               biu_dcu_mbistall_tag_wen_m0_i,
  input  wire logic               biu_dcu_mbist_req_i,
  input  wire logic               biu_dcu_mbist_active_i,
  input  wire logic               biu_dcu_mbist_active_mb1_i,
  input  wire logic               biu_dcu_mbist_tag_write_psel_gen_mb0_i,
  input  wire logic               biu_mbist_data_write_psel_gen_mb0_i,
  input  wire logic               biu_dcu_mbist_read_data_pren_mb1_i,
  input  wire logic               biu_dcu_mbist_read_data_psel_mb2_i,
  input  wire logic               biu_dcu_mbist_read_tag_psel_mb2_i,
  input  wire logic               biu_dcu_mbist_pren_mb2_i,
  input  wire logic               biu_dcu_mbist_read_data_psel_mb3_i,
  input  wire logic               biu_dcu_mbist_read_tag_psel_mb3_i,
  input  wire logic               biu_dcu_mbist_pren_mb3_i,
  input  wire logic [1:0]         biu_dcu_mbist_banksel_mb3_i,
  output wire logic               dcu_biu_mbist_func_access_o,
  output wire logic [27:0]        dcu_biu_mbist_ldst_tag_syndr_m3_o,
  output wire logic [23:0]        dcu_biu_mbist_ldst_tag_chk_m3_o,
  output wire logic [25:0]        dcu_biu_mbist_maint_ev_tag_corrctn_m3_o,
  output wire logic [23:0]        dcu_biu_mbist_maint_ev_tag_chk_m3_o,
  output wire logic [23:0]        dcu_biu_mbist_ldst_data_chk_m3_o,
  input  wire logic [1:0]         biu_dcu_mbist_tag_way_mb0_i,
  output wire logic               dcu_biu_alloc_has_priority_m0_o,
  output wire logic               dcu_biu_alloc_ack_m1_o,
  output wire logic               dcu_biu_ev_tag_has_priority_m0_o,
  output wire logic               dcu_biu_ev_data_has_priority_m0_o,
  output wire logic               dcu_biu_ev_tag_ack_m1_o,
  output wire logic               dcu_biu_ev_data_ack_m1_o,
  output wire logic [33:0]        dcu_biu_tag_data_m2_o,
  output wire logic [127:0]       dcu_biu_line_data_m2_o,
  output wire logic [27:0]        dcu_biu_line_syndrome_m2_o,
  output wire logic [27:0]        dcu_biu_line_ecc_m2_o,
  input  wire logic [7:0]         biu_dcu_line_err_m3_i,
  input  wire logic [7:0]         biu_dcu_line_fatal_m3_i,
  input  wire logic [13:5]        biu_dcu_line_addr_m3_i,
  output wire logic [31:10]       dcu_biu_ev_tag_addr_m3_o,
  output wire half_attr_t         dcu_biu_ev_tag_attrs_m3_o,
  output wire logic               dcu_biu_ev_tag_ns_attr_m3_o,
  output wire logic               dcu_biu_ev_tag_valid_m3_o,
  output wire logic               dcu_biu_ev_tag_dirty_m3_o,
  output wire logic               dcu_biu_ev_tag_fatal_m3_o,
  output wire logic               dcu_biu_ecc_pend_o,
  output wire logic               dcu_biu_maint_ecc_ev_req_o,
  output wire logic [26:0]        dcu_biu_maint_ecc_ev_tag_o,
  output wire logic [3:0]         dcu_biu_maint_ecc_ev_way_o,
  output wire logic [13:5]        dcu_biu_maint_ecc_ev_addr_o,
  output wire logic               dcu_biu_ecc_ls_in_prog_o,
  output wire logic               dcu_misc_in_prog_o,
  input  wire logic               biu_dcu_pf_lu_req_m0_i,
  input  wire logic [31:0]        biu_dcu_pf_lu_addr_m0_i,
  output wire logic               dcu_biu_pf_lu_has_priority_m0_o,
  output wire logic               dcu_biu_pf_lu_ack_m1_o,
  output wire logic               dcu_biu_pf_lu_hit_m2_o,
  output wire logic [1:0]         dcu_biu_pf_lu_way_m2_o,
  output wire logic               dcu_biu_pf_lu_ecc_err_m3_o,

  //----------------------------------------------------------------------------
  // SCB/NVIC interface
  //----------------------------------------------------------------------------

  input  wire mscr_t              scb_mscr_i,
  input  wire logic               scb_ecc_en_i,
  input  wire logic               nvic_aircr_bfhfnmins_cse_i,


  //----------------------------------------------------------------------------
  // RAM Interface
  //----------------------------------------------------------------------------

  input  wire logic [33:0]        ram_dcu_tag_rdata0_i,
  input  wire logic [33:0]        ram_dcu_tag_rdata1_i,
  input  wire logic [33:0]        ram_dcu_tag_rdata2_i,
  input  wire logic [33:0]        ram_dcu_tag_rdata3_i,
  input  wire logic [38:0]        ram_dcu_data_rdata0_i,
  input  wire logic [38:0]        ram_dcu_data_rdata1_i,
  input  wire logic [38:0]        ram_dcu_data_rdata2_i,
  input  wire logic [38:0]        ram_dcu_data_rdata3_i,
  output wire logic [3:0]         dcu_ram_tag_en_o,
  output wire logic               dcu_ram_tag_wr_o,
  output wire logic [33:0]        dcu_ram_tag_wdata_o,
  output wire logic [8:0]         dcu_ram_tag_addr_o,
  output wire logic [3:0]         dcu_ram_data_en_o,
  output wire logic               dcu_ram_data_wr_o,
  output wire logic [4:0]         dcu_ram_data_strb0_o,
  output wire logic [4:0]         dcu_ram_data_strb1_o,
  output wire logic [4:0]         dcu_ram_data_strb2_o,
  output wire logic [4:0]         dcu_ram_data_strb3_o,
  output wire logic [11:0]        dcu_ram_data_addr0_o,
  output wire logic [11:0]        dcu_ram_data_addr1_o,
  output wire logic [11:0]        dcu_ram_data_addr2_o,
  output wire logic [11:0]        dcu_ram_data_addr3_o,
  output wire logic [38:0]        dcu_ram_data_wdata0_o,
  output wire logic [38:0]        dcu_ram_data_wdata1_o,
  output wire logic [38:0]        dcu_ram_data_wdata2_o,
  output wire logic [38:0]        dcu_ram_data_wdata3_o,

  //----------------------------------------------------------------------------
  // CPC Interface
  //----------------------------------------------------------------------------

  input  wire logic               cpc_dcu_invalidate_cache_i,
  input  wire logic               cpc_rrunning_i,
  output wire logic               dcu_cpc_rpwrreq_o,
  output wire logic               dcu_cpc_adclk_en_o,
  output wire logic               dcu_dc_inaccessible_o,
  output wire logic               dcu_auto_inval_in_prog_o,

  //----------------------------------------------------------------------------
  // Misc Signals
  //----------------------------------------------------------------------------

  input  wire logic               lsu_dcu_ch_mintf_quiet_i,
  output wire logic               dcu_lsu_drain_stb_o,

  //----------------------------------------------------------------------------
  // PMU events
  //----------------------------------------------------------------------------

  output wire logic               dcu_lsu_ecc_err_o,
  output wire logic               dcu_lsu_ecc_err_fatal_o,
  output wire logic               dcu_lsu_ecc_err_dcache_o,
  output wire logic               dcu_lsu_ecc_err_fatal_dcache_o,

  //----------------------------------------------------------------------------
  // IPPB Interface
  //----------------------------------------------------------------------------

  input  wire ippb_req_t          lsu_dcu_ippb_req_i,
  output wire ippb_resp_t         dcu_lsu_ippb_resp_o,

  //----------------------------------------------------------------------------
  // RAS Error Interface
  //----------------------------------------------------------------------------

  output wire ras_err_t           dcu_lsu_ras_err_o,

  //----------------------------------------------------------------------------
  // Error Bank Registers
  //----------------------------------------------------------------------------

  output wire logic               dcu_biu_debr0_val_o,
  output wire logic               dcu_biu_debr1_val_o,
  output wire logic [1:0]         dcu_biu_debr0_way_o,
  output wire logic [1:0]         dcu_biu_debr1_way_o,
  output wire logic [13:5]        dcu_biu_debr0_addr_o,
  output wire logic [13:5]        dcu_biu_debr1_addr_o,

  //----------------------------------------------------------------------------
  // MIU Interface
  //----------------------------------------------------------------------------

  input  wire logic [21:0]        miu_addr_i,
  input  wire logic [38:0]        miu_wdata_i
 );

  //assign dcu_lsu_load_data1_m2_o = '0;
  //assign dcu_lsu_ecc_err1_m2_o   = 1'b0;

  generate
    if (DCACHE != 0) begin : gen_dcu_included
  wire     [31:5]  maint_tag_addr_m0;
  wire             maint_tag_priority_m0;
  wire             maint_tag_ack_m1;

  wire             maint_tag_valid_m3;
  wire             maint_tag_dirty_m3;
  wire             maint_tag_ns_attr_m3;

  wire             lsu_dcu_addr_hazard_m1;

  wire             dcu_stb_force_priority;


`ifdef ARM_ASSERT_ON
  //Start automatically generated svas here
  generate
    if( DCACHE!=0 ) begin : gen_auto_sva0
      wire [3:0] zsva_auto_x_check0 = {
        ( gen_dcu_included.dca_lr_wr ),


    end
  endgenerate

  endgenerate
  //End automatically generated svas here
`endif

endmodule // yamin_dcu

`define ARM_UNDEFINE
`include "sva_macros.svh"
`undef ARM_UNDEFINE



