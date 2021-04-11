`define SVA_CLK posedge clk
`define SVA_DIS !csysreset_n
`include "sva_macros.svh"

`ifdef ARM_FCOV_ON
`ifndef ARM_L1_COV_TESTS
`define ARM_L1_COV_TESTS 1
`endif
`endif

module yamin_stb import yamin_pkg::*; import yamin_stb_pkg::*, yamin_ecc_pkg::*; #(
  `include "yamin_decl.sv"
)
(

  //----------------------------------------------------------------------------
  // Clock and Reset
  //----------------------------------------------------------------------------
  input  wire logic               clk,
  input  wire logic               dclk,
  input  wire logic               csysreset_n,

  //----------------------------------------------------------------------------
  // LSU Interface
  //----------------------------------------------------------------------------
  output wire logic [3:0]         stb_lsu_slots_valid_o,
  output wire logic [3:0]         stb_lsu_slots_dev_o,
  output wire logic [3:0]         stb_lsu_slots_ch_o,
  input  wire logic               lsu_stb_drain_entire_stb_i,
  input  wire logic               lsu_watchcat_fire_i,
  output wire logic               stb_lsu_watchcat_two_o,
  output wire logic               stb_lsu_watchcat_three_o,
  output wire logic               stb_lsu_watchcat_triple_o,
  input  wire logic               lsu_stb_store_de_i,
  input  wire logic               lsu_stb_store_ls1_i,
  input  wire logic               lsu_stb_kill_ls2_i,
  input  wire logic               lsu_stb_leaving_ls2_i,
  input  wire logic               lsu_stb_valid_ls2_i,
  input  wire logic               lsu_stb_first_cycle_ls2_i,
  input  wire logic               lsu_stb_load_ls2_i,
  input  wire logic               lsu_stb_store_ls2_i,
  output wire logic               stb_lsu_ack_ls2_o,
  input  wire logic [31:0]        lsu_stb_addr_ls2_i,
  input  wire attr_t              lsu_stb_attrs_ls2_i,
  input  wire logic               lsu_stb_is_dev_est_ls2_i,
  input  wire logic               lsu_stb_ns_attr_ls2_i,
  input  wire logic               lsu_stb_stl_ls2_i,
  input  wire logic [2:0]         lsu_stb_stl_wids_ls2_i,
  input  wire logic               lsu_stb_dbg_ls2_i,
  input  wire logic               lsu_stb_priv_ls2_i,
  input  wire logic               lsu_stb_sh_excl_est_ls2_i,
  input  wire size_t              lsu_stb_size_ls2_i,
  input  wire logic [3:0]         lsu_stb_store_wstrb_ls2_i,
  output wire logic [3:0]         stb_lsu_hit_ls2_o,
  output wire logic [31:0]        stb_lsu_data_ls2_o,
  input  wire logic [31:0]        lsu_stb_store_data_ls2_i,
  output wire logic               stb_lsu_dbg_str_imp_bus_fault_o,

  //----------------------------------------------------------------------------
  // DCU Interface
  //----------------------------------------------------------------------------
  input  wire logic               dcu_stb_drain_entire_stb_i,
  input  wire logic               dcu_stb_ecc_fsm_ev_hazard_i,
  output wire logic               stb_dcu_ch_drained_o,
  output wire logic               stb_dcu_tag_req_m0_o,
  output wire logic               stb_dcu_tag_write_m0_o,
  output wire logic [3:0]         stb_dcu_tag_way_m0_o,
  output wire logic [31:5]        stb_dcu_tag_addr_m0_o,
  output wire half_attr_t         stb_dcu_tag_write_attrs_m0_o,
  output wire logic               stb_dcu_tag_write_ns_attr_m0_o,
  input  wire logic               dcu_stb_tag_has_priority_m0_i,
  input  wire logic               dcu_stb_tag_ack_m1_i,
  input  wire logic [3:0]         dcu_stb_tag_hit_m2_i,
  input  wire logic               dcu_stb_tag_ecc_err_m3_i,
  input  wire logic [3:0]         dcu_stb_victim_way_m2_i,
  output wire logic               stb_dcu_data_req_m0_o,
  output wire logic               stb_dcu_data_write_m0_o,
  output wire logic [13:2]        stb_dcu_data_addr_m0_o,
  output wire logic [3:0]         stb_dcu_data_way_m0_o,
  output wire logic [3:0]         stb_dcu_data_wstrb_m1_o,
  input  wire logic               dcu_stb_data_has_priority_m0_i,
  input  wire logic               dcu_stb_data_ack_m1_i,
  output wire logic [31:0]        stb_dcu_data_write_data_m1_o,
  output wire logic [6:0]         stb_dcu_data_write_ecc_m1_o,
  input  wire logic [31:0]        dcu_stb_data_m2_i,
  input  wire logic               dcu_stb_data_ecc_err_m3_i,
  input  wire logic               dcu_stb_ecc_fsm_busy_i,
  input  wire logic               dcu_dc_inaccessible_i,

  //----------------------------------------------------------------------------
  // BIU Interface
  //----------------------------------------------------------------------------
  output wire logic [3:0]         stb_biu_slots_valid_o,
  output wire logic [31:0]        stb_biu_slot0_addr_o,
  output wire logic [31:0]        stb_biu_slot1_addr_o,
  output wire logic [31:0]        stb_biu_slot2_addr_o,
  output wire logic [31:0]        stb_biu_slot3_addr_o,
  output wire logic [1:0]         stb_biu_slot0_way_o,
  output wire logic [1:0]         stb_biu_slot1_way_o,
  output wire logic [1:0]         stb_biu_slot2_way_o,
  output wire logic [1:0]         stb_biu_slot3_way_o,
  output wire attr_t              stb_biu_slot0_attrs_o,
  output wire attr_t              stb_biu_slot1_attrs_o,
  output wire attr_t              stb_biu_slot2_attrs_o,
  output wire attr_t              stb_biu_slot3_attrs_o,
  output wire logic               stb_biu_slot0_ns_attr_o,
  output wire logic               stb_biu_slot1_ns_attr_o,
  output wire logic               stb_biu_slot2_ns_attr_o,
  output wire logic               stb_biu_slot3_ns_attr_o,
  input  wire logic [3:0]         biu_stb_lf_hazard_i,
  input  wire logic [3:0]         biu_stb_lf_hazard_abort_i,
  input  wire logic [3:0]         biu_stb_lf_hazard_alloc_i,
  input  wire logic [1:0]         biu_stb_lf_hazard_way_i,
  input  wire logic [3:0]         biu_stb_lf_can_merge_i,
  input  wire logic [3:0]         biu_stb_ev_hazard_i,
  output wire logic [3:0]         stb_biu_lf_req_o,
  output wire logic [1:0]         stb_biu_lf_earliest_slot_o,
  output wire logic [3:0]         stb_biu_lf_merge_req_o,
  output wire logic               stb_biu_lf_merge_update_dirty_o,
  output wire logic [31:0]        stb_biu_lf_merge_data_o,
  output wire logic [3:0]         stb_biu_lf_merge_wstrb_o,
  output wire logic               stb_biu_write_req_o,
  output wire logic [31:0]        stb_biu_write_data_o,
  output wire logic [3:0]         stb_biu_write_wstrb_o,
  output wire logic [3:0]         stb_biu_write_slot_o,
  output wire logic               stb_biu_write_priv_o,
  output wire attr_t              stb_biu_write_attrs_o,
  output wire logic               stb_biu_write_ns_attr_o,
  output wire size_t              stb_biu_write_size_o,
  output wire logic               stb_biu_write_strex_o,
  output wire logic               stb_biu_write_dbg_o,
  output wire logic               stb_biu_write_sameline_o,
  input  wire logic               biu_stb_write_ack_i,
  input  wire logic [3:0]         biu_stb_valid_wids_i,
  input  wire logic               biu_stb_no_write_alloc_mode_i,
  output wire logic               stb_biu_cancel_no_write_alloc_o,
  input  wire logic               biu_stb_waw_hazard_ls2_i,
  output wire logic               stb_biu_stl_wait_wids_o,
  output wire logic               stb_biu_slot_in_m1_o,

  //----------------------------------------------------------------------------
  // SCB Interface
  //----------------------------------------------------------------------------

  input  wire mscr_t              scb_mscr_i,
  input  wire logic               scb_ecc_en_i,
  input  wire actlr_t             scb_actlr_s_i,
  input  wire actlr_t             scb_actlr_ns_i,

  //----------------------------------------------------------------------------
  // PMU Events
  //----------------------------------------------------------------------------

  output wire logic               stb_lsu_nwamode_o,

  //----------------------------------------------------------------------------
  // MBIST Interface - For STB ECC generation logic
  //----------------------------------------------------------------------------
  input  wire logic               biu_mbist_data_write_psel_gen_mb0_i,
  input  wire logic [21:0]        miu_addr_i,
  input  wire logic [3:0]         biu_dcu_data_way_m0_i,
  input  wire logic [311:0]       biu_dcu_alloc_data_m1_i  // Only data fields used [70:39] and [31:0]
);

  //----------------------------------------------------------------------------
  // Registers
  //----------------------------------------------------------------------------

  // Reset signal for registers that are only reset when RAR is set
  wire rar_csysreset_n;
  generate
    if (RAR == 1) begin : gen_rar_enabled
      assign rar_csysreset_n = csysreset_n;
    end else begin : gen_no_rar_enabled
      assign rar_csysreset_n = 1'b1;
    end
  endgenerate

  reg [3:0]   slots_new_store_ls2;     // new request and write strobes

  wire        slot3_mergeable;

  wire        slot0_ev_hazard;
  wire        slot1_ev_hazard;
  wire        slot2_ev_hazard;


  assign slots_cacheable = {attrs_are_ch(slot3_attrs),
                            attrs_are_ch(slot2_attrs),
                            attrs_are_ch(slot1_attrs),
                            attrs_are_ch(slot0_attrs)};

`endif

endmodule

`define ARM_UNDEFINE
`include "sva_macros.svh"
`undef ARM_UNDEFINE




