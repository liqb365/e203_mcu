/*
 Copyright 2018-2020 Nuclei System Technology, Inc.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

//=====================================================================
//
// Designer   : LZB
//
// Description:
//  The Module to realize a simple NICE core
//
// ====================================================================
`include "e203_defines.v"

`ifdef E203_HAS_NICE_MATRIX//{

module e203_subsys_nice_core (

    // System
    input                         	nice_clk             ,
    input                         	nice_rst_n	          ,
    output                        	nice_active	      ,
    output                        	nice_mem_holdup	  ,

	// Control cmd_req
    input                         	nice_req_valid       ,
    output                        	nice_req_ready       ,
    input  [`E203_XLEN-1:0]       	nice_req_inst        ,
    input  [`E203_XLEN-1:0]       	nice_req_rs1         ,
    input  [`E203_XLEN-1:0]       	nice_req_rs2         ,

    // Control cmd_rsp
    output                        	nice_rsp_valid       ,
    input                         	nice_rsp_ready       ,
    output [`E203_XLEN-1:0]       	nice_rsp_rdat        ,
    output                        	nice_rsp_err    	  ,
//  output                        	nice_rsp_err_irq	  ,

	// Memory lsu_req
    output                        	nice_icb_cmd_valid   ,
    input                         	nice_icb_cmd_ready   ,
    output [`E203_ADDR_SIZE-1:0]  	nice_icb_cmd_addr    ,
    output                        	nice_icb_cmd_read    ,
    output [`E203_XLEN-1:0]       	nice_icb_cmd_wdata   ,
//  output [`E203_XLEN_MW-1:0]  	nice_icb_cmd_wmask   ,  //
    output [1:0]                  	nice_icb_cmd_size    ,

    // Memory lsu_rsp
    input                         	nice_icb_rsp_valid   ,
    output                        	nice_icb_rsp_ready   ,
    input  [`E203_XLEN-1:0]       	nice_icb_rsp_rdata   ,
    input                         	nice_icb_rsp_err

);





   	localparam ROWBUF_DP 	= 256;
   	localparam ROWBUF_IDX_W = 8;
   	localparam ROW_IDX_W 	= 8;







   	////////////////////////////////////////////////////////////
   	// decode
   	////////////////////////////////////////////////////////////
   	wire [6:0] opcode      = {7{nice_req_valid}} & nice_req_inst[6:0];
   	wire [2:0] rv32_func3  = {3{nice_req_valid}} & nice_req_inst[14:12];
   	wire [6:0] rv32_func7  = {7{nice_req_valid}} & nice_req_inst[31:25];

//  wire opcode_custom0 = (opcode == 7'b0001011);
//  wire opcode_custom1 = (opcode == 7'b0101011);
//  wire opcode_custom2 = (opcode == 7'b1011011);
   	wire opcode_custom3 = (opcode == 7'b1111011);

   	wire rv32_func3_000 = (rv32_func3 == 3'b000);
   	wire rv32_func3_001 = (rv32_func3 == 3'b001);
   	wire rv32_func3_010 = (rv32_func3 == 3'b010);
   	wire rv32_func3_011 = (rv32_func3 == 3'b011);
   	wire rv32_func3_100 = (rv32_func3 == 3'b100);
   	wire rv32_func3_101 = (rv32_func3 == 3'b101);
   	wire rv32_func3_110 = (rv32_func3 == 3'b110);
   	wire rv32_func3_111 = (rv32_func3 == 3'b111);

   	wire rv32_func7_0000000 = (rv32_func7 == 7'b0000000);
   	wire rv32_func7_0000001 = (rv32_func7 == 7'b0000001);
   	wire rv32_func7_0000010 = (rv32_func7 == 7'b0000010);
   	wire rv32_func7_0000011 = (rv32_func7 == 7'b0000011);
   	wire rv32_func7_0000100 = (rv32_func7 == 7'b0000100);
   	wire rv32_func7_0000101 = (rv32_func7 == 7'b0000101);
   	wire rv32_func7_0000110 = (rv32_func7 == 7'b0000110);
   	wire rv32_func7_0000111 = (rv32_func7 == 7'b0000111);

   	////////////////////////////////////////////////////////////
   	// custom3:
   	// Supported format: only R type here
   	// Supported instr:
   	//  1. custom3 lmatrix1: load data(in memory) to row_buf
   	//     lmatrix1 (a1)
   	//     .insn r opcode, func3, func7, rd, rs1, rs2
   	//  2. custom3 smatrix1: store data(in row_buf) to memory
   	//     smatrix1 (a1)
   	//     .insn r opcode, func3, func7, rd, rs1, rs2
   	////////////////////////////////////////////////////////////
   	//wire custom3_lmatrix1 	= opcode_custom3 & rv32_func3_010 & rv32_func7_0000001;
   	//wire custom3_smatrix1   = opcode_custom3 & rv32_func3_010 & rv32_func7_0000010;
   	wire custom3_lmatrix1 		= opcode_custom3 & rv32_func3_111 & rv32_func7_0000000;
   	wire custom3_smatrix1   	= opcode_custom3 & rv32_func3_111 & rv32_func7_0000001;
   	wire custom3_lmatrix2 		= opcode_custom3 & rv32_func3_111 & rv32_func7_0000010;
   	wire custom3_smatrix2   	= opcode_custom3 & rv32_func3_111 & rv32_func7_0000011;
   	wire custom3_sresultmatrix  = opcode_custom3 & rv32_func3_111 & rv32_func7_0000100;

   	////////////////////////////////////////////////////////////
   	//  multi-cyc op
   	////////////////////////////////////////////////////////////
   	wire custom_multi_cyc_op = 	custom3_lmatrix1 	|
								custom3_smatrix1	|
								custom3_lmatrix2 	|
                                custom3_smatrix2	|
                                custom3_sresultmatrix;
   	// need access memory
   	wire custom_mem_op = 	custom3_lmatrix1 	|
							custom3_smatrix1	|
							custom3_lmatrix2 	|
                           	custom3_smatrix2	|
                           	custom3_sresultmatrix;











   	////////////////////////////////////////////////////////////
   	// NICE FSM
   	////////////////////////////////////////////////////////////
   	parameter NICE_FSM_WIDTH 	= 3;

	parameter IDLE     			= 3'd0;
   	parameter LMATRIX1     		= 3'd1;
   	parameter SMATRIX1     		= 3'd2;
   	parameter LMATRIX2     		= 3'd3;
   	parameter SMATRIX2     		= 3'd4;
   	parameter SRESULTMATRIX     = 3'd5;
   	parameter ROWSUM   			= 3'd6;

   	wire [NICE_FSM_WIDTH-1:0] 		state_r;
   	wire [NICE_FSM_WIDTH-1:0] 		nxt_state;

   	wire [NICE_FSM_WIDTH-1:0] 		state_idle_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_lmatrix1_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_smatrix1_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_lmatrix2_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_smatrix2_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_sresultmatrix_nxt;

   	wire 							nice_req_hsked;
   	wire 							nice_rsp_hsked;
   	wire 							nice_icb_rsp_hsked;

   	wire 							illgel_instr = ~(custom_multi_cyc_op);

   	wire 							state_idle_exit_ena;
   	wire 							state_lmatrix1_exit_ena;
   	wire 							state_smatrix1_exit_ena;
   	wire 							state_lmatrix2_exit_ena;
   	wire 							state_smatrix2_exit_ena;
   	wire 							state_sresultmatrix_exit_ena;
   	wire 							state_ena;

   	wire 							state_is_idle   		= (state_r == IDLE);
   	wire 							state_is_lmatrix1   	= (state_r == LMATRIX1);
   	wire 							state_is_smatrix1   	= (state_r == SMATRIX1);
   	wire 							state_is_lmatrix2   	= (state_r == LMATRIX2);
   	wire 							state_is_smatrix2   	= (state_r == SMATRIX2);
   	wire 							state_is_sresultmatrix  = (state_r == SRESULTMATRIX);

	//------------------------------------------------------------------------------------
   	assign state_idle_exit_ena 	= state_is_idle & nice_req_hsked & ~illgel_instr;
   	assign state_idle_nxt 		= custom3_lmatrix1    	? LMATRIX1   	:
                                  custom3_smatrix1    	? SMATRIX1   	:
                                  custom3_lmatrix2    	? LMATRIX2   	:
                                  custom3_smatrix2    	? SMATRIX2   	:
                                  custom3_sresultmatrix ? SRESULTMATRIX :
			    							   		  	  IDLE;

	//------------------------------------------------------------------------------------
   	assign state_lmatrix1_exit_ena 	= state_is_lmatrix1 & lmatrix1_icb_rsp_hsked_last;
   	assign state_lmatrix1_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_smatrix1_exit_ena 	= state_is_smatrix1 & smatrix1_icb_rsp_hsked_last;
   	assign state_smatrix1_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_lmatrix2_exit_ena 	= state_is_lmatrix2 & lmatrix2_icb_rsp_hsked_last;
   	assign state_lmatrix2_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_smatrix2_exit_ena 	= state_is_smatrix2 & smatrix2_icb_rsp_hsked_last;
   	assign state_smatrix2_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_sresultmatrix_exit_ena = state_is_sresultmatrix & sresultmatrix_icb_rsp_hsked_last;
   	assign state_sresultmatrix_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign nxt_state =  ({NICE_FSM_WIDTH{state_idle_exit_ena   }} & state_idle_nxt   ) 	|
						({NICE_FSM_WIDTH{state_lmatrix1_exit_ena   }} & state_lmatrix1_nxt   ) 	|
						({NICE_FSM_WIDTH{state_smatrix1_exit_ena   }} & state_smatrix1_nxt   )	|
						({NICE_FSM_WIDTH{state_lmatrix2_exit_ena   }} & state_lmatrix2_nxt   ) 	|
						({NICE_FSM_WIDTH{state_smatrix2_exit_ena   }} & state_smatrix2_nxt   )	|
						({NICE_FSM_WIDTH{state_sresultmatrix_exit_ena   }} & state_sresultmatrix_nxt   );

   	assign state_ena =	state_idle_exit_ena 		|
						state_lmatrix1_exit_ena		|
						state_smatrix1_exit_ena		|
						state_lmatrix2_exit_ena		|
						state_smatrix2_exit_ena		|
						state_sresultmatrix_exit_ena;

   	sirv_gnrl_dfflr #(NICE_FSM_WIDTH)   state_dfflr (state_ena, nxt_state, state_r, nice_clk, nice_rst_n);













   	////////////////////////////////////////////////////////////
   	// instr EXU
   	////////////////////////////////////////////////////////////
   	reg [ROW_IDX_W-1:0] clonum = 3'b0;

	always @(posedge nice_clk or negedge nice_rst_n)
	begin
		if (nice_req_hsked == 1'b1)
			clonum = nice_req_rs2;
	end











   	//////////// 1. custom3_lmatrix1
   	wire [ROWBUF_IDX_W-1:0] 		lmatrix1_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		lmatrix1_cnt_nxt;
   	wire 							lmatrix1_cnt_clr;
   	wire 							lmatrix1_cnt_incr;
   	wire 							lmatrix1_cnt_ena;
   	wire 							lmatrix1_cnt_last;

	assign lmatrix1_cnt_last 			= (lmatrix1_cnt_r == clonum);
   	assign lmatrix1_cnt_clr 			= custom3_lmatrix1 & nice_req_hsked;
   	assign lmatrix1_cnt_incr 			= lmatrix1_icb_rsp_hsked & ~lmatrix1_cnt_last;
   	assign lmatrix1_cnt_ena 			= lmatrix1_cnt_clr | lmatrix1_cnt_incr;
   	assign lmatrix1_cnt_nxt 			=   ({ROWBUF_IDX_W{lmatrix1_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}) 	|
										({ROWBUF_IDX_W{lmatrix1_cnt_incr}} & (lmatrix1_cnt_r + 1'b1));

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) lmatrix1_cnt_dfflr (lmatrix1_cnt_ena, lmatrix1_cnt_nxt, lmatrix1_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in LBUF.
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_lmatrix1;

   	assign nice_rsp_valid_lmatrix1 = state_is_lmatrix1 & lmatrix1_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when lmatrix1_cnt_r is not full in LBUF.
	// This signal decide that if nice_icb_cmd_valid should be
	// pulled up.
   	wire nice_icb_cmd_valid_lmatrix1;

   	assign nice_icb_cmd_valid_lmatrix1 = (state_is_lmatrix1 & (lmatrix1_cnt_r < clonum));

	// lmatrix1_icb_rsp_hsked decide two things:
	// 1.If lmatrix1_cnt_incr should be pulled up.
	// 2.If lmatrix1_wr should be pulled up.
   	wire lmatrix1_icb_rsp_hsked;
	wire lmatrix1_icb_rsp_hsked_last;

   	assign lmatrix1_icb_rsp_hsked 		= 	state_is_lmatrix1 		&
										nice_icb_rsp_hsked;

   	assign lmatrix1_icb_rsp_hsked_last 	= 	lmatrix1_icb_rsp_hsked &
										lmatrix1_cnt_last;















   	//////////// 2. custom3_smatrix1
   	wire [ROWBUF_IDX_W-1:0] 		smatrix1_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		smatrix1_cmd_cnt_nxt;
   	wire 							smatrix1_cmd_cnt_clr;
   	wire 							smatrix1_cmd_cnt_incr;
   	wire 							smatrix1_cmd_cnt_ena;
   	wire 							smatrix1_cmd_cnt_last;

   	assign smatrix1_cmd_cnt_last 		= (smatrix1_cmd_cnt_r == clonum);
   	assign smatrix1_cmd_cnt_clr 		= smatrix1_icb_rsp_hsked_last;
   	assign smatrix1_cmd_cnt_incr 		= smatrix1_icb_cmd_hsked & ~smatrix1_cmd_cnt_last;
   	assign smatrix1_cmd_cnt_ena 		= smatrix1_cmd_cnt_clr | smatrix1_cmd_cnt_incr;
   	assign smatrix1_cmd_cnt_nxt 		=   ( {ROWBUF_IDX_W{smatrix1_cmd_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}    )		|
										( {ROWBUF_IDX_W{smatrix1_cmd_cnt_incr}} & (smatrix1_cmd_cnt_r + 1'b1) );

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) smatrix1_cmd_cnt_dfflr (smatrix1_cmd_cnt_ena, smatrix1_cmd_cnt_nxt, smatrix1_cmd_cnt_r, nice_clk, nice_rst_n);

   	wire [ROWBUF_IDX_W-1:0] 		smatrix1_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		smatrix1_cnt_nxt;
   	wire 							smatrix1_cnt_clr;
   	wire 							smatrix1_cnt_incr;
   	wire 							smatrix1_cnt_ena;
   	wire 							smatrix1_cnt_last;

   	assign smatrix1_cnt_last 			= (smatrix1_cnt_r == clonum);
  //assign smatrix1_cnt_clr 			= custom3_smatrix1 & nice_req_hsked;
   	assign smatrix1_cnt_clr 			= smatrix1_icb_rsp_hsked_last;
   	assign smatrix1_cnt_incr 			= smatrix1_icb_rsp_hsked & ~smatrix1_cnt_last;
   	assign smatrix1_cnt_ena 			= smatrix1_cnt_clr | smatrix1_cnt_incr;
   	assign smatrix1_cnt_nxt 			=   ( {ROWBUF_IDX_W{smatrix1_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}	)	|
										( {ROWBUF_IDX_W{smatrix1_cnt_incr}} & (smatrix1_cnt_r + 1'b1) 	);

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) smatrix1_cnt_dfflr (smatrix1_cnt_ena, smatrix1_cnt_nxt, smatrix1_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in SBUF
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_smatrix1;

   	assign nice_rsp_valid_smatrix1 = state_is_smatrix1 & smatrix1_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when smatrix1_cmd_cnt_r is not full in SBUF
	// This signal decide that if nice_icb_cmd_valid should be pulled up.
   	wire nice_icb_cmd_valid_smatrix1;

   	assign nice_icb_cmd_valid_smatrix1 = ( state_is_smatrix1 				&
									  (smatrix1_cmd_cnt_r <= clonum) 	&
									  (smatrix1_cnt_r != clonum)	);

	// This signal decide if smatrix1_cmd_cnt_incr should be pulled up.
	wire smatrix1_icb_cmd_hsked;

   	assign smatrix1_icb_cmd_hsked = (state_is_smatrix1 | (state_is_idle & custom3_smatrix1)) & nice_icb_cmd_hsked;

	// This signal decide if smatrix1_cnt_incr should be pulled up.
   	wire smatrix1_icb_rsp_hsked;
	wire smatrix1_icb_rsp_hsked_last;

   	assign smatrix1_icb_rsp_hsked 		= 	state_is_smatrix1 &
										nice_icb_rsp_hsked;

   	assign smatrix1_icb_rsp_hsked_last 	= 	smatrix1_icb_rsp_hsked &
										smatrix1_cnt_last;
















   	//////////// 3. custom3_lmatrix2
   	wire [ROWBUF_IDX_W-1:0] 		lmatrix2_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		lmatrix2_cnt_nxt;
   	wire 							lmatrix2_cnt_clr;
   	wire 							lmatrix2_cnt_incr;
   	wire 							lmatrix2_cnt_ena;
   	wire 							lmatrix2_cnt_last;

	assign lmatrix2_cnt_last 			= (lmatrix2_cnt_r == clonum);
   	assign lmatrix2_cnt_clr 			= custom3_lmatrix2 & nice_req_hsked;
   	assign lmatrix2_cnt_incr 			= lmatrix2_icb_rsp_hsked & ~lmatrix2_cnt_last;
   	assign lmatrix2_cnt_ena 			= lmatrix2_cnt_clr | lmatrix2_cnt_incr;
   	assign lmatrix2_cnt_nxt 			=   ({ROWBUF_IDX_W{lmatrix2_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}) 	|
										({ROWBUF_IDX_W{lmatrix2_cnt_incr}} & (lmatrix2_cnt_r + 1'b1));

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) lmatrix2_cnt_dfflr (lmatrix2_cnt_ena, lmatrix2_cnt_nxt, lmatrix2_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in LBUF.
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_lmatrix2;

   	assign nice_rsp_valid_lmatrix2 = state_is_lmatrix2 & lmatrix2_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when lmatrix2_cnt_r is not full in LBUF.
	// This signal decide that if nice_icb_cmd_valid should be
	// pulled up.
   	wire nice_icb_cmd_valid_lmatrix2;

   	assign nice_icb_cmd_valid_lmatrix2 = (state_is_lmatrix2 & (lmatrix2_cnt_r < clonum));

	// lmatrix2_icb_rsp_hsked decide two things:
	// 1.If lmatrix2_cnt_incr should be pulled up.
	// 2.If lmatrix2_wr should be pulled up.
   	wire lmatrix2_icb_rsp_hsked;
	wire lmatrix2_icb_rsp_hsked_last;

   	assign lmatrix2_icb_rsp_hsked 		= 	state_is_lmatrix2 		&
										nice_icb_rsp_hsked;

   	assign lmatrix2_icb_rsp_hsked_last 	= 	lmatrix2_icb_rsp_hsked &
										lmatrix2_cnt_last;

















   	//////////// 4. custom3_smatrix2
   	wire [ROWBUF_IDX_W-1:0] 		smatrix2_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		smatrix2_cmd_cnt_nxt;
   	wire 							smatrix2_cmd_cnt_clr;
   	wire 							smatrix2_cmd_cnt_incr;
   	wire 							smatrix2_cmd_cnt_ena;
   	wire 							smatrix2_cmd_cnt_last;

   	assign smatrix2_cmd_cnt_last 		= (smatrix2_cmd_cnt_r == clonum);
   	assign smatrix2_cmd_cnt_clr 		= smatrix2_icb_rsp_hsked_last;
   	assign smatrix2_cmd_cnt_incr 		= smatrix2_icb_cmd_hsked & ~smatrix2_cmd_cnt_last;
   	assign smatrix2_cmd_cnt_ena 		= smatrix2_cmd_cnt_clr | smatrix2_cmd_cnt_incr;
   	assign smatrix2_cmd_cnt_nxt 		=   ( {ROWBUF_IDX_W{smatrix2_cmd_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}    )		|
											( {ROWBUF_IDX_W{smatrix2_cmd_cnt_incr}} & (smatrix2_cmd_cnt_r + 1'b1) );

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) smatrix2_cmd_cnt_dfflr (smatrix2_cmd_cnt_ena, smatrix2_cmd_cnt_nxt, smatrix2_cmd_cnt_r, nice_clk, nice_rst_n);

   	wire [ROWBUF_IDX_W-1:0] 		smatrix2_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		smatrix2_cnt_nxt;
   	wire 							smatrix2_cnt_clr;
   	wire 							smatrix2_cnt_incr;
   	wire 							smatrix2_cnt_ena;
   	wire 							smatrix2_cnt_last;

   	assign smatrix2_cnt_last 			= (smatrix2_cnt_r == clonum);
   	assign smatrix2_cnt_clr 			= smatrix2_icb_rsp_hsked_last;
   	assign smatrix2_cnt_incr 			= smatrix2_icb_rsp_hsked & ~smatrix2_cnt_last;
   	assign smatrix2_cnt_ena 			= smatrix2_cnt_clr | smatrix2_cnt_incr;
   	assign smatrix2_cnt_nxt 			=   ( {ROWBUF_IDX_W{smatrix2_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}	)	|
											( {ROWBUF_IDX_W{smatrix2_cnt_incr}} & (smatrix2_cnt_r + 1'b1) 	);

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) smatrix2_cnt_dfflr (smatrix2_cnt_ena, smatrix2_cnt_nxt, smatrix2_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in SBUF
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_smatrix2;

   	assign nice_rsp_valid_smatrix2 = state_is_smatrix2 & smatrix2_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when smatrix2_cmd_cnt_r is not full in SBUF
	// This signal decide that if nice_icb_cmd_valid should be pulled up.
   	wire nice_icb_cmd_valid_smatrix2;

   	assign nice_icb_cmd_valid_smatrix2 = ( state_is_smatrix2 				&
									  (smatrix2_cmd_cnt_r <= clonum) 	&
									  (smatrix2_cnt_r != clonum)	);

	// This signal decide if smatrix2_cmd_cnt_incr should be pulled up.
	wire smatrix2_icb_cmd_hsked;

   	assign smatrix2_icb_cmd_hsked = (state_is_smatrix2 | (state_is_idle & custom3_smatrix2)) & nice_icb_cmd_hsked;

	// This signal decide if smatrix2_cnt_incr should be pulled up.
   	wire smatrix2_icb_rsp_hsked;

   	assign smatrix2_icb_rsp_hsked = state_is_smatrix2 & nice_icb_rsp_hsked;

	wire smatrix2_icb_rsp_hsked_last;

   	assign smatrix2_icb_rsp_hsked_last = smatrix2_icb_rsp_hsked & smatrix2_cnt_last;















   	//////////// 5. custom3_sresultmatrix
   	wire [ROWBUF_IDX_W-1:0] 		sresultmatrix_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		sresultmatrix_cmd_cnt_nxt;
   	wire 							sresultmatrix_cmd_cnt_clr;
   	wire 							sresultmatrix_cmd_cnt_incr;
   	wire 							sresultmatrix_cmd_cnt_ena;
   	wire 							sresultmatrix_cmd_cnt_last;

   	assign sresultmatrix_cmd_cnt_last 		= (sresultmatrix_cmd_cnt_r == clonum);
   	assign sresultmatrix_cmd_cnt_clr 		= sresultmatrix_icb_rsp_hsked_last;
   	assign sresultmatrix_cmd_cnt_incr 		= sresultmatrix_icb_cmd_hsked & ~sresultmatrix_cmd_cnt_last;
   	assign sresultmatrix_cmd_cnt_ena 		= sresultmatrix_cmd_cnt_clr | sresultmatrix_cmd_cnt_incr;
   	assign sresultmatrix_cmd_cnt_nxt 		=   ( {ROWBUF_IDX_W{sresultmatrix_cmd_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}    )		|
											( {ROWBUF_IDX_W{sresultmatrix_cmd_cnt_incr}} & (sresultmatrix_cmd_cnt_r + 1'b1) );

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) sresultmatrix_cmd_cnt_dfflr (sresultmatrix_cmd_cnt_ena, sresultmatrix_cmd_cnt_nxt, sresultmatrix_cmd_cnt_r, nice_clk, nice_rst_n);

   	wire [ROWBUF_IDX_W-1:0] 		sresultmatrix_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		sresultmatrix_cnt_nxt;
   	wire 							sresultmatrix_cnt_clr;
   	wire 							sresultmatrix_cnt_incr;
   	wire 							sresultmatrix_cnt_ena;
   	wire 							sresultmatrix_cnt_last;

   	assign sresultmatrix_cnt_last 			= (sresultmatrix_cnt_r == clonum);
   	assign sresultmatrix_cnt_clr 			= sresultmatrix_icb_rsp_hsked_last;
   	assign sresultmatrix_cnt_incr 			= sresultmatrix_icb_rsp_hsked & ~sresultmatrix_cnt_last;
   	assign sresultmatrix_cnt_ena 			= sresultmatrix_cnt_clr | sresultmatrix_cnt_incr;
   	assign sresultmatrix_cnt_nxt 			=   ( {ROWBUF_IDX_W{sresultmatrix_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}	)	|
											( {ROWBUF_IDX_W{sresultmatrix_cnt_incr}} & (sresultmatrix_cnt_r + 1'b1) 	);

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) sresultmatrix_cnt_dfflr (sresultmatrix_cnt_ena, sresultmatrix_cnt_nxt, sresultmatrix_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in SBUF
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_sresultmatrix;

   	assign nice_rsp_valid_sresultmatrix = state_is_sresultmatrix & sresultmatrix_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when sresultmatrix_cmd_cnt_r is not full in SBUF
	// This signal decide that if nice_icb_cmd_valid should be pulled up.
   	wire nice_icb_cmd_valid_sresultmatrix;

   	assign nice_icb_cmd_valid_sresultmatrix = ( state_is_sresultmatrix 				&
									  (sresultmatrix_cmd_cnt_r <= clonum) 	&
									  (sresultmatrix_cnt_r != clonum)	);

	// This signal decide if sresultmatrix_cmd_cnt_incr should be pulled up.
	wire sresultmatrix_icb_cmd_hsked;

   	assign sresultmatrix_icb_cmd_hsked = (state_is_sresultmatrix | (state_is_idle & custom3_sresultmatrix)) & nice_icb_cmd_hsked;

	// This signal decide if sresultmatrix_cnt_incr should be pulled up.
   	wire sresultmatrix_icb_rsp_hsked;

   	assign sresultmatrix_icb_rsp_hsked = state_is_sresultmatrix & nice_icb_rsp_hsked;

	wire sresultmatrix_icb_rsp_hsked_last;

   	assign sresultmatrix_icb_rsp_hsked_last = sresultmatrix_icb_rsp_hsked & sresultmatrix_cnt_last;







   	wire [ROWBUF_IDX_W-1:0] 		lmatrix1_idx 		= lmatrix1_cnt_r;
   	wire 							lmatrix1_wr 		= lmatrix1_icb_rsp_hsked;
   	wire [`E203_XLEN-1:0] 			lmatrix1_wdata 		= nice_icb_rsp_rdata;

   	wire [ROWBUF_IDX_W-1:0] matrix1_idx_mux;
   	wire 					matrix1_wr_mux;
   	wire [`E203_XLEN-1:0] 	matrix1_wdat_mux;

   	assign matrix1_idx_mux = ({ROWBUF_IDX_W{lmatrix1_wr  }} & lmatrix1_idx);
   	assign matrix1_wr_mux = lmatrix1_wr;
   	assign matrix1_wdat_mux = ({`E203_XLEN{lmatrix1_wr  }} & lmatrix1_wdata);

   	wire [ROWBUF_DP-1:0]   matrix1_we;
   	wire [`E203_XLEN-1:0]  matrix1_wdat [ROWBUF_DP-1:0];
	wire [`E203_XLEN-1:0]  matrix1_r 	[ROWBUF_DP-1:0];

   	genvar i;

   	generate
   	  	for (i=0; i<ROWBUF_DP; i=i+1)
		begin:gen_matrix1

   	    	assign matrix1_we[i] = (matrix1_wr_mux & (matrix1_idx_mux == i[ROWBUF_IDX_W-1:0]));

   	    	assign matrix1_wdat[i] = ({`E203_XLEN{matrix1_we[i]}} & matrix1_wdat_mux);

   	    	sirv_gnrl_dfflr #(`E203_XLEN) matrix1_dfflr (matrix1_we[i], matrix1_wdat[i], matrix1_r[i], nice_clk, nice_rst_n);
   	  	end
   	endgenerate








   	wire [ROWBUF_IDX_W-1:0] 		lmatrix2_idx 		= lmatrix2_cnt_r;
   	wire 							lmatrix2_wr 		= lmatrix2_icb_rsp_hsked;
   	wire [`E203_XLEN-1:0] 			lmatrix2_wdata 		= nice_icb_rsp_rdata;

   	wire [ROWBUF_IDX_W-1:0] matrix2_idx_mux;
   	wire 					matrix2_wr_mux;
   	wire [`E203_XLEN-1:0] 	matrix2_wdat_mux;

   	assign matrix2_idx_mux = ({ROWBUF_IDX_W{lmatrix2_wr  }} & lmatrix2_idx);
   	assign matrix2_wr_mux = lmatrix2_wr;
   	assign matrix2_wdat_mux = ({`E203_XLEN{lmatrix2_wr  }} & lmatrix2_wdata);

   	wire [ROWBUF_DP-1:0]   matrix2_we;
   	wire [`E203_XLEN-1:0]  matrix2_wdat [ROWBUF_DP-1:0];
	wire [`E203_XLEN-1:0]  matrix2_r 	[ROWBUF_DP-1:0];

   	genvar j;

   	generate
   	  	for (j=0; j<ROWBUF_DP; j=j+1)
		begin:gen_matrix2

   	    	assign matrix2_we[j] = (matrix2_wr_mux & (matrix2_idx_mux == j[ROWBUF_IDX_W-1:0]));

   	    	assign matrix2_wdat[j] = ({`E203_XLEN{matrix2_we[j]}} & matrix2_wdat_mux);

   	    	sirv_gnrl_dfflr #(`E203_XLEN) matrix2_dfflr (matrix2_we[j], matrix2_wdat[j], matrix2_r[j], nice_clk, nice_rst_n);
   	  	end
   	endgenerate








   	wire [ROWBUF_DP-1:0]   resultmatrix_we;
   	wire [`E203_XLEN-1:0]  resultmatrix_wdat [ROWBUF_DP-1:0];
	wire [`E203_XLEN-1:0]  resultmatrix_r 	[ROWBUF_DP-1:0];

   	genvar k;

   	generate
   	  	for (k=0; k<ROWBUF_DP; k=k+1)
		begin:gen_resultmatrix

   	    	//assign resultmatrix_we[k] = 1'b1;
   	    	assign resultmatrix_we[k] = custom3_sresultmatrix;

   	    	assign resultmatrix_wdat[k] = matrix1_r[k] + matrix2_r[k];

   	    	sirv_gnrl_dfflr #(`E203_XLEN) resultmatrix_dfflr (resultmatrix_we[k], resultmatrix_wdat[k], resultmatrix_r[k], nice_clk, nice_rst_n);
   	  	end
   	endgenerate









   	//////////// mem aacess addr management
   	wire [`E203_XLEN-1:0] maddr_acc_r;

   	wire 							nice_icb_cmd_hsked;

   	assign nice_icb_cmd_hsked = nice_icb_cmd_valid & nice_icb_cmd_ready;

   	// custom3_lmatrix1
   	wire lmatrix1_maddr_ena    =   	(state_is_idle & custom3_lmatrix1 & nice_icb_cmd_hsked) 	|
							  	(state_is_lmatrix1 & nice_icb_cmd_hsked);

   	// custom3_smatrix1
   	wire smatrix1_maddr_ena    =   	(state_is_idle & custom3_smatrix1 & nice_icb_cmd_hsked)		|
								(state_is_smatrix1 & nice_icb_cmd_hsked);

   	// custom3_lmatrix2
   	wire lmatrix2_maddr_ena    =   	(state_is_idle & custom3_lmatrix2 & nice_icb_cmd_hsked) 	|
							  	(state_is_lmatrix2 & nice_icb_cmd_hsked);

   	// custom3_smatrix2
   	wire smatrix2_maddr_ena    =   	(state_is_idle & custom3_smatrix2 & nice_icb_cmd_hsked)		|
								(state_is_smatrix2 & nice_icb_cmd_hsked);

   	// custom3_sresultmatrix
   	wire sresultmatrix_maddr_ena    =   	(state_is_idle & custom3_sresultmatrix & nice_icb_cmd_hsked)		|
								(state_is_sresultmatrix & nice_icb_cmd_hsked);

   	// maddr acc
   	wire  maddr_ena = 	lmatrix1_maddr_ena 	|
						smatrix1_maddr_ena	|
						lmatrix2_maddr_ena 	|
                       	smatrix2_maddr_ena	|
                       	sresultmatrix_maddr_ena;

   	wire  maddr_ena_idle = maddr_ena & state_is_idle;

   	wire [`E203_XLEN-1:0] 	maddr_acc_op1 = maddr_ena_idle ? nice_req_rs1 : maddr_acc_r; // not reused
   	wire [`E203_XLEN-1:0] 	maddr_acc_op2 = maddr_ena_idle ? `E203_XLEN'h4 : `E203_XLEN'h4;

   	wire [`E203_XLEN-1:0] 	maddr_acc_next = maddr_acc_op1 + maddr_acc_op2;
   	wire  					maddr_acc_ena  = maddr_ena;

   	sirv_gnrl_dfflr #(`E203_XLEN)   maddr_acc_dfflr (maddr_acc_ena, maddr_acc_next, maddr_acc_r, nice_clk, nice_rst_n);

   	////////////////////////////////////////////////////////////
   	// Control cmd_req
   	////////////////////////////////////////////////////////////
   	assign nice_req_hsked = nice_req_valid & nice_req_ready;
   	assign nice_req_ready = state_is_idle & (custom_mem_op ? nice_icb_cmd_ready : 1'b1);

   	////////////////////////////////////////////////////////////
   	// Control cmd_rsp
   	////////////////////////////////////////////////////////////

   	assign nice_rsp_valid 		= 	nice_rsp_valid_smatrix1 	|
									nice_rsp_valid_lmatrix1		|
									nice_rsp_valid_smatrix2 	|
                                   	nice_rsp_valid_lmatrix2		|
									nice_rsp_valid_sresultmatrix;

   	assign nice_rsp_hsked 		= 	nice_rsp_valid 		&
									nice_rsp_ready;

   	assign nice_rsp_rdat  		=  0;

   	// memory access bus error
   	//assign nice_rsp_err_irq  =   (nice_icb_rsp_hsked & nice_icb_rsp_err)
   	//                          | (nice_req_hsked & illgel_instr)
   	//                          ;
   	assign nice_rsp_err   		=   (nice_icb_rsp_hsked & nice_icb_rsp_err);

   	////////////////////////////////////////////////////////////
   	// Memory lsu
   	////////////////////////////////////////////////////////////
	//
   	// 	memory access list:
	//
   	//  1. In IDLE, custom_mem_op will access memory(lmatrix1/smatrix1/rowsum)
   	//  2. In LBUF, it will read from memory as long as lmatrix1_cnt_r is not full
   	//  3. In SBUF, it will write to memory as long as smatrix1_cnt_r is not full
   	//  3. In ROWSUM, it will read from memory as long as rowsum_cnt_r is not full
	//
   	//	assign nice_icb_rsp_ready = state_is_ldst_rsp & nice_rsp_ready;
   	// 	rsp always ready

   	wire [ROWBUF_IDX_W-1:0] smatrix1_idx = smatrix1_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] smatrix2_idx = smatrix2_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] sresultmatrix_idx = sresultmatrix_cmd_cnt_r;

   	assign nice_icb_cmd_valid =	(state_is_idle & nice_req_valid & custom_mem_op) 		|
								nice_icb_cmd_valid_lmatrix1								|
								nice_icb_cmd_valid_smatrix1								|
								nice_icb_cmd_valid_lmatrix2								|
								nice_icb_cmd_valid_smatrix2								|
								nice_icb_cmd_valid_sresultmatrix;

   	assign nice_icb_cmd_addr  = (state_is_idle & custom_mem_op) ? nice_req_rs1 : maddr_acc_r;

   	assign nice_icb_cmd_read  = (state_is_idle & custom_mem_op) ? (custom3_lmatrix1 | custom3_lmatrix2) :
   	                     (state_is_smatrix1 | state_is_smatrix2 | state_is_sresultmatrix) ? 1'b0 : 1'b1;

   	//assign nice_icb_cmd_read  = (state_is_idle & custom_mem_op) ? (custom3_lmatrix1) :
   	  //                   					(state_is_smatrix1) ? 1'b0 : 1'b1;

   	assign nice_icb_cmd_wdata = (state_is_idle & custom3_smatrix1) ? matrix1_r[smatrix1_idx] :
   	                           					 state_is_smatrix1 ? matrix1_r[smatrix1_idx] :
								(state_is_idle & custom3_smatrix2) ? matrix2_r[smatrix2_idx] :
												 state_is_smatrix2 ? matrix2_r[smatrix2_idx] :
								(state_is_idle & custom3_sresultmatrix) ? resultmatrix_r[sresultmatrix_idx] :
												 state_is_sresultmatrix ? resultmatrix_r[sresultmatrix_idx] :
																	 `E203_XLEN'b0;

   	assign nice_icb_cmd_size  = 2'b10;

   	assign nice_icb_rsp_ready = 1'b1;

   	assign nice_icb_rsp_hsked = nice_icb_rsp_valid 	&
								nice_icb_rsp_ready;

   	////////////////////////////////////////////////////////////
   	// nice_mem_holdup
   	////////////////////////////////////////////////////////////
   	assign nice_mem_holdup    =  state_is_lmatrix1 	|
								 state_is_smatrix1	|
							 	 state_is_lmatrix2 	|
                                 state_is_smatrix2	|
                                 state_is_sresultmatrix;

   	////////////////////////////////////////////////////////////
   	// nice_active
   	////////////////////////////////////////////////////////////
   	assign nice_active = state_is_idle ? nice_req_valid : 1'b1;

endmodule

`endif//}
