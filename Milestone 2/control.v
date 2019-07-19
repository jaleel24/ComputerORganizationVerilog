module control(input[10:0] execution, input clk, input rst, input[31:0] ALU_data2, input[31:0] rd2, input ALUzero,
input[31:0] pc_addr_plus, input[31:0] ALUresult, input[31:0] rd_data,
output inc_pc, output load_inst, output dec_en, output mem_rd, output regwrite, output[31:0] wd,
output ALUenable, output mem_wr, output jump, output branch, output[31:0] data2, output[4:0] ALUcommand);
   // I---LW, ld rd, rs1, imm
   // 12bit-immediate | 5bit-rs1 | 3bit-funct | 5bit-rd | 7bit-opcode 
   //load word :           LW     32'b?????????????????010?????0000011    I

   // I---SLLI, slli rd, imm(rs1)  shift rd to left by [imm+(value of rs1)] bits
   // 6bit-funct | 6bit-immediate | 5bit-rs1 | 3bit-funct | 5bit-rd | 7bit-opcode 
   //Shift Left imediate:  SLLI,  32'b000000???????????001?????0010011    I

   // S, sw rs1,rs2,imm, store the value in rs2 to the address [(value of rs1)+imm] of data_RAM
   //imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
   //store word:           SW     32'b?????????????????010?????0100011    S
   //SB, imm[12]|imm[10:5]|rs2|rs1|func3|imm[4:1]|imm[11]|opcode
   //Branch equal:         BEQ    32'b?????????????????000?????1100011    S   if rs1==rs2,  branch to imm

	
   //R, sll rd, rs1, rs2       shift the value of rs1 by (value of rs2) bits and reture the shifted value to rd
   // 7-bit funct | 5bit-rs2 | 5bit-rs1 | 3bit-funct | 5-bit rd | 7-bit opcode |
   //                      ADD    32'b0000000??????????000?????0110011    R
   //                      SUB    32'b0100000??????????000?????0110011    R
   //Shift Left:           SLL    32'b0000000??????????001?????0110011    R
   //                      XOR    32'b0000000??????????100?????0110011    R
   //                       OR    32'b0000000??????????110?????0110011    R
	
	//	Instruction added for Milestone 2:						
   // 	                  AND 	 32'b0000000??????????111?????0110011	  R
	
   //UJ, JAL, jal rd, imm, 
   // imm[20]| imm[10:1] | imm[11] | imm[19:12] | rd | opcode
   //                      JAL    32'b?????????????????????????1101111   UJ
   // system            EBREAK    32'b00000000000100000000000001110011   HALT system
    parameter ALUSUB=5'b00001;
    parameter ALUADD=5'b00010;
    parameter  ALUSL=5'b00100;
    parameter ALUXOR=5'b01000;
    parameter  ALUOR=5'b10000;
	 parameter ALUAND=5'b00111;   //for AND operation
   
    parameter     LW=11'b00000000001;
    parameter   SLLI=11'b00000000010;
    parameter     SW=11'b00000000100;
    parameter    BEQ=11'b00000001000;
    parameter    ADD=11'b00000010000;
    parameter    SUB=11'b00000100000;
    parameter    SLL=11'b00001000000;
    parameter    XOR=11'b00010000000;
    parameter     OR=11'b00100000000;
	 //milestone 2
	 parameter 	  AND=11'b00000000011;
    parameter    JAL=11'b01000000000;
    parameter   HALT=11'b10000000000;
	 
    
    parameter     fetch=3'b000;
    parameter  decoding=3'b001;
    parameter   control=3'b010;
    parameter executing=3'b011;
    parameter writeback=3'b100;
    parameter change_pc=3'b101;

    reg[2:0] state;
    reg[8:0] op_reg;
    reg[4:0] ALUcommand_r;
    reg[2:0] select_wd;
    reg ALUsrc;

    assign data2=(ALUsrc==1'b1)?ALU_data2:rd2; //mux to selec the second input of the ALU is from ALU_data2 or directly from register i.e. rd2.
    assign {load_inst, dec_en, ALUenable, mem_rd, regwrite, mem_wr, jump, branch, inc_pc}=op_reg;
    assign ALUcommand=ALUcommand_r;
    assign wd=({32{select_wd[2]}}&pc_addr_plus)|({32{select_wd[1]}}&ALUresult)|({32{select_wd[0]}}&rd_data); // if select_wd=3'b100  then the input of the register writing is from pc_addr_plus
                                                                                                       // if select_wd=3'b010 from ALUresult, else 3'b001 from rd_data of dataRAM 
    always @(posedge clk or posedge rst)
       if (rst==1)
          begin
            state<=3'b000;
            op_reg<=9'b000000000;
            ALUsrc<=1'b0;
            ALUcommand_r<=5'b00000;
            select_wd<=3'b010;
          end
       else
          begin
            case(state)
              fetch:
                begin
                  op_reg<=9'b100000000; //load one instruction from inst_ROM based on the value of PC, initial value of PC is 0, 
                  state<=decoding;
                end
           decoding:
                begin
                  op_reg<=9'b110000000; //fetched one instruction and start to send to inst_decoder for decoding
                  state<=control;
                end
            control:
                begin
                  case(execution)
                     LW,SW:               //if the the execution is load word, do the following preparationg, later we will find in this stage LW SW have same operation
                       begin
                         ALUsrc<=1'b1; //select the imm address as the second input of the ALU, noting first input of ALU always from register file i.e. rd1.
                         ALUcommand_r<=ALUADD; //ALU execute add operation during execution state
                         state<=executing; //state to executing stage when next clock comes
                       end
                     SLLI:               //if the the execution is shift left immediately 
                       begin
                         ALUsrc<=1'b1; //select the imm value as the second input of the ALU to shift the rd1.
                         ALUcommand_r<=ALUSL; //
                         state<=executing; //state to executing stage when next clock comes
                       end
//                     SW:               //if the the execution is store word
//                       begin
//                         ALUsrc<=1'b1; //select the imm address as the second input of the ALU which will be addted to the adress in rd1 from register file.
//                         ALUcommand_r<=ALUADD; //ALU execute add operation, we can find that during the preparation stage, the LW and SW has same operation, we can joint them
//                       end
                     BEQ, SUB:               //if the the execution is branch when equal, we can find BEQ is same with SUB in this stage, we can joint them
                       begin
                         ALUsrc<=1'b0; //select the rd2 as the second input of ALU.
                         ALUcommand_r<=ALUSUB; //ALU execute sub operation
                         state<=executing; //state to executing stage when next clock comes
                       end
                     ADD:               //if the the execution is addition 
                       begin
                         ALUsrc<=1'b0; //select the rd2.
                         ALUcommand_r<=ALUADD; //execute addition 
                         state<=executing; //state to executing stage when next clock comes
                       end
                     SLL:               //if the the execution is logical shift left
                       begin
                         ALUsrc<=1'b0; //select the rd2.
                         ALUcommand_r<=ALUSL; //execute shift left 
                         state<=executing; //state to executing stage when next clock comes
                       end
                     XOR:               //if the the execution is bit wise xor 
                       begin
                         ALUsrc<=1'b0; //select the rd2.
                         ALUcommand_r<=ALUXOR; //execute bitwise xor
                         state<=executing; //state to executing stage when next clock comes
                       end
                     OR:               //if the the execution is bit wise or 
                       begin
                         ALUsrc<=1'b0; //select the rd2.
                         ALUcommand_r<=ALUOR; //execute bitwise or
                         state<=executing; //state to executing stage when next clock comes
                       end
						   AND:               //if the the execution is bit wise or 
							 begin
                         ALUsrc<=1'b0; //select the rd2.
                         ALUcommand_r<=ALUAND; //execute bitwise or
                         state<=executing; //state to executing stage when next clock comes
                       end
                     JAL:               //if the the execution is jump
                       begin
                         //dont need ALU for jump, so dont need ALU preparations 
                         state<=executing; //state to executing stage when next clock comes
                       end
                     HALT:              //if the the execution is HALT
                       begin
                         //dont need ALU for jump, so dont need ALU preparations 
                         state<=fetch; //state to instruction fetch state, since PC keeps same, instructions fetched is still HALT,
                                       //therefore, the CPU will keep looping from the instruction fetch to control, we can take is as shutdown
                       end
                  endcase
                  op_reg<=9'b000000000;
                end
            executing:
                begin
                  case(execution)																			//Milestone 2
                     LW, SLLI, SW, BEQ, ADD, SUB, SLL, XOR, OR, AND:op_reg<=9'b001000000; //executing ALU when the command requires
                  endcase
                  state<=writeback;
                end
            writeback:
                begin
                  case(execution)
                     LW:
                       begin
                         op_reg[5]<=1'b1; //start reading the data ram content at the address indexed by the ALUresult
                         select_wd<=3'b001; //select the output of data ram as the input of register writing
                       end
                     SW:
                       begin
                         op_reg[3]<=1'b1; //start writing rd2 to the data ram at the address indexed by the ALUresult                         
                       end
                     SLLI, ADD, SUB, SLL, XOR, OR, AND:	//Milestone 2 //add AND operation, so it will enable the output of the ALUresult ram as the input of register writing
                       begin
                         select_wd<=3'b010; //select the output of ALUresult ram as the input of register writing
                       end
                     BEQ:
                       begin
                         op_reg[1]<=(ALUzero==1'b1)?1'b1:1'b0; //if the value is same , then set branch to 1
                       end
                     JAL:
                       begin
                         select_wd<=3'b100; //select pc_addr_plus as the input of register writing
                         op_reg[2]<=1'b1; //set the jump to 1 for instruction address updating in pc
                       end
                  endcase
                  state<=change_pc;
                  op_reg[6]<=1'b0; //change ALUenable back to 0
                end
            change_pc:
                begin
                  case(execution)
						//Milestone 2
						//we have added AND to enable the result to register file
                     LW, SLLI, ADD, SUB, SLL, XOR, OR, AND, JAL:op_reg[4]<=1'b1; //write the result to register file
                  endcase
                  state<=fetch; //finished the command and return to the instruction fetch stage
                  op_reg[0]<=1'b1; //for all commands, update the pc trigierd by the rising edge of inc_pc
                end
            default: 
                begin
                  state<=3'b000;
                  op_reg<=9'b000000000;
                  ALUsrc<=1'b0;
                  ALUcommand_r<=5'b00000;
                  select_wd<=3'b010;
                end
            endcase
          end
endmodule
//Mar. 3, 2019, Y. Zhao, EECS2021, YorkU
