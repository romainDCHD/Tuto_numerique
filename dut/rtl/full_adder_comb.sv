`timescale 1ns/1ps
// Additionneur basique purement combinatoire
// Sous bloc de adder_pipeline

module full_adder_comb (
    input  logic a_i,
    input  logic b_i,
    input  logic cin_i,
    output logic sum_o,
    output logic cout_o
);

    assign sum_o  = a_i ^ b_i ^ cin_i;
    assign cout_o = (a_i & b_i)
                  | (a_i & cin_i)
                  | (b_i & cin_i);

endmodule
