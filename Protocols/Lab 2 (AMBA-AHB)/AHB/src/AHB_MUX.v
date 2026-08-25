module AHB_MUX (
    // inputs from slave 1
    input HRESP_Slave_1, // response from first slave
    input HREADYOUT_1, // ready signal from first slave
    input [31:0] HRDATA_Slave_1, // read data from first slave

    // inputs from slave 2
    input HRESP_Slave_2, // response from second slave
    input HREADYOUT_2, // ready signal from second slave
    input [31:0] HRDATA_Slave_2, // read data from second slave


    // inputs from decoder
    input [1:0] HSELx_Mux, // Slave select signal

    // outputs
    output reg [31:0] HRDATA,
    output reg HREADY,
    output reg HRESP
);
    // to select between multiple slaves (we will insert more slaves later) 
    always @(*) begin
	HRDATA = 32'h00000000;
	HREADY = 1'b1;
	HRESP = 1'b1;

        case (HSELx_Mux)
            2'b00: begin
                HRDATA = HRDATA_Slave_1; // Read data from first slave
                HREADY = HREADYOUT_1; // Ready signal from mux ( to indicate the completeness of the transfer for other Slaves)
                HRESP = HRESP_Slave_1; // Response from first slave
            end
            2'b01: begin
                HRDATA = HRDATA_Slave_2; // Read data from first slave
                HREADY = HREADYOUT_2; // Ready signal from mux ( to indicate the completeness of the transfer for other Slaves)
                HRESP = HRESP_Slave_2; // Response from first slave
            end
            default: begin
                HRDATA = 32'h00000000; // Default case, can be modified as needed
                HREADY = 1'b1; // Default ready signal
                HRESP = 1'b1; // Default response signal
            end
        endcase
    end
endmodule
