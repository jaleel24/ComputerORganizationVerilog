module labL ;

   reg signed   [31:0] a, b, expect;
   reg [2:0]           op;
   wire                ex;
   wire [31:0]         z;
   reg                 ok = 0, flag, tmp, zero;
   reg [1*7:0]         operator;

   yAlu alu(z, ex, a, b, op);

   initial
     begin
        repeat (3)
          begin
             a = $random;
             b = $random;
             tmp = $random % 2;
             flag = $value$plusargs("op=%d", op);

             if (tmp === 0) b = a;

             // The oracle: compute "expect" based on "op"
             if (op === 3'b000) begin
                expect = a & b;
                operator = "&";
             end
             else if (op === 3'b001) begin
                expect = a | b;
                operator = "|";
             end
             else if (op === 3'b010) begin
                expect = a + b;
                operator = "+";
             end
             else if (op === 3'b110) begin
                expect = a - b;
                operator = "-";
             end
             else if (op === 3'b111) begin
                expect = (a < b) ? 1 : 0;
                operator = "<";
             end

             #1;

             // Compare the circuit's output with "expect"
             // and set "ok" accordingly
             ok = (expect === z) ? 1 : 0;
             zero = (expect === 0) ? 1 : 0;

             if (ok)
               $display("PASS:  a=%b\n       b=%b\n     a%sb=%b\n    zero=%b\n",
                        a, b, operator, z, zero);
             else
               $display("FAIL:  a=%b\n       b=%b\n     a%sb=%b\nexpected=%b\n    zero=%b\n",
                        a, b, operator, z, expect, zero);
          end
        $finish;
     end

endmodule // LabL
