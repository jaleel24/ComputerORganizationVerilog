module ALU(input ALUenable,input[4:0] command, input[31:0] data1, input[31:0] data2, output[31:0] ALUresult, output ALUzero);
    // BEQ and SUB needs SUB, ADD needs ADD, shift left needs SL, and XOR, OR  command={OR,XOR,SL,ADD,SUB} which is from the control unit
    parameter SUB=5'b00001;
    parameter ADD=5'b00010;
    parameter  SL=5'b00100;
    parameter XOR=5'b01000;
    parameter  OR=5'b10000;
	 //Milestone 2, AND instruction op // 00111
	 parameter AND=5'b00111;
    reg[31:0] ALUresult_r;
    assign ALUresult=ALUresult_r;
    assign ALUzero=(ALUresult==32'h00000000)?1'b1:1'b0;
    always @(posedge ALUenable)
       begin
          case(command)
            SUB:
               begin
                  ALUresult_r<=data1-data2;
               end
            ADD:
               begin
                  ALUresult_r<=data1+data2;
               end
             SL:
               begin
                  ALUresult_r<=data1<<data2;
               end 
             XOR:
               begin
                  ALUresult_r<=data1^data2;
               end  
             OR:
               begin
                  ALUresult_r<=data1|data2;
					end
				//Milestone 2, AND operations
				AND:				
					begin 
						ALUresult_r<=data1&data2;
               end
					
             default:ALUresult_r<=32'h11111111;
           endcase         
       end
endmodule
//Mar. 2, 2019, Y. Zhao, EECS2021, YorkU
