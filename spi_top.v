module spi_top (
    input  wire        PCLK,
    input  wire        PRESETn,

    // APB Interface
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [3:0]  PADDR,
    input  wire [31:0] PWDATA,

    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,

    // SPI Clock and Chip Select (debug / observability)
    output wire        SCLK,
    output wire [3:0]  CS,

    // Per-slave RX done flags (debug / observability)
    output wire [3:0]  slave_done
);

    wire [31:0] tx_data;
    wire [31:0] rx_data;

    wire        start;
    wire        cpol;
    wire        cpha;

    wire [1:0]  slave_sel;
    wire [3:0]  dvsr;

    wire        busy;
    wire        done;

    wire        master_miso;
    wire        master_mosi;

    // Individual slave MISO lines
    wire        miso0, miso1, miso2, miso3;

    // APB SPI INTERFACE
    apb_spi_interface U1 (
        .PCLK      (PCLK),
        .PRESETn   (PRESETn),

        .PSEL      (PSEL),
        .PENABLE   (PENABLE),
        .PWRITE    (PWRITE),

        .PADDR     (PADDR),
        .PWDATA    (PWDATA),

        .PRDATA    (PRDATA),
        .PREADY    (PREADY),
        .PSLVERR   (PSLVERR),

        .tx_data   (tx_data),
        .rx_data   (rx_data),

        .start     (start),
        .cpol      (cpol),
        .cpha      (cpha),

        .slave_sel (slave_sel),
        .dvsr      (dvsr),

        .busy      (busy),
        .done      (done)
    );

    // SPI MASTER
    master U2 (
        .clk       (PCLK),
        .reset     (PRESETn),

        .start     (start),
        .cpol      (cpol),
        .cpha      (cpha),

        .data_in   (tx_data),
        .dvsr      (dvsr),
        .slave_sel (slave_sel),

        .miso      (master_miso),
        .mosi      (master_mosi),
        .sclk      (SCLK),

        .data_out  (rx_data),
        .cs        (CS),

        .busy      (busy),
        .done      (done)
    );

    // SPI SLAVE 0
    slave S0 (
        .sclk  (SCLK),
        .reset (PRESETn),
        .mosi  (master_mosi),
        .miso  (miso0),
        .done  (slave_done[0]),
        .cs    (CS[0])
    );

    // SPI SLAVE 1
    slave S1 (
        .sclk  (SCLK),
        .reset (PRESETn),
        .mosi  (master_mosi),
        .miso  (miso1),
        .done  (slave_done[1]),
        .cs    (CS[1])
    );

    // SPI SLAVE 2
    slave S2 (
        .sclk  (SCLK),
        .reset (PRESETn),
        .mosi  (master_mosi),
        .miso  (miso2),
        .done  (slave_done[2]),
        .cs    (CS[2])
    );

    // SPI SLAVE 3
    slave S3 (
        .sclk  (SCLK),
        .reset (PRESETn),
        .mosi  (master_mosi),
        .miso  (miso3),
        .done  (slave_done[3]),
        .cs    (CS[3])
    );

    // MISO MULTIPLEXER
    // Select MISO from the active (chip-selected) slave
    assign master_miso = (CS == 4'b1110) ? miso0 :
                          (CS == 4'b1101) ? miso1 :
                          (CS == 4'b1011) ? miso2 :
                          (CS == 4'b0111) ? miso3 :
                                             1'b0;

endmodule
