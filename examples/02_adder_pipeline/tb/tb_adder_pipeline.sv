`timescale 1ns/1ps

// Banc de test dirige et auto-verifiant.
module tb_adder_pipeline;

    localparam int unsigned WIDTH = 8;
    localparam int unsigned NOMBRE_TRANSACTIONS = 8;

    logic             clk_i;
    logic             rst_ni;
    logic             valid_i;
    logic [WIDTH-1:0] a_i;
    logic [WIDTH-1:0] b_i;
    logic             cin_i;
    logic             valid_o;
    logic [WIDTH-1:0] sum_o;
    logic             cout_o;

    logic             valid_attendu_q = 1'b0;
    logic [WIDTH:0]   resultat_attendu_q = '0;
    integer           transactions_verifiees = 0;

    adder_pipeline #(
        .WIDTH (WIDTH)
    ) dut (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .valid_i (valid_i),
        .a_i     (a_i),
        .b_i     (b_i),
        .cin_i   (cin_i),
        .valid_o (valid_o),
        .sum_o   (sum_o),
        .cout_o  (cout_o)
    );

    initial begin
        clk_i = 1'b0;
        forever #5 clk_i = ~clk_i;
    end

    // Le scoreboard modele exactement la latence d'un cycle.
    // La verification est retardee d'une nanoseconde apres le front actif afin
    // d'observer les mises a jour non bloquantes.
    always @(posedge clk_i) begin : scoreboard
        if (!rst_ni) begin
            #1;
            if ((valid_o !== 1'b0) || (sum_o !== '0) || (cout_o !== 1'b0)) begin
                $fatal(1, "Le reset synchrone n'a pas remis les sorties a zero");
            end
            valid_attendu_q    = 1'b0;
            resultat_attendu_q = '0;
        end else begin
            #1;
            if (valid_o !== valid_attendu_q) begin
                $fatal(1, "valid_o=%b, valeur attendue=%b",
                       valid_o, valid_attendu_q);
            end

            if (valid_attendu_q) begin
                if ({cout_o, sum_o} !== resultat_attendu_q) begin
                    $fatal(1,
                           "Resultat obtenu=%h, attendu=%h",
                           {cout_o, sum_o}, resultat_attendu_q);
                end
                transactions_verifiees = transactions_verifiees + 1;
            end else if ((sum_o !== '0) || (cout_o !== 1'b0)) begin
                $fatal(1, "Les donnees de sortie doivent etre nulles sans valid_o");
            end

            valid_attendu_q = valid_i;
            resultat_attendu_q = {1'b0, a_i}
                               + {1'b0, b_i}
                               + {{WIDTH{1'b0}}, cin_i};
        end
    end

    // Les entrees sont appliquees au front descendant, a 5 ns du front actif.
    task automatic appliquer_vecteur(
        input logic             valid,
        input logic [WIDTH-1:0] a,
        input logic [WIDTH-1:0] b,
        input logic             cin
    );
        @(negedge clk_i);
        valid_i = valid;
        a_i     = a;
        b_i     = b;
        cin_i   = cin;
    endtask

    initial begin : scenario_dirige
        rst_ni  = 1'b0;
        valid_i = 1'b0;
        a_i     = '0;
        b_i     = '0;
        cin_i   = 1'b0;

        // Deux fronts actifs garantissent l'application du reset synchrone.
        repeat (2) @(negedge clk_i);
        rst_ni = 1'b1;

        appliquer_vecteur(1'b1, 8'h00, 8'h00, 1'b0); // zero
        appliquer_vecteur(1'b1, 8'hFF, 8'h00, 1'b1); // retenue de bout en bout
        appliquer_vecteur(1'b0, 8'h00, 8'h00, 1'b0); // bulle de validite
        appliquer_vecteur(1'b1, 8'h0F, 8'h01, 1'b0); // propagation locale
        appliquer_vecteur(1'b1, 8'h55, 8'hAA, 1'b0); // motifs alternes
        appliquer_vecteur(1'b1, 8'hA5, 8'h5A, 1'b1); // depassement avec cin
        appliquer_vecteur(1'b0, 8'h12, 8'h34, 1'b0); // seconde bulle
        appliquer_vecteur(1'b1, 8'h7F, 8'h01, 1'b0); // frontiere signee
        appliquer_vecteur(1'b1, 8'h80, 8'h80, 1'b0); // retenue de poids fort
        appliquer_vecteur(1'b1, 8'hFF, 8'h01, 1'b0); // maximum plus un

        // Cette bulle capture la derniere transaction et vide le pipeline.
        appliquer_vecteur(1'b0, 8'h00, 8'h00, 1'b0);
        @(posedge clk_i);
        #2;

        if (transactions_verifiees != NOMBRE_TRANSACTIONS) begin
            $fatal(1, "%0d transactions verifiees, %0d attendues",
                   transactions_verifiees, NOMBRE_TRANSACTIONS);
        end

        $display("TEST_PASS: adder_pipeline");
        $finish;
    end

endmodule
