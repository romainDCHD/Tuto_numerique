`timescale 1ns/1ps

// =============================================================================
// Additionneur ripple-carry 4 bits entre deux banques de registres.
//
// Architecture :
//
//     FF_IN -> FA0 -> FA1 -> FA2 -> FA3 -> FF_OUT
//
// Fonction :
//
//   A chaque coup de clock : prend 4 bits en entrée et donne la somme en sortie
//     a la clk suivante
//
//  =============================================================================

module ripple_carry_4 (

    input  logic       clk_i,
    input  logic       rst_ni,

    input  logic [3:0] a_i,
    input  logic [3:0] b_i,
    input  logic       cin_i,

    output logic [3:0] sum_o,
    output logic       cout_o
);


    // =========================================================================
    // Registres d'entree
    // =========================================================================

    logic [3:0] a_q;
    logic [3:0] b_q;
    logic       cin_q;


    // =========================================================================
    // Signaux combinatoires
    // =========================================================================

    logic [3:0] sum_comb;

    // carry[0] = carry d'entree
    // carry[4] = carry final
    logic [4:0] carry;


    // =========================================================================
    // Banque de registres d'entree
    //
    // Reset synchrone actif bas.
    // =========================================================================

    always_ff @(posedge clk_i) begin

        if (!rst_ni) begin

            a_q   <= 4'b0000;
            b_q   <= 4'b0000;
            cin_q <= 1'b0;

        end else begin

            a_q   <= a_i;
            b_q   <= b_i;
            cin_q <= cin_i;

        end

    end


    // =========================================================================
    // Additionneur ripple-carry 4 bits
    // =========================================================================

    assign carry[0] = cin_q;


    // -------------------------------------------------------------------------
    // Bit 0
    // -------------------------------------------------------------------------

    full_adder_comb u_fa0 (
        .a_i    (a_q[0]),
        .b_i    (b_q[0]),
        .cin_i  (carry[0]),

        .sum_o  (sum_comb[0]),
        .cout_o (carry[1])
    );


    // -------------------------------------------------------------------------
    // Bit 1
    // -------------------------------------------------------------------------

    full_adder_comb u_fa1 (
        .a_i    (a_q[1]),
        .b_i    (b_q[1]),
        .cin_i  (carry[1]),

        .sum_o  (sum_comb[1]),
        .cout_o (carry[2])
    );


    // -------------------------------------------------------------------------
    // Bit 2
    // -------------------------------------------------------------------------

    full_adder_comb u_fa2 (
        .a_i    (a_q[2]),
        .b_i    (b_q[2]),
        .cin_i  (carry[2]),

        .sum_o  (sum_comb[2]),
        .cout_o (carry[3])
    );


    // -------------------------------------------------------------------------
    // Bit 3
    // -------------------------------------------------------------------------

    full_adder_comb u_fa3 (
        .a_i    (a_q[3]),
        .b_i    (b_q[3]),
        .cin_i  (carry[3]),

        .sum_o  (sum_comb[3]),
        .cout_o (carry[4])
    );


    // =========================================================================
    // Registres de sortie
    // =========================================================================

    always_ff @(posedge clk_i) begin

        if (!rst_ni) begin

            sum_o  <= 4'b0000;
            cout_o <= 1'b0;

        end else begin

            sum_o  <= sum_comb;
            cout_o <= carry[4];

        end

    end


endmodule
