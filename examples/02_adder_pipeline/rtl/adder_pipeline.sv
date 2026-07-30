`timescale 1ns/1ps

// Additionneur parametrique avec registres d'entree et de sortie.
//
// Une transaction capturee sur un front montant est presentee sur les sorties
// au front montant suivant : la latence fonctionnelle vaut donc un cycle.
module adder_pipeline #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             valid_i,
    input  logic [WIDTH-1:0] a_i,
    input  logic [WIDTH-1:0] b_i,
    input  logic             cin_i,
    output logic             valid_o,
    output logic [WIDTH-1:0] sum_o,
    output logic             cout_o
);

    logic [WIDTH-1:0] a_q;
    logic [WIDTH-1:0] b_q;
    logic             cin_q;
    logic             valid_q;

    logic [WIDTH-1:0] sum_comb;
    logic [WIDTH:0]   carry_comb;

    assign carry_comb[0] = cin_q;

    // La chaine de retenue instancie le meme full adder que le premier exemple.
    for (genvar bit_index = 0; bit_index < WIDTH; bit_index++) begin : gen_full_adders
        full_adder_comb u_full_adder (
            .a_i    (a_q[bit_index]),
            .b_i    (b_q[bit_index]),
            .cin_i  (carry_comb[bit_index]),
            .sum_o  (sum_comb[bit_index]),
            .cout_o (carry_comb[bit_index + 1])
        );
    end

    // Reset synchrone, actif a l'etat bas.
    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            a_q     <= '0;
            b_q     <= '0;
            cin_q   <= 1'b0;
            valid_q <= 1'b0;
            valid_o <= 1'b0;
            sum_o   <= '0;
            cout_o  <= 1'b0;
        end else begin
            a_q     <= a_i;
            b_q     <= b_i;
            cin_q   <= cin_i;
            valid_q <= valid_i;

            valid_o <= valid_q;
            if (valid_q) begin
                sum_o  <= sum_comb;
                cout_o <= carry_comb[WIDTH];
            end else begin
                sum_o  <= '0;
                cout_o <= 1'b0;
            end
        end
    end

endmodule
