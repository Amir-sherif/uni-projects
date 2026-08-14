`timescale 1ns/1ps

module apb_spi_interface_tb;

    // APB signals
    reg         PCLK;
    reg         PRESETn;
    reg         PSEL;
    reg         PENABLE;
    reg         PWRITE;
    reg  [3:0]  PADDR;
    reg  [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    // SPI signals
    wire [31:0] tx_data;
    reg  [31:0] rx_data;
    wire        start;
    wire        cpol;
    wire        cpha;
    wire [1:0]  slave_sel;
    wire [3:0]  dvsr;
    reg         busy;
    reg         done;


    // DUT
    apb_spi_interface DUT (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .start(start),
        .cpol(cpol),
        .cpha(cpha),
        .slave_sel(slave_sel),
        .dvsr(dvsr),
        .busy(busy),
        .done(done)
    );


    // Clock
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end


    // APB write
    task apb_write;

        input [3:0]  addr;
        input [31:0] data;

        begin

            // Setup
            #10;
            PSEL    = 1;
            PENABLE = 0;
            PWRITE  = 1;
            PADDR   = addr;
            PWDATA  = data;

            // Access
            #10;
            PENABLE = 1;

            // Complete transfer
            #10;
            PSEL    = 0;
            PENABLE = 0;
            PWRITE  = 0;
            PADDR   = 0;
            PWDATA  = 0;

            #1;

        end

    endtask


    // APB read
    task apb_read;

        input [3:0]  addr;
        input [31:0] expected;

        begin

            // Setup
            #10;
            PSEL    = 1;
            PENABLE = 0;
            PWRITE  = 0;
            PADDR   = addr;
            PWDATA  = 0;

            // Access
            #10;
            PENABLE = 1;

            #1;

            if (PRDATA == expected)
                $display("READ PASS: ADDR=%h DATA=%h",
                         addr, PRDATA);
            else
                $display("READ FAIL: ADDR=%h EXPECTED=%h GOT=%h",
                         addr, expected, PRDATA);

            // Complete transfer
            #9;
            PSEL    = 0;
            PENABLE = 0;
            PADDR   = 0;

        end

    endtask


    // Test
    initial begin

        // Initial values
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;

        rx_data = 0;
        busy    = 0;
        done    = 0;

        PRESETn = 0;


        // Reset
        #12;
        PRESETn = 1;

        #10;

        if (tx_data == 0 &&
            start == 0 &&
            cpol == 0 &&
            cpha == 0 &&
            slave_sel == 0 &&
            dvsr == 0)
            $display("RESET PASS");
        else
            $display("RESET FAIL");


        // PREADY
        if (PREADY == 1)
            $display("PREADY PASS");
        else
            $display("PREADY FAIL");


        // PSLVERR
        if (PSLVERR == 0)
            $display("PSLVERR PASS");
        else
            $display("PSLVERR FAIL");


        // Write TX_DATA
        apb_write(4'h0, 32'h1234_ABCD);

        if (tx_data == 32'h1234_ABCD)
            $display("TX_DATA WRITE PASS");
        else
            $display("TX_DATA WRITE FAIL");


        // Write CTRL
        apb_write(4'h8, 32'hE);

        if (cpol == 1 &&
            cpha == 1 &&
            slave_sel == 1 &&
            dvsr == 0)
            $display("CTRL CONFIG PASS");
        else
            $display("CTRL CONFIG FAIL");


        // Read CTRL
        apb_read(4'h8, 32'hE);


// Start

#10;
PSEL = 1;
PENABLE = 0;
PWRITE = 1;
PADDR = 8;
PWDATA = 1;

#10;
PENABLE = 1;

// Wait for write clock edge
#10;

if (start == 1)
    $display("START PASS");
else
    $display("START FAIL: start = %b", start);

// Finish APB transfer
PSEL = 0;
PENABLE = 0;
PWRITE = 0;
PADDR = 0;
PWDATA = 0;

// Wait for next clock edge
#5;

if (start == 0)
    $display("START CLEAR PASS");
else
    $display("START CLEAR FAIL: start = %b", start);
        // Read RX_DATA
        rx_data = 32'hdddd;

        apb_read(4'h4, 32'hdddd);


        // Status idle
        busy = 0;
        done = 0;

        apb_read(4'hC, 32'h0);


        // Status busy
        busy = 1;
        done = 0;

        apb_read(4'hC, 32'h1);


        // Status done
        busy = 0;
        done = 1;

        apb_read(4'hC, 32'h2);


        // Status busy and done
        busy = 1;
        done = 1;

        apb_read(4'hC, 32'h3);


        // Write RX_DATA
        rx_data = 32'h5555_AAAA;

        apb_write(4'h4, 32'hFFFF_FFFF);

        #1;

        if (rx_data == 32'h5555_AAAA)
            $display("RX_DATA READ-ONLY PASS");
        else
            $display("RX_DATA READ-ONLY FAIL");


        // Write STATUS
        busy = 1;
        done = 0;

        apb_write(4'hC, 32'hFFFF_FFFF);

        #1;

        if (busy == 1 && done == 0)
            $display("STATUS READ-ONLY PASS");
        else
            $display("STATUS READ-ONLY FAIL");


        // Invalid address
        apb_read(4'h1, 32'h0);

        #20;
        $stop;

    end

endmodule

