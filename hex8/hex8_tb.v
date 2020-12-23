`include "hex8.v"

module hex8_tb ();

reg clk = 0;
always #5 clk = !clk;
reg reset;

hex8 DUT (
    .clk,
    .reset
);

initial begin
    reset = 1; #10;
    assert(DUT.a_reg == 8'b0);
    assert(DUT.b_reg == 8'b0);
    assert(DUT.pc == 8'b0);
    assert(DUT.r_reg == 8'b0);
    assert(DUT.o_reg_low == 4'b0);
    assert(DUT.o_reg_high == 4'b0);
    assert(DUT.i_reg == 4'b0);
    assert(DUT.pipeline == 3'b001);
    assert(DUT.phi == 2'b01);
    reset = 0;
    DUT.memory[0] = 8'b10100101; #20;
    assert(DUT.o_reg_low == 4'b0101);
    assert(DUT.i_reg == 4'b1010);
    assert(DUT.pc == 8'b0);
    #20;
    assert(DUT.pc == 8'b1);
    $finish;
end

endmodule
