module slave 
	(
    input wire sclk,reset,
    input wire mosi,
    output reg miso,done,
    input wire cs     
    );


    reg [5:0] bit_cnt;
    reg [31:0] rx_reg;

    

  always @(posedge sclk , negedge reset) begin
      if (!reset) rx_reg <= 0; // Clear receive register on reset
       else 
	   begin
	   
         if (!cs) 
	      begin // Active low chip select 
            rx_reg <= {rx_reg[30:0], mosi}; // Shift in MOSI data
          end
       end
      
        
  end
  always@(negedge sclk , negedge reset) begin
    if (!reset)
   	 begin
        bit_cnt <= 0;
        miso <= 0;
        done <= 0; // Clear done on reset
     end 
    else 
	 begin
 		if (!cs) begin

                // Send current LSB
                miso <= rx_reg[0];

                if (bit_cnt == 6'd31) 
				 begin

                    bit_cnt <= 6'd0;

                    done <= 1'b1;
                 end

                else 
				 begin

                    bit_cnt <= bit_cnt + 1'b1;
                    done <= 1'b0;

                 end

            end

        else 
			begin
                // Slave is not selected

                bit_cnt <= 6'd0;

                miso <= 1'b0;

                done <= 1'b0;

            end

        end

    end


endmodule