module labL;

   reg a, b, cin;
   reg [1:0] expect;
   wire z, cout;
   yAdder1 adder(z, cout, a, b, cin);
   integer i, j, k;

   initial
     begin
        for (i = 0; i < 2; i = i + 1)
          for (j = 0; j < 2; j = j + 1)
            for (k = 0; k < 2; k = k + 1)
              begin
                 a = i;
                 b = j;
                 cin = k;

                 expect = a + b + cin;

                 #1; // wait for z and cout
                 if (expect[1] !== cout || expect[0] !== z)
                   $display("FAIL: a=%b b=%b cin=%b z=%b (expected %b) cout=%b (expected %b)",
                            a, b, cin, z, expect[0], cout, expect[1]);
              end
        $finish;
     end

endmodule // LabL
