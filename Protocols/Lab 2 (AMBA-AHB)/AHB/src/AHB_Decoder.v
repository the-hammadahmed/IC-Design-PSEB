module AHB_Decoder (
    // inputs from master
    input [31:0] HADDR,  // Address from master (Most significant two bits are used to select slave)
    // outputs
    output reg [1:0] HSELx_slaves,  // Slave select signal
    output reg [1:0] HSELx_Mux  // Slave select signal for MUX 
);
  // Decode the address to select the appropriate slave
  always @(*) begin
    case (HADDR[31:30])  // Using the two most significant bits for slave selection
      2'b00:   HSELx_slaves = 2'b00;  // Select Slave 1
      2'b01:   HSELx_slaves = 2'b01;  // Select Slave 2
      //2'b10:   HSELx_slaves = 2'b10;  // Select Slave 3
      //2'b11:   HSELx_slaves = 2'b11;  // Select Slave 4
      default: HSELx_slaves = 2'b10;  //changed prev was 2'b00 // Default case, can be modified as needed
    endcase
    HSELx_Mux = HSELx_slaves;  // Connect the slave select signal to the MUX
  end
endmodule
