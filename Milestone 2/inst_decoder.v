module inst_decoder(input[31:0] inst, input dec_en, output[4:0] rr1, output[4:0] rr2, output[4:0] wr, output[31:0] ALU_data2, output[31:0] branch_address,
output[31:0] jump_address, output[10:0] execution );
   // I---LW, ld rd, rs1, imm
   // 12bit-immediate | 5bit-rs1 | 3bit-funct | 5bit-rd | 7bit-opcode 
   //load word :           LW     32'b?????????????????010?????0000011    I1

   // I---SLLI, slli rd, imm(rs1)  shift rd to left by [imm+(value of rs1)] bits
   // 6bit-funct | 6bit-immediate | 5bit-rs1 | 3bit-funct | 5bit-rd | 7bit-opcode 
   //Shift Left imediate:  SLLI,  32'b000000???????????001?????0010011    I2

   // S, sw rs1,rs2,imm, store the value in rs2 to the address [(value of rs1)+imm] of data_RAM
   //imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
   //store word:           SW     32'b?????????????????010?????0100011    S1
   //SB, imm[12]|imm[10:5]|rs2|rs1|imm[4:1]|imm[11]|opcode
   //Branch equal:         BEQ    32'b?????????????????000?????1100011    S2   if rs1==rs2,  branch to imm

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
    parameter     I1=7'b0000011;  
    parameter     I2=7'b0010011;
    parameter     S1=7'b0100011;
    parameter     S2=7'b1100011;
    parameter      R=7'b0110011;
    parameter     UJ=7'b1101111;
    parameter     SH=7'b1110011;

    parameter     LW=11'b00000000001;
    parameter   SLLI=11'b00000000010;
    parameter     SW=11'b00000000100;
    parameter    BEQ=11'b00000001000;
    parameter    ADD=11'b00000010000;
    parameter    SUB=11'b00000100000;
    parameter    SLL=11'b00001000000;
    parameter    XOR=11'b00010000000;
    parameter     OR=11'b00100000000;
	 parameter 	  AND=11'b00000000011;	//AND code is 0011000000000
    parameter    JAL=11'b01000000000;
    parameter   HALT=11'b10000000000;
    reg[31:0] rr1_r, rr2_r, wr_r, branch_address_r, jump_address_r, ALU_data2_r;
    reg[10:0] execution_r;
    assign execution=execution_r;
    assign ALU_data2=ALU_data2_r;
    assign rr1=rr1_r;
    assign rr2=rr2_r;
    assign wr=wr_r;
    assign branch_address=branch_address_r;
    assign jump_address=jump_address_r;
    always @(posedge dec_en)
        begin
           case(inst[6:0])
             I1:
                begin
                  if (inst[14:12]==3'b010)
                     begin
                       execution_r<=LW;             //command for control to generate corresponding control signal
                       ALU_data2_r<={{21{inst[31]}},inst[30:20]}; // imm address for ALU to add to rd1 from the register file, concatenating the extened sign bit with the orignal value to a 32bit imm value
                       rr1_r<=inst[19:15];  //rd1 index
                       wr_r<=inst[11:7];   // target register index
                     end
                end
             I2:
                begin
                  if ((inst[14:12]==3'b001)&&(inst[31:26]==6'b000000))
                     begin
                       execution_r<=SLLI;
                       ALU_data2_r<={{27{inst[25]}},inst[24:20]}; // 32bit value for ALU input to shift the other input
                       rr1_r<=inst[19:15];
                       wr_r<=inst[11:7];   // target register index
                     end
                end
             S1:
                begin
                  if (inst[14:12]==3'b010)
                     begin
                       execution_r<=SW;
                       ALU_data2_r<={{21{inst[31]}},inst[30:25],inst[11:7]}; // 32bit value for ALU input to shift the other input
                       rr1_r<=inst[19:15];
                       rr2_r<=inst[24:20];   // register index to find the value to be stored
                     end
                end
             S2:
                begin
                  if (inst[14:12]==3'b000)
                     begin
                       execution_r<=BEQ;
                       branch_address_r<={{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'b0}; // 32bit value for ALU input to shift the other input
                       rr1_r<=inst[19:15];
                       rr2_r<=inst[24:20];   // register index to find the value to be stored
                     end
                end
             R:
                begin
                  if ((inst[14:12]==3'b000)&&(inst[31:25]==7'b0000000))
                     begin
                       execution_r<=ADD;
                       rr1_r<=inst[19:15];
                       rr2_r<=inst[24:20];   
                       wr_r<=inst[11:7];
                     end
                  if ((inst[14:12]==3'b000)&&(inst[31:25]==7'b0100000))
                     begin
                       execution_r<=SUB;
                       rr1_r<=inst[19:15];
                       rr2_r<=inst[24:20];   
                       wr_r<=inst[11:7];
                     end
                  if ((inst[14:12]==3'b001)&&(inst[31:25]==7'b0000000))
                     begin
                       execution_r<=SLL;
                       rr1_r<=inst[19:15];
                       rr2_r<=inst[24:20];   
                       wr_r<=inst[11:7];
                     end
                  if ((inst[14:12]==3'b100)&&(inst[31:25]==7'b0000000))
                     begin
                       execution_r<=XOR;
                       rr1_r<=inst[19:15];
                       rr2_r<=inst[24:20];  
                       wr_r<=inst[11:7];
                     end
                  if ((inst[14:12]==3'b110)&&(inst[31:25]==7'b0000000))
                     begin
                       execution_r<=OR;
                       rr1_r<=inst[19:15];
                       rr2_r<=inst[24:20]; 
                       wr_r<=inst[11:7];
                     end
						if ((inst[14:12]==3'b111)&&(inst[31:25]==7'b0000000))
                    begin
                       execution_r<=AND;				//added 111 Funct3 for AND operation
                       rr1_r<=inst[19:15];			//AND    32'b0000000??????????111?????0110011    R
                       rr2_r<=inst[24:20]; 
                       wr_r<=inst[11:7];
                    end
                end
             UJ:
                begin
                       execution_r<=JAL;  //imm[20]| imm[10:1] | imm[11] | imm[19:12] | rd | opcode
                       jump_address_r<={{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'b0}; // 32bit jump address
                       wr_r<=inst[11:7];
                end
             SH:
                begin
                  if (inst[31:7]==25'b0000000000010000000000000)
                     begin
                       execution_r<=HALT;  //imm[20]| imm[10:1] | imm[11] | imm[19:12] | rd | opcode
                     end
                end
           endcase
        end
endmodule
//Mar. 2, Y. Zhao, EECS2021, YorkU
