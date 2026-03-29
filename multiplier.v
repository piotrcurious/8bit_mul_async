// Unsigned 8×8 → 16-bit multiplier
// Verilog-2001 (IEEE 1364-2001)
//
// Architecture:
//   - 8 partial products, each gated by one bit of b
//   - Operand a widened to 16 bits before shifting to prevent truncation
//   - Balanced binary reduction tree: 3 adder levels, depth O(log2 N)
//
// Overflow proof:
//   max pp[i] = 0xFF << i; pp[7] = 0x7F80 < 0xFFFF  → no pp overflows 16b
//   max product = 255×255 = 65025 < 65536             → result fits in 16b
//   all intermediate sums < 65536                      → no stage overflows

module multiplier (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    output wire [15:0] c
);

    // Partial products
    // {8'b0, a} makes the operand explicitly 16-bit before the shift,
    // preventing the 8-bit truncation that ({8{b[i]}} & a) << i would cause.
    // Note: wire arrays are valid Verilog-2001 (IEEE 1364-2001 §4.2.1)
    wire [15:0] pp [0:7];

    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : gen_pp
            assign pp[i] = b[i] ? ({8'b0, a} << i) : 16'b0;
        end
    endgenerate

    // Balanced reduction tree — 3 adder levels vs 7 in a linear chain
    wire [15:0] s0 = pp[0] + pp[1];
    wire [15:0] s1 = pp[2] + pp[3];
    wire [15:0] s2 = pp[4] + pp[5];
    wire [15:0] s3 = pp[6] + pp[7];
    wire [15:0] s4 = s0 + s1;
    wire [15:0] s5 = s2 + s3;

    assign c = s4 + s5;

endmodule
