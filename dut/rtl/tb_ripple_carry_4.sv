`timescale 1ns/1ps

module tb_ripple_carry_4;

    // ################################
    // # Signaux
    // ################################

    logic       clk_i;
    logic       rst_ni;

    logic [3:0] a_i;
    logic [3:0] b_i;
    logic       cin_i;

    logic [3:0] sum_o;
    logic       cout_o;

    integer errors;


    // ################################
    // # DUT
    // ################################

    ripple_carry_4 dut (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .a_i    (a_i),
        .b_i    (b_i),
        .cin_i  (cin_i),
        .sum_o  (sum_o),
        .cout_o (cout_o)
    );


    // ################################
    // # Horloge
    //
    // Periode   : 10 ns
    // Frequence : 100 MHz
    // ################################

    initial begin
        clk_i = 1'b0;
        forever #5ns clk_i = ~clk_i;
    end


    // ################################
    // # Verification d'un resultat
    // ################################

    task automatic check_result(
        input integer test_id,
        input logic [4:0] expected,
        input string detail
    );
       #1;
       
        if ({cout_o, sum_o} !== expected) begin
            errors = errors + 1;

            $display(
                "[TEST_FAILED] TEST %0d : %s | resultat=%0d attendu=%0d",
                test_id,
                detail,
                {cout_o, sum_o},
                expected
            );
        end
        else begin
            $display(
                "[TEST_PASS] TEST %0d : %s | resultat=%0d",
                test_id,
                detail,
                {cout_o, sum_o}
            );
        end

    endtask


    // ################################
    // # Stimuli
    // ################################

    initial begin

        errors = 0;

        rst_ni = 1'b0;
        a_i    = 4'd0;
        b_i    = 4'd0;
        cin_i  = 1'b0;


        // ################################
        // # Reset
        // ################################

        repeat (2) @(posedge clk_i);

        @(negedge clk_i);
        rst_ni = 1'b1;


        // ################################
        // # Test 1 : 5 + 3 + 0 = 8
        // ################################

        a_i   = 4'd5;
        b_i   = 4'd3;
        cin_i = 1'b0;

        @(posedge clk_i);
        @(posedge clk_i);
        #1ps;

        check_result(1, 5'd8, "5 + 3 + 0");


        // ################################
        // # Test 2 : 7 + 4 + 1 = 12
        // ################################

        @(negedge clk_i);

        a_i   = 4'd7;
        b_i   = 4'd4;
        cin_i = 1'b1;

        @(posedge clk_i);
        @(posedge clk_i);
        #1ps;

        check_result(2, 5'd12, "7 + 4 + 1");


        // ################################
        // # Test 3 : 15 + 1 + 0 = 16
        // ################################

        @(negedge clk_i);

        a_i   = 4'd15;
        b_i   = 4'd1;
        cin_i = 1'b0;

        @(posedge clk_i);
        @(posedge clk_i);
        #1ps;

        check_result(3, 5'd16, "15 + 1 + 0");


        // ################################
        // # Test 4 : 15 + 15 + 1 = 31
        // ################################

        @(negedge clk_i);

        a_i   = 4'd15;
        b_i   = 4'd15;
        cin_i = 1'b1;

        @(posedge clk_i);
        @(posedge clk_i);
        #1ps;

        check_result(4, 5'd31, "15 + 15 + 1");


        // ################################
        // # Resultats
        // ################################

        $display("");

        if (errors == 0) begin
            $display("[TEST_PASS] ALL_TESTS_PASSED");
        end
        else begin
            $display(
                "[TEST_FAILED] %0d_ERROR(S)",
                errors
            );
        end

        $display("");

        $finish;
    end

endmodule
