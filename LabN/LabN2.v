module labM;
wire [31:0] PCin;
reg RegDst, RegWrite, clk, ALUSrc, Mem2Reg, MemWrite, MemRead;
reg [2:0] op;
wire [31:0] wd, rd1, rd2, imm, ins, PCp4, z;
wire [31:0] jTarget, branch,memOut,wb;
wire zero, isjump, isbranch;

yIF myIF(ins, PCp4, PCin, clk);
yID myID(rd1, rd2, imm, jTarget, branch, ins, wd, RegWrite, clk);
yEX myEx(z, zero, rd1, rd2, imm, op, ALUSrc);
yDM myDM(memOut, z, rd2, clk, MemRead, MemWrite);
yWB myWB(wb, z, memOut, Mem2Reg);
yPC myPC(PCin,PC,PCp4,INT,entryPoint,branchImm,jImm,zero,isbranch,isjump);
yC1 myC1(isStype, isRtype, isItype, isLw, isjump, isbranch, opCode);
assign wd = wb;

initial
begin
//------------------------------------Entry point
entryPoint = 32'h28;
INT = 1; #1;
//PCin = 16'h28;
//------------------------------------Run program
repeat (43)
begin
//---------------------------------Fetch an ins
clk = 1; #1;
INT = 0;
//Temporally Set
//isjump = 0;
//isbranch = 0;

//RegDst = 0; RegWrite = 0; ALUSrc = 1; op = 3'b010;
//MemRead = 0;MemWrite = 0; Mem2Reg = 0;
//branch = 0; jump = 0;

//---------------------------------Set control signals
RegDst = 0; RegWrite = 0; ALUSrc = 1; op = 3'b010;
MemRead = 0;MemWrite = 0; Mem2Reg = 0;
branch = 0; jump = 0;

// Add statements to adjust the above defaults
if(ins[6:0] == 7'h33 && ins[14:12] == 3'b110) //R-type
begin
RegDst = 0; RegWrite =1; ALUSrc = 0;
MemRead =0;MemWrite = 0;Mem2Reg =0;
op=3'b001;
end

else if(ins[6:0] == 7'h33 && ins[14:12] == 3'b000)  //R-Type
begin
RegDst = 0; RegWrite = 1; ALUSrc = 0;
MemRead = 0;MemWrite = 0;Mem2Reg = 0;
op=3'b010;
end

if(ins[6:0] == 7'h03) // ld x8,8(x2)
begin
RegDst = 0; RegWrite = 1; ALUSrc = 1;
MemRead = 1;MemWrite = 0;Mem2Reg = 1;
end

if(ins[6:0] == 7'h13) // I-type addi x9,x9,8
begin
RegDst = 0; RegWrite = 1; ALUSrc = 1;
MemRead = 0; MemWrite = 0;Mem2Reg = 0;
end
if(ins[6:0] == 7'h63) // SB type beq x0,x0, loop
begin
RegDst = 0; RegWrite =0; ALUSrc = 0;
MemRead = 0; MemWrite = 0; Mem2Reg = 0;
end

if(ins[6:0] == 7'h6F) // UJ type or J-Type
begin
RegDst = 0; RegWrite = 1; ALUSrc = 1;
MemRead = 0;MemWrite = 0; Mem2Reg = 0;
end

if(ins[6:0] == 7'h23) // S type sw x14, 8(x2)
begin
RegDst = 0; RegWrite = 0; ALUSrc = 1;
MemRead = 0;MemWrite = 1; Mem2Reg = 0;
end

//---------------------------------Execute the ins
clk = 0; #1;
//---------------------------------View results
#1 $display("%h: rd1=%2d rd2=%2d z=%3d zero=%b wb=%2d",ins, rd1, rd2, z, zero, wb);
//---------------------------------Prepare for the next ins
/*if (INT == 1)
PCin = entryPoint;
else
if (beq && zero ==1)
PCin = PCp4 + (branchImm<<2);
else if (jal)
PCin = PCin + (jImm <<2)
else
PCin = PCp4;*/

/*begin
PCin = PCin + (branch<<2);
end
else if (ins[6:0] == 7'h6F) // UJ Type
begin
PCin =PCin + $signed(jTarget<<2);
end
else
begin
PCin = PCp4 ;
end*/


end
$finish;
end
endmodule
