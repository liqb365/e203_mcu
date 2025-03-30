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

`ifdef E203_HAS_NICE_VECTOR//{

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
   	//  1. custom3 lvector1: load data(in memory) to row_buf
   	//     lvector1 (a1)
   	//     .insn r opcode, func3, func7, rd, rs1, rs2
   	//  2. custom3 svector1: store data(in row_buf) to memory
   	//     svector1 (a1)
   	//     .insn r opcode, func3, func7, rd, rs1, rs2
   	////////////////////////////////////////////////////////////
   	//wire custom3_lvector1 	= opcode_custom3 & rv32_func3_010 & rv32_func7_0000001;
   	//wire custom3_svector1   = opcode_custom3 & rv32_func3_010 & rv32_func7_0000010;
   	wire custom3_lvector1 		= opcode_custom3 & rv32_func3_111 & rv32_func7_0000000;
   	wire custom3_svector1   	= opcode_custom3 & rv32_func3_111 & rv32_func7_0000001;
   	wire custom3_lvector2 		= opcode_custom3 & rv32_func3_111 & rv32_func7_0000010;
   	wire custom3_svector2   	= opcode_custom3 & rv32_func3_111 & rv32_func7_0000011;
   	wire custom3_lresultvector  = opcode_custom3 & rv32_func3_111 & rv32_func7_0000100;
   	wire custom3_sresultvector  = opcode_custom3 & rv32_func3_111 & rv32_func7_0000101;
   	wire custom3_mulacc  		= opcode_custom3 & rv32_func3_111 & rv32_func7_0000110;

   	////////////////////////////////////////////////////////////
   	//  multi-cyc op
   	////////////////////////////////////////////////////////////
   	wire custom_multi_cyc_op = 	custom3_lvector1 		|
								custom3_svector1		|
								custom3_lvector2 		|
                                custom3_svector2		|
                                custom3_lresultvector	|
                                custom3_sresultvector	|
                                custom3_mulacc;
   	// need access memory
   	wire custom_mem_op = 	custom3_lvector1 		|
							custom3_svector1		|
							custom3_lvector2 		|
                           	custom3_svector2		|
                           	custom3_lresultvector	|
                           	custom3_sresultvector	|
                           	custom3_mulacc;











   	////////////////////////////////////////////////////////////
   	// NICE FSM
   	////////////////////////////////////////////////////////////
   	parameter NICE_FSM_WIDTH 	= 4;

	parameter IDLE     			= 4'd0;
   	parameter LMATRIX1     		= 4'd1;
   	parameter SMATRIX1     		= 4'd2;
   	parameter LMATRIX2     		= 4'd3;
   	parameter SMATRIX2     		= 4'd4;
   	parameter LRESULTMATRIX     = 4'd5;
   	parameter SRESULTMATRIX     = 4'd6;
   	parameter MULACC     		= 4'd7;
   	parameter ROWSUM   			= 4'd8;

   	wire [NICE_FSM_WIDTH-1:0] 		state_r;
   	wire [NICE_FSM_WIDTH-1:0] 		nxt_state;

   	wire [NICE_FSM_WIDTH-1:0] 		state_idle_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_lvector1_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_svector1_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_lvector2_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_svector2_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_lresultvector_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_sresultvector_nxt;
   	wire [NICE_FSM_WIDTH-1:0] 		state_mulacc;

   	wire 							nice_req_hsked;
   	wire 							nice_rsp_hsked;
   	wire 							nice_icb_rsp_hsked;

   	wire 							illgel_instr = ~(custom_multi_cyc_op);

   	wire 							state_idle_exit_ena;
   	wire 							state_lvector1_exit_ena;
   	wire 							state_svector1_exit_ena;
   	wire 							state_lvector2_exit_ena;
   	wire 							state_svector2_exit_ena;
   	wire 							state_lresultvector_exit_ena;
   	wire 							state_sresultvector_exit_ena;
   	wire 							state_mulacc_exit_ena;
   	wire 							state_ena;

   	wire 							state_is_idle   		= (state_r == IDLE);
   	wire 							state_is_lvector1   	= (state_r == LMATRIX1);
   	wire 							state_is_svector1   	= (state_r == SMATRIX1);
   	wire 							state_is_lvector2   	= (state_r == LMATRIX2);
   	wire 							state_is_svector2   	= (state_r == SMATRIX2);
   	wire 							state_is_lresultvector  = (state_r == LRESULTMATRIX);
   	wire 							state_is_sresultvector  = (state_r == SRESULTMATRIX);
   	wire 							state_is_mulacc  		= (state_r == MULACC);

	//------------------------------------------------------------------------------------
   	assign state_idle_exit_ena 	= state_is_idle & nice_req_hsked & ~illgel_instr;
   	assign state_idle_nxt 		= custom3_lvector1    	? LMATRIX1   	:
                                  custom3_svector1    	? SMATRIX1   	:
                                  custom3_lvector2    	? LMATRIX2   	:
                                  custom3_svector2    	? SMATRIX2   	:
                                  custom3_lresultvector ? LRESULTMATRIX :
                                  custom3_sresultvector ? SRESULTMATRIX :
                                  custom3_mulacc 		? MULACC 		:
			    							   		  	  IDLE;

	//------------------------------------------------------------------------------------
   	assign state_lvector1_exit_ena 	= state_is_lvector1 & lvector1_icb_rsp_hsked_last;
   	assign state_lvector1_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_svector1_exit_ena 	= state_is_svector1 & svector1_icb_rsp_hsked_last;
   	assign state_svector1_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_lvector2_exit_ena 	= state_is_lvector2 & lvector2_icb_rsp_hsked_last;
   	assign state_lvector2_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_svector2_exit_ena 	= state_is_svector2 & svector2_icb_rsp_hsked_last;
   	assign state_svector2_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_lresultvector_exit_ena = state_is_lresultvector & lresultvector_icb_rsp_hsked_last;
   	assign state_lresultvector_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	assign state_sresultvector_exit_ena = state_is_sresultvector & sresultvector_icb_rsp_hsked_last;
   	assign state_sresultvector_nxt 		= IDLE;

	//------------------------------------------------------------------------------------
   	//assign state_mulacc_exit_ena = state_is_mulacc & mulacc_icb_rsp_hsked_last;
   	assign state_mulacc_exit_ena = state_is_mulacc & mulacc_done;
   	assign state_mulacc_nxt 	 = IDLE;

	//------------------------------------------------------------------------------------
   	assign nxt_state =  ({NICE_FSM_WIDTH{state_idle_exit_ena   			}} & state_idle_nxt   		) 	|
						({NICE_FSM_WIDTH{state_lvector1_exit_ena   		}} & state_lvector1_nxt   	) 	|
						({NICE_FSM_WIDTH{state_svector1_exit_ena   		}} & state_svector1_nxt   	)	|
						({NICE_FSM_WIDTH{state_lvector2_exit_ena   		}} & state_lvector2_nxt   	) 	|
						({NICE_FSM_WIDTH{state_svector2_exit_ena   		}} & state_svector2_nxt   	)	|
						({NICE_FSM_WIDTH{state_lresultvector_exit_ena   }} & state_lresultvector_nxt)	|
						({NICE_FSM_WIDTH{state_sresultvector_exit_ena   }} & state_sresultvector_nxt)	|
						({NICE_FSM_WIDTH{state_mulacc_exit_ena   		}} & state_mulacc_nxt   	);

   	assign state_ena =	state_idle_exit_ena 			|
						state_lvector1_exit_ena			|
						state_svector1_exit_ena			|
						state_lvector2_exit_ena			|
						state_svector2_exit_ena			|
						state_lresultvector_exit_ena	|
						state_sresultvector_exit_ena	|
						state_mulacc_exit_ena;

   	sirv_gnrl_dfflr #(NICE_FSM_WIDTH)   state_dfflr (state_ena, nxt_state, state_r, nice_clk, nice_rst_n);



	wire mulacc_done;
	reg reg_mulacc_done;

	assign mulacc_done = reg_mulacc_done;




	reg [7:0] counter;

	always @(posedge nice_clk or negedge nice_rst_n)
	begin
		if (state_is_mulacc == 1'b1)
		begin
			if (counter == 8'h3)
			begin
				reg_mulacc_done = 1'b1;
				counter = 8'h0;
			end
			else
			begin
				reg_mulacc_done = 1'b0;
				counter = counter + 8'h01;
			end
		end

	end


	initial
	begin
		counter = 8'h0;
		reg_mulacc_done = 1'b0;
	end








   	////////////////////////////////////////////////////////////
   	// instr EXU
   	////////////////////////////////////////////////////////////
   	reg [ROW_IDX_W-1:0] clonum = 3'b0;

	always @(posedge nice_clk or negedge nice_rst_n)
	begin
		if (nice_req_hsked == 1'b1)
			clonum = nice_req_rs2;
	end






   	wire nice_rsp_valid_mulacc;

   	assign nice_rsp_valid_mulacc = state_is_mulacc & mulacc_done;





   	//////////// 1. custom3_lvector1
   	wire [ROWBUF_IDX_W-1:0] 		lvector1_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		lvector1_cnt_nxt;
   	wire 							lvector1_cnt_clr;
   	wire 							lvector1_cnt_incr;
   	wire 							lvector1_cnt_ena;
   	wire 							lvector1_cnt_last;

	assign lvector1_cnt_last 			= (lvector1_cnt_r == clonum);
   	assign lvector1_cnt_clr 			= custom3_lvector1 & nice_req_hsked;
   	assign lvector1_cnt_incr 			= lvector1_icb_rsp_hsked & ~lvector1_cnt_last;
   	assign lvector1_cnt_ena 			= lvector1_cnt_clr | lvector1_cnt_incr;
   	assign lvector1_cnt_nxt 			=   ({ROWBUF_IDX_W{lvector1_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}) 	|
										({ROWBUF_IDX_W{lvector1_cnt_incr}} & (lvector1_cnt_r + 1'b1));

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) lvector1_cnt_dfflr (lvector1_cnt_ena, lvector1_cnt_nxt, lvector1_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in LBUF.
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_lvector1;

   	assign nice_rsp_valid_lvector1 = state_is_lvector1 & lvector1_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when lvector1_cnt_r is not full in LBUF.
	// This signal decide that if nice_icb_cmd_valid should be
	// pulled up.
   	wire nice_icb_cmd_valid_lvector1;

   	assign nice_icb_cmd_valid_lvector1 = (state_is_lvector1 & (lvector1_cnt_r < clonum));

	// lvector1_icb_rsp_hsked decide two things:
	// 1.If lvector1_cnt_incr should be pulled up.
	// 2.If lvector1_wr should be pulled up.
   	wire lvector1_icb_rsp_hsked;
	wire lvector1_icb_rsp_hsked_last;

   	assign lvector1_icb_rsp_hsked 		= 	state_is_lvector1 		&
										nice_icb_rsp_hsked;

   	assign lvector1_icb_rsp_hsked_last 	= 	lvector1_icb_rsp_hsked &
										lvector1_cnt_last;















   	//////////// 2. custom3_svector1
   	wire [ROWBUF_IDX_W-1:0] 		svector1_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		svector1_cmd_cnt_nxt;
   	wire 							svector1_cmd_cnt_clr;
   	wire 							svector1_cmd_cnt_incr;
   	wire 							svector1_cmd_cnt_ena;
   	wire 							svector1_cmd_cnt_last;

   	assign svector1_cmd_cnt_last 		= (svector1_cmd_cnt_r == clonum);
   	assign svector1_cmd_cnt_clr 		= svector1_icb_rsp_hsked_last;
   	assign svector1_cmd_cnt_incr 		= svector1_icb_cmd_hsked & ~svector1_cmd_cnt_last;
   	assign svector1_cmd_cnt_ena 		= svector1_cmd_cnt_clr | svector1_cmd_cnt_incr;
   	assign svector1_cmd_cnt_nxt 		=   ( {ROWBUF_IDX_W{svector1_cmd_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}    )		|
										( {ROWBUF_IDX_W{svector1_cmd_cnt_incr}} & (svector1_cmd_cnt_r + 1'b1) );

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) svector1_cmd_cnt_dfflr (svector1_cmd_cnt_ena, svector1_cmd_cnt_nxt, svector1_cmd_cnt_r, nice_clk, nice_rst_n);

   	wire [ROWBUF_IDX_W-1:0] 		svector1_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		svector1_cnt_nxt;
   	wire 							svector1_cnt_clr;
   	wire 							svector1_cnt_incr;
   	wire 							svector1_cnt_ena;
   	wire 							svector1_cnt_last;

   	assign svector1_cnt_last 			= (svector1_cnt_r == clonum);
  //assign svector1_cnt_clr 			= custom3_svector1 & nice_req_hsked;
   	assign svector1_cnt_clr 			= svector1_icb_rsp_hsked_last;
   	assign svector1_cnt_incr 			= svector1_icb_rsp_hsked & ~svector1_cnt_last;
   	assign svector1_cnt_ena 			= svector1_cnt_clr | svector1_cnt_incr;
   	assign svector1_cnt_nxt 			=   ( {ROWBUF_IDX_W{svector1_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}	)	|
										( {ROWBUF_IDX_W{svector1_cnt_incr}} & (svector1_cnt_r + 1'b1) 	);

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) svector1_cnt_dfflr (svector1_cnt_ena, svector1_cnt_nxt, svector1_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in SBUF
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_svector1;

   	assign nice_rsp_valid_svector1 = state_is_svector1 & svector1_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when svector1_cmd_cnt_r is not full in SBUF
	// This signal decide that if nice_icb_cmd_valid should be pulled up.
   	wire nice_icb_cmd_valid_svector1;

   	assign nice_icb_cmd_valid_svector1 = ( state_is_svector1 				&
									  (svector1_cmd_cnt_r <= clonum) 	&
									  (svector1_cnt_r != clonum)	);

	// This signal decide if svector1_cmd_cnt_incr should be pulled up.
	wire svector1_icb_cmd_hsked;

   	assign svector1_icb_cmd_hsked = (state_is_svector1 | (state_is_idle & custom3_svector1)) & nice_icb_cmd_hsked;

	// This signal decide if svector1_cnt_incr should be pulled up.
   	wire svector1_icb_rsp_hsked;
	wire svector1_icb_rsp_hsked_last;

   	assign svector1_icb_rsp_hsked 		= 	state_is_svector1 &
										nice_icb_rsp_hsked;

   	assign svector1_icb_rsp_hsked_last 	= 	svector1_icb_rsp_hsked &
										svector1_cnt_last;
















   	//////////// 3. custom3_lvector2
   	wire [ROWBUF_IDX_W-1:0] 		lvector2_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		lvector2_cnt_nxt;
   	wire 							lvector2_cnt_clr;
   	wire 							lvector2_cnt_incr;
   	wire 							lvector2_cnt_ena;
   	wire 							lvector2_cnt_last;

	assign lvector2_cnt_last 			= (lvector2_cnt_r == clonum);
   	assign lvector2_cnt_clr 			= custom3_lvector2 & nice_req_hsked;
   	assign lvector2_cnt_incr 			= lvector2_icb_rsp_hsked & ~lvector2_cnt_last;
   	assign lvector2_cnt_ena 			= lvector2_cnt_clr | lvector2_cnt_incr;
   	assign lvector2_cnt_nxt 			=   ({ROWBUF_IDX_W{lvector2_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}) 	|
										({ROWBUF_IDX_W{lvector2_cnt_incr}} & (lvector2_cnt_r + 1'b1));

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) lvector2_cnt_dfflr (lvector2_cnt_ena, lvector2_cnt_nxt, lvector2_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in LBUF.
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_lvector2;

   	assign nice_rsp_valid_lvector2 = state_is_lvector2 & lvector2_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when lvector2_cnt_r is not full in LBUF.
	// This signal decide that if nice_icb_cmd_valid should be
	// pulled up.
   	wire nice_icb_cmd_valid_lvector2;

   	assign nice_icb_cmd_valid_lvector2 = (state_is_lvector2 & (lvector2_cnt_r < clonum));

	// lvector2_icb_rsp_hsked decide two things:
	// 1.If lvector2_cnt_incr should be pulled up.
	// 2.If lvector2_wr should be pulled up.
   	wire lvector2_icb_rsp_hsked;
	wire lvector2_icb_rsp_hsked_last;

   	assign lvector2_icb_rsp_hsked 		= 	state_is_lvector2 		&
										nice_icb_rsp_hsked;

   	assign lvector2_icb_rsp_hsked_last 	= 	lvector2_icb_rsp_hsked &
										lvector2_cnt_last;

















   	//////////// 4. custom3_svector2
   	wire [ROWBUF_IDX_W-1:0] 		svector2_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		svector2_cmd_cnt_nxt;
   	wire 							svector2_cmd_cnt_clr;
   	wire 							svector2_cmd_cnt_incr;
   	wire 							svector2_cmd_cnt_ena;
   	wire 							svector2_cmd_cnt_last;

   	assign svector2_cmd_cnt_last 		= (svector2_cmd_cnt_r == clonum);
   	assign svector2_cmd_cnt_clr 		= svector2_icb_rsp_hsked_last;
   	assign svector2_cmd_cnt_incr 		= svector2_icb_cmd_hsked & ~svector2_cmd_cnt_last;
   	assign svector2_cmd_cnt_ena 		= svector2_cmd_cnt_clr | svector2_cmd_cnt_incr;
   	assign svector2_cmd_cnt_nxt 		=   ( {ROWBUF_IDX_W{svector2_cmd_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}    )		|
											( {ROWBUF_IDX_W{svector2_cmd_cnt_incr}} & (svector2_cmd_cnt_r + 1'b1) );

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) svector2_cmd_cnt_dfflr (svector2_cmd_cnt_ena, svector2_cmd_cnt_nxt, svector2_cmd_cnt_r, nice_clk, nice_rst_n);

   	wire [ROWBUF_IDX_W-1:0] 		svector2_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		svector2_cnt_nxt;
   	wire 							svector2_cnt_clr;
   	wire 							svector2_cnt_incr;
   	wire 							svector2_cnt_ena;
   	wire 							svector2_cnt_last;

   	assign svector2_cnt_last 			= (svector2_cnt_r == clonum);
   	assign svector2_cnt_clr 			= svector2_icb_rsp_hsked_last;
   	assign svector2_cnt_incr 			= svector2_icb_rsp_hsked & ~svector2_cnt_last;
   	assign svector2_cnt_ena 			= svector2_cnt_clr | svector2_cnt_incr;
   	assign svector2_cnt_nxt 			=   ( {ROWBUF_IDX_W{svector2_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}	)	|
											( {ROWBUF_IDX_W{svector2_cnt_incr}} & (svector2_cnt_r + 1'b1) 	);

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) svector2_cnt_dfflr (svector2_cnt_ena, svector2_cnt_nxt, svector2_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in SBUF
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_svector2;

   	assign nice_rsp_valid_svector2 = state_is_svector2 & svector2_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when svector2_cmd_cnt_r is not full in SBUF
	// This signal decide that if nice_icb_cmd_valid should be pulled up.
   	wire nice_icb_cmd_valid_svector2;

   	assign nice_icb_cmd_valid_svector2 = ( state_is_svector2 				&
									  (svector2_cmd_cnt_r <= clonum) 	&
									  (svector2_cnt_r != clonum)	);

	// This signal decide if svector2_cmd_cnt_incr should be pulled up.
	wire svector2_icb_cmd_hsked;

   	assign svector2_icb_cmd_hsked = (state_is_svector2 | (state_is_idle & custom3_svector2)) & nice_icb_cmd_hsked;

	// This signal decide if svector2_cnt_incr should be pulled up.
   	wire svector2_icb_rsp_hsked;

   	assign svector2_icb_rsp_hsked = state_is_svector2 & nice_icb_rsp_hsked;

	wire svector2_icb_rsp_hsked_last;

   	assign svector2_icb_rsp_hsked_last = svector2_icb_rsp_hsked & svector2_cnt_last;






   	//////////// 5. custom3_lresultvector
   	wire [ROWBUF_IDX_W-1:0] 		lresultvector_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		lresultvector_cnt_nxt;
   	wire 							lresultvector_cnt_clr;
   	wire 							lresultvector_cnt_incr;
   	wire 							lresultvector_cnt_ena;
   	wire 							lresultvector_cnt_last;

	assign lresultvector_cnt_last 			= (lresultvector_cnt_r == clonum);
   	assign lresultvector_cnt_clr 			= custom3_lresultvector & nice_req_hsked;
   	assign lresultvector_cnt_incr 			= lresultvector_icb_rsp_hsked & ~lresultvector_cnt_last;
   	assign lresultvector_cnt_ena 			= lresultvector_cnt_clr | lresultvector_cnt_incr;
   	assign lresultvector_cnt_nxt 			=   ({ROWBUF_IDX_W{lresultvector_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}) 	|
										({ROWBUF_IDX_W{lresultvector_cnt_incr}} & (lresultvector_cnt_r + 1'b1));

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) lresultvector_cnt_dfflr (lresultvector_cnt_ena, lresultvector_cnt_nxt, lresultvector_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in LBUF.
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_lresultvector;

   	assign nice_rsp_valid_lresultvector = state_is_lresultvector & lresultvector_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when lresultvector_cnt_r is not full in LBUF.
	// This signal decide that if nice_icb_cmd_valid should be
	// pulled up.
   	wire nice_icb_cmd_valid_lresultvector;

   	assign nice_icb_cmd_valid_lresultvector = (state_is_lresultvector & (lresultvector_cnt_r < clonum));

	// lresultvector_icb_rsp_hsked decide two things:
	// 1.If lresultvector_cnt_incr should be pulled up.
	// 2.If lresultvector_wr should be pulled up.
   	wire lresultvector_icb_rsp_hsked;
	wire lresultvector_icb_rsp_hsked_last;

   	assign lresultvector_icb_rsp_hsked 		= 	state_is_lresultvector 		&
										nice_icb_rsp_hsked;

   	assign lresultvector_icb_rsp_hsked_last 	= 	lresultvector_icb_rsp_hsked &
										lresultvector_cnt_last;









   	//////////// 6. custom3_sresultvector
   	wire [ROWBUF_IDX_W-1:0] 		sresultvector_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		sresultvector_cmd_cnt_nxt;
   	wire 							sresultvector_cmd_cnt_clr;
   	wire 							sresultvector_cmd_cnt_incr;
   	wire 							sresultvector_cmd_cnt_ena;
   	wire 							sresultvector_cmd_cnt_last;

   	assign sresultvector_cmd_cnt_last 		= (sresultvector_cmd_cnt_r == clonum);
   	assign sresultvector_cmd_cnt_clr 		= sresultvector_icb_rsp_hsked_last;
   	assign sresultvector_cmd_cnt_incr 		= sresultvector_icb_cmd_hsked & ~sresultvector_cmd_cnt_last;
   	assign sresultvector_cmd_cnt_ena 		= sresultvector_cmd_cnt_clr | sresultvector_cmd_cnt_incr;
   	assign sresultvector_cmd_cnt_nxt 		=   ( {ROWBUF_IDX_W{sresultvector_cmd_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}    )		|
											( {ROWBUF_IDX_W{sresultvector_cmd_cnt_incr}} & (sresultvector_cmd_cnt_r + 1'b1) );

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) sresultvector_cmd_cnt_dfflr (sresultvector_cmd_cnt_ena, sresultvector_cmd_cnt_nxt, sresultvector_cmd_cnt_r, nice_clk, nice_rst_n);

   	wire [ROWBUF_IDX_W-1:0] 		sresultvector_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] 		sresultvector_cnt_nxt;
   	wire 							sresultvector_cnt_clr;
   	wire 							sresultvector_cnt_incr;
   	wire 							sresultvector_cnt_ena;
   	wire 							sresultvector_cnt_last;

   	assign sresultvector_cnt_last 			= (sresultvector_cnt_r == clonum);
   	assign sresultvector_cnt_clr 			= sresultvector_icb_rsp_hsked_last;
   	assign sresultvector_cnt_incr 			= sresultvector_icb_rsp_hsked & ~sresultvector_cnt_last;
   	assign sresultvector_cnt_ena 			= sresultvector_cnt_clr | sresultvector_cnt_incr;
   	assign sresultvector_cnt_nxt 			=   ( {ROWBUF_IDX_W{sresultvector_cnt_clr }} & {ROWBUF_IDX_W{1'b0}}	)	|
											( {ROWBUF_IDX_W{sresultvector_cnt_incr}} & (sresultvector_cnt_r + 1'b1) 	);

   	sirv_gnrl_dfflr #(ROWBUF_IDX_W) sresultvector_cnt_dfflr (sresultvector_cnt_ena, sresultvector_cnt_nxt, sresultvector_cnt_r, nice_clk, nice_rst_n);

   	// nice_rsp_valid wait for nice_icb_rsp_valid in SBUF
	// This signal decide that if nice_rsp_valid should be
	// pulled up.
   	wire nice_rsp_valid_sresultvector;

   	assign nice_rsp_valid_sresultvector = state_is_sresultvector & sresultvector_cnt_last & nice_icb_rsp_valid;

   	// nice_icb_cmd_valid sets when sresultvector_cmd_cnt_r is not full in SBUF
	// This signal decide that if nice_icb_cmd_valid should be pulled up.
   	wire nice_icb_cmd_valid_sresultvector;

   	assign nice_icb_cmd_valid_sresultvector = ( state_is_sresultvector 				&
									  (sresultvector_cmd_cnt_r <= clonum) 	&
									  (sresultvector_cnt_r != clonum)	);

	// This signal decide if sresultvector_cmd_cnt_incr should be pulled up.
	wire sresultvector_icb_cmd_hsked;

   	assign sresultvector_icb_cmd_hsked = (state_is_sresultvector | (state_is_idle & custom3_sresultvector)) & nice_icb_cmd_hsked;

	// This signal decide if sresultvector_cnt_incr should be pulled up.
   	wire sresultvector_icb_rsp_hsked;

   	assign sresultvector_icb_rsp_hsked = state_is_sresultvector & nice_icb_rsp_hsked;

	wire sresultvector_icb_rsp_hsked_last;

   	assign sresultvector_icb_rsp_hsked_last = sresultvector_icb_rsp_hsked & sresultvector_cnt_last;







   	wire [ROWBUF_IDX_W-1:0] 		lvector1_idx 		= lvector1_cnt_r;
   	wire 							lvector1_wr 		= lvector1_icb_rsp_hsked;
   	wire [`E203_XLEN-1:0] 			lvector1_wdata 		= nice_icb_rsp_rdata;

   	wire [ROWBUF_IDX_W-1:0] vector1_idx_mux;
   	wire 					vector1_wr_mux;
   	wire [`E203_XLEN-1:0] 	vector1_wdat_mux;

   	assign vector1_idx_mux = ({ROWBUF_IDX_W{lvector1_wr  }} & lvector1_idx);
   	assign vector1_wr_mux = lvector1_wr;
   	assign vector1_wdat_mux = ({`E203_XLEN{lvector1_wr  }} & lvector1_wdata);

   	wire [ROWBUF_DP-1:0]   vector1_we;
   	wire [`E203_XLEN-1:0]  vector1_wdat [ROWBUF_DP-1:0];
	wire [`E203_XLEN-1:0]  vector1_r 	[ROWBUF_DP-1:0];

   	genvar i;

   	generate
   	  	for (i=0; i<ROWBUF_DP; i=i+1)
		begin:gen_vector1

   	    	assign vector1_we[i] = (vector1_wr_mux & (vector1_idx_mux == i[ROWBUF_IDX_W-1:0]));

   	    	assign vector1_wdat[i] = ({`E203_XLEN{vector1_we[i]}} & vector1_wdat_mux);

   	    	sirv_gnrl_dfflr #(`E203_XLEN) vector1_dfflr (vector1_we[i], vector1_wdat[i], vector1_r[i], nice_clk, nice_rst_n);
   	  	end
   	endgenerate








   	wire [ROWBUF_IDX_W-1:0] 		lvector2_idx 		= lvector2_cnt_r;
   	wire 							lvector2_wr 		= lvector2_icb_rsp_hsked;
   	wire [`E203_XLEN-1:0] 			lvector2_wdata 		= nice_icb_rsp_rdata;

   	wire [ROWBUF_IDX_W-1:0] vector2_idx_mux;
   	wire 					vector2_wr_mux;
   	wire [`E203_XLEN-1:0] 	vector2_wdat_mux;

   	assign vector2_idx_mux = ({ROWBUF_IDX_W{lvector2_wr  }} & lvector2_idx);
   	assign vector2_wr_mux = lvector2_wr;
   	assign vector2_wdat_mux = ({`E203_XLEN{lvector2_wr  }} & lvector2_wdata);

   	wire [ROWBUF_DP-1:0]   vector2_we;
   	wire [`E203_XLEN-1:0]  vector2_wdat [ROWBUF_DP-1:0];
	wire [`E203_XLEN-1:0]  vector2_r 	[ROWBUF_DP-1:0];

   	genvar j;

   	generate
   	  	for (j=0; j<ROWBUF_DP; j=j+1)
		begin:gen_vector2

   	    	assign vector2_we[j] = (vector2_wr_mux & (vector2_idx_mux == j[ROWBUF_IDX_W-1:0]));

   	    	assign vector2_wdat[j] = ({`E203_XLEN{vector2_we[j]}} & vector2_wdat_mux);

   	    	sirv_gnrl_dfflr #(`E203_XLEN) vector2_dfflr (vector2_we[j], vector2_wdat[j], vector2_r[j], nice_clk, nice_rst_n);
   	  	end
   	endgenerate









   	wire [ROWBUF_IDX_W-1:0] 		lresultvector_idx 		= lresultvector_cnt_r;
   	wire 							lresultvector_wr 		= lresultvector_icb_rsp_hsked;
   	wire [`E203_XLEN-1:0] 			lresultvector_wdata 	= nice_icb_rsp_rdata;

   	wire [ROWBUF_IDX_W-1:0] resultvector_idx_mux;
   	wire 					resultvector_wr_mux;
   	wire [`E203_XLEN-1:0] 	resultvector_wdat_mux;

   	assign resultvector_idx_mux = ({ROWBUF_IDX_W{lresultvector_wr  }} & lresultvector_idx);
   	assign resultvector_wr_mux = lresultvector_wr;
   	assign resultvector_wdat_mux = ({`E203_XLEN{lresultvector_wr  }} & lresultvector_wdata);

   	wire [ROWBUF_DP-1:0]   resultvector_we;
   	wire [`E203_XLEN-1:0]  resultvector_wdat [ROWBUF_DP-1:0];
	wire [`E203_XLEN-1:0]  resultvector_r 	[ROWBUF_DP-1:0];

   	genvar k;

   	generate
   	  	for (k=0; k<ROWBUF_DP; k=k+1)
		begin:gen_resultvector

   	    	//assign resultvector_we[k] = state_is_mulacc ? 1 : (resultvector_wr_mux & (resultvector_idx_mux == k[ROWBUF_IDX_W-1:0]));
   	    	assign resultvector_we[k] = mulacc_done ? 1 : (resultvector_wr_mux & (resultvector_idx_mux == k[ROWBUF_IDX_W-1:0]));

   	    	//assign resultvector_wdat[k] = ({`E203_XLEN{resultvector_we[k]}} & resultvector_wdat_mux);
   	    	//assign resultvector_wdat[k] = state_is_mulacc ? ((vector1_r[k] * 2) + resultvector_r[k]) : ({`E203_XLEN{resultvector_we[k]}} & resultvector_wdat_mux);
   	    	//assign resultvector_wdat[k] = mulacc_done ? ((vector1_r[k] * 2) + resultvector_r[k]) : ({`E203_XLEN{resultvector_we[k]}} & resultvector_wdat_mux);
   	    	assign resultvector_wdat[k] = mulacc_done ? ((vector1_r[k] * clonum) + resultvector_r[k]) : ({`E203_XLEN{resultvector_we[k]}} & resultvector_wdat_mux);

   	    	sirv_gnrl_dfflr #(`E203_XLEN) resultvector_dfflr (resultvector_we[k], resultvector_wdat[k], resultvector_r[k], nice_clk, nice_rst_n);
   	  	end
   	endgenerate

   	//wire [ROWBUF_DP-1:0]   resultvector_we;
   	//wire [`E203_XLEN-1:0]  resultvector_wdat [ROWBUF_DP-1:0];
	//wire [`E203_XLEN-1:0]  resultvector_r 	[ROWBUF_DP-1:0];

   	//genvar k;

   	//generate
   	//  	for (k=0; k<ROWBUF_DP; k=k+1)
	//	begin:gen_resultvector
   	//    	assign resultvector_we[k] = 1'b0;
   	//    	//assign resultvector_we[k] = custom3_sresultvector;
   	//    	assign resultvector_wdat[k] = vector1_r[k] + vector2_r[k];

   	//    	sirv_gnrl_dfflr #(`E203_XLEN) resultvector_dfflr (resultvector_we[k], resultvector_wdat[k], resultvector_r[k], nice_clk, nice_rst_n);
   	//  	end
   	//endgenerate









   	//////////// mem aacess addr management
   	wire [`E203_XLEN-1:0] maddr_acc_r;

   	wire 							nice_icb_cmd_hsked;

   	assign nice_icb_cmd_hsked = nice_icb_cmd_valid & nice_icb_cmd_ready;

   	// custom3_lvector1
   	wire lvector1_maddr_ena    =   	(state_is_idle & custom3_lvector1 & nice_icb_cmd_hsked) 	|
							  	(state_is_lvector1 & nice_icb_cmd_hsked);

   	// custom3_svector1
   	wire svector1_maddr_ena    =   	(state_is_idle & custom3_svector1 & nice_icb_cmd_hsked)		|
								(state_is_svector1 & nice_icb_cmd_hsked);

   	// custom3_lvector2
   	wire lvector2_maddr_ena    =   	(state_is_idle & custom3_lvector2 & nice_icb_cmd_hsked) 	|
							  	(state_is_lvector2 & nice_icb_cmd_hsked);

   	// custom3_svector2
   	wire svector2_maddr_ena    =   	(state_is_idle & custom3_svector2 & nice_icb_cmd_hsked)		|
								(state_is_svector2 & nice_icb_cmd_hsked);

   	// custom3_lresultvector
   	wire lresultvector_maddr_ena    =   	(state_is_idle & custom3_lresultvector & nice_icb_cmd_hsked) 	|
							  	(state_is_lresultvector & nice_icb_cmd_hsked);

   	// custom3_sresultvector
   	wire sresultvector_maddr_ena    =   	(state_is_idle & custom3_sresultvector & nice_icb_cmd_hsked)		|
								(state_is_sresultvector & nice_icb_cmd_hsked);

   	// maddr acc
   	wire  maddr_ena = 	lvector1_maddr_ena 			|
						svector1_maddr_ena			|
						lvector2_maddr_ena 			|
                       	svector2_maddr_ena			|
                       	lresultvector_maddr_ena		|
                       	sresultvector_maddr_ena;

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

   	assign nice_rsp_valid 		= 	nice_rsp_valid_svector1 		|
									nice_rsp_valid_lvector1			|
									nice_rsp_valid_svector2 		|
                                   	nice_rsp_valid_lvector2			|
									nice_rsp_valid_lresultvector	|
									nice_rsp_valid_sresultvector	|
									nice_rsp_valid_mulacc;

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
   	//  1. In IDLE, custom_mem_op will access memory(lvector1/svector1/rowsum)
   	//  2. In LBUF, it will read from memory as long as lvector1_cnt_r is not full
   	//  3. In SBUF, it will write to memory as long as svector1_cnt_r is not full
   	//  3. In ROWSUM, it will read from memory as long as rowsum_cnt_r is not full
	//
   	//	assign nice_icb_rsp_ready = state_is_ldst_rsp & nice_rsp_ready;
   	// 	rsp always ready

   	wire [ROWBUF_IDX_W-1:0] svector1_idx = svector1_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] svector2_idx = svector2_cmd_cnt_r;
   	wire [ROWBUF_IDX_W-1:0] sresultvector_idx = sresultvector_cmd_cnt_r;

   	assign nice_icb_cmd_valid =	(state_is_idle & nice_req_valid & custom_mem_op) 		|
								nice_icb_cmd_valid_lvector1								|
								nice_icb_cmd_valid_svector1								|
								nice_icb_cmd_valid_lvector2								|
								nice_icb_cmd_valid_svector2								|
								nice_icb_cmd_valid_lresultvector						|
								nice_icb_cmd_valid_sresultvector;

   	assign nice_icb_cmd_addr  = (state_is_idle & custom_mem_op) ? nice_req_rs1 : maddr_acc_r;

   	assign nice_icb_cmd_read  = (state_is_idle & custom_mem_op) ? (custom3_lvector1 | custom3_lvector2 | custom3_lresultvector) :
   	                     (state_is_svector1 | state_is_svector2 | state_is_sresultvector) ? 1'b0 : 1'b1;

   	//assign nice_icb_cmd_read  = (state_is_idle & custom_mem_op) ? (custom3_lvector1) :
   	  //                   					(state_is_svector1) ? 1'b0 : 1'b1;

   	assign nice_icb_cmd_wdata = (state_is_idle & custom3_svector1) ? vector1_r[svector1_idx] :
   	                           					 state_is_svector1 ? vector1_r[svector1_idx] :
								(state_is_idle & custom3_svector2) ? vector2_r[svector2_idx] :
												 state_is_svector2 ? vector2_r[svector2_idx] :
								(state_is_idle & custom3_sresultvector) ? resultvector_r[sresultvector_idx] :
												 state_is_sresultvector ? resultvector_r[sresultvector_idx] :
																	 `E203_XLEN'b0;

   	assign nice_icb_cmd_size  = 2'b10;

   	assign nice_icb_rsp_ready = 1'b1;

   	assign nice_icb_rsp_hsked = nice_icb_rsp_valid 	&
								nice_icb_rsp_ready;

   	////////////////////////////////////////////////////////////
   	// nice_mem_holdup
   	////////////////////////////////////////////////////////////
   	assign nice_mem_holdup    =  state_is_lvector1 			|
								 state_is_svector1			|
							 	 state_is_lvector2 			|
                                 state_is_svector2			|
                                 state_is_lresultvector		|
                                 state_is_sresultvector;

   	////////////////////////////////////////////////////////////
   	// nice_active
   	////////////////////////////////////////////////////////////
   	assign nice_active = state_is_idle ? nice_req_valid : 1'b1;

endmodule

`endif//}
