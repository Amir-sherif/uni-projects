`timescale 1ns/1ps

module master_tb;

    reg         clk;
    reg         reset;
    reg         start;
    reg         cpol, cpha;
    reg  [31:0] data_in;
    reg  [3:0]  dvsr;
    reg  [1:0]  slave_sel;

    wire        mosi;
    wire        sclk;
    wire [31:0] data_out;
    wire [3:0]  cs;
    wire        busy, done;

    // loopback: whatever master sends out, it reads back in
    wire miso = mosi;

    master dut (
        .clk        (clk),
        .reset      (reset),
        .start      (start),
        .cpol       (cpol),
        .cpha       (cpha),
        .data_in    (data_in),
        .dvsr       (dvsr),
        .slave_sel  (slave_sel),
        .miso       (miso),
        .mosi       (mosi),
        .sclk       (sclk),
        .data_out   (data_out),
        .cs         (cs),
        .busy       (busy),
        .done       (done)
    );

    always #5 clk = ~clk;

    task reset_dut;
        begin
            reset     = 0;
            start     = 0;
            cpol      = 0;
            cpha      = 0;
            data_in   = 32'h0;
            dvsr      = 4'd2;
            slave_sel = 2'd0;
            #20;
            reset = 1;
            #20;
        end
    endtask

    task do_transaction(input [31:0] din, input cpol_v, input cpha_v,
                         input [3:0] dvsr_v, input [1:0] ssel);
        begin
            data_in   = din;
            cpol      = cpol_v;
            cpha      = cpha_v;
            dvsr      = dvsr_v;
            slave_sel = ssel;
            start     = 1;
            #10;
            start = 0;

            wait (done == 1'b1);
            #10;

            $display("din=%h  cpol=%b cpha=%b dvsr=%0d ssel=%0d  dout=%h  %s",
                       din, cpol_v, cpha_v, dvsr_v, ssel, data_out,
                       (data_out === din) ? "PASS" : "FAIL");

            #20;
        end
    endtask

    initial begin
        $dumpfile("master_tb.vcd");
        $dumpvars(0, master_tb);
        clk = 0;
        reset_dut();

        do_transaction(32'h0001_0092, 1'b0, 1'b0, 4'd2, 2'd0); // CPOL0 CPHA0
        do_transaction(32'h1234_5678, 1'b0, 1'b1, 4'd3, 2'd1); // CPOL0 CPHA1
        do_transaction(32'h74a0_0980, 1'b1, 1'b0, 4'd1, 2'd2); // CPOL1 CPHA0
        do_transaction(32'h0392_1733, 1'b1, 1'b1, 4'd0, 2'd3); // CPOL1 CPHA1

        $stop;
    end

endmodule