module master(
   input wire clk,
   input wire reset,
   
   // signals the the apb controls 
   // data input and the controls from the interface 
   
   input wire start,
   input wire cpol,cpha,
   
   input wire [31:0] data_in,
   input wire [3:0] dvsr, // clock divider 
   input wire [1:0] slave_sel,


   // data to the spi slave 

   input wire miso, // master in slave out 
   output reg mosi, // master out slave in  
   output reg sclk, // syncronized clock
   
   output reg [31:0] data_out,
   output reg [3:0] cs, // chip selection (slave) (active low one-cold ) 

   // status for transition 
   
   output reg busy,
   output reg done
   
);

  // FSM
  
  localparam IDLE = 2'b00,
             RUN  = 2'b01;


  reg [1:0] state;
  
  // register used in the design 
  
  reg [31:0] tx_reg;
  reg [31:0] rx_reg;

  reg [4:0] bit_cnt;
  reg [3:0] clk_cnt;

  reg cpol_reg,cpha_reg;

  reg [1:0] slave_sel_reg;
  
  
  always @(posedge clk or negedge reset) begin

        if (!reset) 
		 begin

            state         <= IDLE;

            tx_reg        <= 32'b0;
            rx_reg        <= 32'b0;

            bit_cnt       <= 5'd0;
            clk_cnt       <= 4'd0;

            cpol_reg      <= 1'b0;
            cpha_reg      <= 1'b0;

            slave_sel_reg <= 2'b00;

            data_out      <= 32'b0;

            mosi          <= 1'b0;

            sclk          <= 1'b0;

            cs            <= 4'b1111;

            busy          <= 1'b0;
            done          <= 1'b0;

         end
		 
		 else begin

            case (state)
                
                IDLE: begin
  
                    busy <= 1'b0; // flag means im ready for the operation 

                    sclk <= cpol_reg;

                    cs <= 4'b1111;
					
					if (start) // flag start to go on process the data for transaction
   					 begin

                        cpol_reg      <= cpol;
                        cpha_reg      <= cpha;  // saving the inputs for modes
                        slave_sel_reg <= slave_sel;
						
                        tx_reg <= data_in; // applying the data in the transmition register 

                        rx_reg <= 32'b0; // clear the receving register 

                                        
                        bit_cnt <= 5'd0;  // Clear counters
                        clk_cnt <= 4'd0;

                        
                        done <= 1'b0; // two flages for saying that the master is busy doing an operation 
                        busy <= 1'b1; // and the other one is to say that its not done yet 

                        // Select slave
                        case (slave_sel)

                            2'd0 : cs <= 4'b1110;
                            2'd1 : cs <= 4'b1101;
                            2'd2 : cs <= 4'b1011;
                            2'd3 : cs <= 4'b0111;

                        endcase
																		
                        // for the cpha = 0
                        // First MOSI bit must be ready
                        // before the first sampling edge.

                        if (!cpha) begin
                            mosi <= data_in[31];
                        end
                        else begin
                            mosi <= 1'b0; // cpha = 1 
                        end

                        state <= RUN;   

                    end

                end
				
				// now going to the run state after getting every thing ready 
				
				 RUN: begin

                    busy <= 1'b1;


                    // Keep selected slave in the previous state active using the slave_sel register
                    case (slave_sel_reg)

                        2'd0 : cs <= 4'b1110;
                        2'd1 : cs <= 4'b1101;
                        2'd2 : cs <= 4'b1011;
                        2'd3 : cs <= 4'b0111;

                    endcase
					
					
					 if (clk_cnt == dvsr) // clock divider for the syncronized clock sent to the slaves
					 begin

                        clk_cnt <= 4'd0;                       

                        if (sclk == cpol_reg) // means that the sclk is at the idle level 
						 begin

                            sclk <= ~sclk;


                            /*
                            CPHA = 0

                            Sample MISO on leading edge.
                            */

                            if (!cpha_reg) begin

                               rx_reg <= {rx_reg[30:0], miso};

                            end


                            /*
                            CPHA = 1

                            Change MOSI on leading edge.
                            */

                            else begin

                                mosi <= tx_reg[31];

                                tx_reg <= {tx_reg[30:0], 1'b0};

                            end

                        end 
					    
						else begin


                            sclk <= ~sclk;


                            /*
                            CPHA = 0

                            Change MOSI on trailing edge.
                            */

                            if (!cpha_reg) 
							  begin

                                tx_reg <= {tx_reg[30:0], 1'b0};

                                /*
                                If this was the last bit,
                                the transaction is finished.
                                */
								mosi <= tx_reg[30];

                                if (bit_cnt == 5'd31) 
								 begin

                                    data_out <= rx_reg;

                                    cs <= 4'b1111;

                                    busy <= 1'b0;
                                    done <= 1'b1;

                                    sclk <= cpol_reg;
                                    state <= IDLE;

                                 end

                                else begin

                                    bit_cnt <= bit_cnt + 1'b1;

                                end

                            end
							
							/*
                            CPHA = 1

                            Sample MISO on trailing edge.
                            */

                            else begin

                                rx_reg <= {rx_reg[30:0], miso};

                                
                               // Last received bit.
                                

                                if (bit_cnt == 5'd31) begin

                                    data_out <= rx_reg;

                                    cs <= 4'b1111;

                                    busy <= 1'b0;
                                    done <= 1'b1;

                                    sclk <= cpol_reg;

                                    state <= IDLE;

                                end

                                else begin

                                    bit_cnt <= bit_cnt + 1'b1;

                                end

                            end

                        end

                    end

                    else begin

                        clk_cnt <= clk_cnt + 1'b1;

                    end

                end


                default: begin

                    state <= IDLE;

                    cs <= 4'b1111;

                    busy <= 1'b0;

                end

            endcase

        end

    end

endmodule