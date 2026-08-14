module apb_spi_interface (
    input         PCLK,
    input         PRESETn,

    input         PSEL,
    input         PENABLE,
    input         PWRITE,

    input  [3:0]  PADDR,
    input  [31:0] PWDATA,

    output reg [31:0] PRDATA,
    output            PREADY,
    output            PSLVERR,

    // INTERFACE TO SPI MASTER

    output reg [31:0] tx_data,
    input      [31:0] rx_data,

    output reg        start,
    output reg        cpol,
    output reg        cpha,

    output reg [1:0]  slave_sel,
    output reg [3:0]  dvsr,

    input             busy,
    input             done

);
    // APB RESPONSE

    
    assign PREADY = 1'b1;

    // No error 
    assign PSLVERR = 1'b0;


    // APB WRITE

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            tx_data   <= 32'b0;

            start     <= 1'b0;

            cpol      <= 1'b0;
            cpha      <= 1'b0;

            slave_sel <= 2'b00;

            dvsr      <= 4'b0000;

        end

        else begin

            // START is a one-clock pulse.
            start <= 1'b0;

            // APB write transfer
            if (PSEL && PENABLE && PWRITE) begin

                case (PADDR)

                   
                    // TX_DATA
                  

                    4'h0: begin
                        tx_data <= PWDATA;
                    end


                    
                    // CTRL
                   

                    4'h8: begin


                        start     <= PWDATA[0];

                        cpol      <= PWDATA[1];

                        cpha      <= PWDATA[2];

                        slave_sel <= PWDATA[4:3];

                        dvsr      <= PWDATA[8:5];

                    end


                    default: begin
                        // don't do any thing
                    end

                endcase

            end

        end

    end


   
    // APB READ

    always @(*) begin

        PRDATA = 32'b0;

        if (PSEL && PENABLE && !PWRITE) begin

            case (PADDR)

                // RX_DATA

                4'h4: begin

                    PRDATA = rx_data;

                end
    
                   // CTRL
              
                4'h8: begin

                    PRDATA = 32'b0;

                    PRDATA[0]   = 1'b0;
                    PRDATA[1]   = cpol;
                    PRDATA[2]   = cpha;
                    PRDATA[4:3] = slave_sel;
                    PRDATA[8:5] = dvsr;

                end


               
                // STATUS
               
                4'hC: begin

                   

                    PRDATA = 32'b0;

                    PRDATA[0] = busy;
                    PRDATA[1] = done;

                end


                default: begin

                    PRDATA = 32'b0;

                end

            endcase

        end

    end

endmodule