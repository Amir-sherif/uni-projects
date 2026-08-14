module slave_tb;

  reg sclk;
	reg reset;
  reg mosi;
	reg cs  ;
	
  wire miso;
	wire done;
	
	reg [31:0] test_data;

  integer i;
	
  slave s0
  (.*);
  
  initial
  begin
  sclk = 1'b0;
  forever #5 sclk = ~sclk;
  end
	
	 initial begin
        $dumpfile("slave_tb.vcd");
        $dumpvars(0, slave_tb);
        mosi      = 1'b0;
        cs        = 1'b1;
        reset     = 1'b0;

        test_data = 32'hAB31_0092;
        #20;
        reset = 1'b1;
        #10;


        cs = 1'b0;


        for (i = 31; i >= 0; i = i - 1) begin

            // Put data on MOSI
            // before the rising edge

            mosi = test_data[i];

            // Wait for rising edge
            // Slave samples MOSI here

            @(posedge sclk);

        end

        @(negedge sclk);


       

        if (done == 1'b1)

            $display("DONE TEST: PASS");

        else

            $display("DONE TEST: FAIL");
			
			
	    if (s0.rx_reg == test_data)

            $display("RX TEST: PASS  RX = %h", s0.rx_reg );
        else

            $display("RX TEST: FAIL  Expected = %h  Got = %h", test_data, s0.rx_reg );

        cs = 1'b1;
        #20;

        $stop;

    end

endmodule
