`timescale 1ns/1ps

// Banc de test dirige et auto-verifiant du full adder.
module tb_full_adder_comb;

    logic a_i;
    logic b_i;
    logic cin_i;
    logic sum_o;
    logic cout_o;

    full_adder_comb dut (
        .a_i    (a_i),
        .b_i    (b_i),
        .cin_i  (cin_i),
        .sum_o  (sum_o),
        .cout_o (cout_o)
    );

    initial begin : test_exhaustif
        logic sum_attendue;
        logic cout_attendue;

        a_i   = 1'b0;
        b_i   = 1'b0;
        cin_i = 1'b0;

        // Les huit combinaisons de la table de verite sont testees.
        for (int vecteur = 0; vecteur < 8; vecteur++) begin
            {a_i, b_i, cin_i} = vecteur[2:0];
            // Le delai laisse le temps aux mises a jour combinatoires.
            #10;

            sum_attendue  = a_i ^ b_i ^ cin_i;
            cout_attendue = (a_i & b_i) | (a_i & cin_i) | (b_i & cin_i);

            if ((sum_o !== sum_attendue) || (cout_o !== cout_attendue)) begin
                $fatal(1,
                       "Echec vecteur %03b : obtenu cout,sum=%b%b, attendu=%b%b",
                       {a_i, b_i, cin_i}, cout_o, sum_o,
                       cout_attendue, sum_attendue);
            end
        end

        $display("TEST_PASS: full_adder_comb");
        $finish;
    end

endmodule
