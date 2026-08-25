module AHB_Slave_2 #(
    parameter MEM_WIDTH = 8,
    parameter MEM_DEPTH = 64
) (
    input HCLK,
    input HRESETn,

    // Input from master
    input [31:0] HADDR,
    input [31:0] HWDATA,

    // Input from decoder
    input [1:0] HSELx_slaves,

    // Control signals
    input HWRITE,
    input [2:0] HSIZE,
    input [1:0] HTRANS,
    input [2:0] HBURST,
    input HREADY,

    // Outputs to MUX
    output reg HREADYOUT,
    output reg HRESP,
    output reg [31:0] HRDATA
);

  // FSM States
  // Internal state encoding
  parameter IDLE = 2'b00;
  parameter WRITE = 2'b01;
  parameter READ = 2'b10;

  reg [1:0] curr_state;  // Current state
  reg [1:0] next_state;  // Next state

  // Memory_2 declaration
  reg [MEM_WIDTH-1:0] memory_2[MEM_DEPTH-1:0];

  // Internal registers for address phase capture
  reg [31:0] HADDR_reg;
  reg HWRITE_reg;
  reg [2:0] HSIZE_reg;
  reg [1:0] HTRANS_reg;
  reg [2:0] HBURST_reg;

  // internal signlas
  reg [31:0] HADDR_Half;  // address that incerements the HADDR by 1 to write 16 bits
  reg [31:0] HADDR_Full_1;  // address that incerements the HADDR by 1 to write 32 bits
  reg [31:0] HADDR_Full_2;  // address that incerements the HADDR by 2 to write 32 bits
  reg [31:0] HADDR_Full_3;  // address that incerements the HADDR by 3 to write 32 bits

  // FSM Sequential Logic
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) curr_state <= IDLE;
    else curr_state <= next_state;
  end

  // FSM Combinational Logic
  always @("*") begin
    next_state = curr_state;
    case (curr_state)
      IDLE: begin
        if (HREADY && HSELx_slaves == 2'b01 && (HTRANS == 2'b10 || HTRANS == 2'b11)) begin
          if (HWRITE) next_state = WRITE;
          else next_state = READ;
        end
      end
      WRITE: begin
        if (!(HTRANS == 2'b10 || HTRANS == 2'b11))
          next_state = IDLE;  // If not in valid transfer state, go to IDLE
        else if (!HWRITE) next_state = READ;
        else next_state = WRITE;
      end
      READ: begin
        if (!(HTRANS == 2'b10 || HTRANS == 2'b11)) next_state = IDLE;
        else if (HWRITE) next_state = WRITE;  // If write request comes, switch to WRITE state
        else next_state = READ;
      end
    endcase
  end


  // output logic
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      HRDATA    <= 32'h0;
      HREADYOUT <= 1'b1;
      HRESP     <= 1'b0;
    end else begin

      if (next_state == READ) begin
        if ((HBURST == 3'b000 || HBURST == 3'b001)) begin
          case (HSIZE)
            3'b000: begin  // 8-bit
              HRDATA <= {24'h000000, memory_2[HADDR[29:0]]};  // Read 8 bits from memory_2
            end
            3'b001: begin  // 16-bit
              HRDATA <= {
                16'h0000, memory_2[HADDR_Half], memory_2[HADDR[29:0]]
              };  // Read 16 bits from memory_2
            end
            3'b010: begin  // 32-bit
              HRDATA <= {
                memory_2[HADDR_Full_3],
                memory_2[HADDR_Full_2],
                memory_2[HADDR_Full_1],
                memory_2[HADDR[29:0]]
              };  // Read 32 bits from memory_2
            end
          endcase
        end
      end else if (curr_state == WRITE) begin
        if ((HBURST_reg == 3'b000 || HBURST_reg == 3'b001)) begin
          case (HSIZE_reg)
            3'b000: begin  // 8-bit
              memory_2[HADDR_reg[29:0]] <= HWDATA[7:0];
            end
            3'b001: begin  // 16-bit
              memory_2[HADDR_reg[29:0]] <= HWDATA[7:0];  // Write 8 bits to memory_2
              memory_2[HADDR_Half] <= HWDATA[15:8];  // Write next 8 bits to memory_2
            end
            3'b010: begin  // 32-bit
              memory_2[HADDR_reg[29:0]] <= HWDATA[7:0];  // Write first 8 bits to memory_2
              memory_2[HADDR_Full_1] <= HWDATA[15:8];  // Write next 8 bits to memory_2
              memory_2[HADDR_Full_2] <= HWDATA[23:16];  // Write next 8 bits to memory_2
              memory_2[HADDR_Full_3] <= HWDATA[31:24];  // Write last 8 bits to memory_2
            end
          endcase
        end
      end

    end

  end


  // always block for address to respect address phase and data phase and to enable pipelining in the address
  always @(posedge HCLK) begin
    if (HREADY && HSELx_slaves == 2'b01) begin  // so if not ready the value of the prev. address will be stored in HADDR_reg (wait states)
      HADDR_reg  <= HADDR;
      HWRITE_reg <= HWRITE;
      HSIZE_reg  <= HSIZE;
      HTRANS_reg <= HTRANS;
      HBURST_reg <= HBURST;
    end
  end


  // always block for address managing to respect wait states
  always @(*) begin
    if (HREADY) begin
      // write transfer
      if (HWRITE) begin
        HADDR_Half   = HADDR_reg[29:0] + 1;  // Half address for 16 bits transfer, incerement by 1 
        HADDR_Full_1 = HADDR_reg[29:0] + 1;  // Full address for 32 bits transfer, incerement by 1
        HADDR_Full_2 = HADDR_reg[29:0] + 2;  // Full address for 32 bits transfer incerement by 2
        HADDR_Full_3 = HADDR_reg[29:0] + 3;  // Full address for 32 bits transfer, incerement by 3
      end  // read transfer
      else begin
        HADDR_Half   = HADDR[29:0] + 1;  // Half address for 16 bits transfer, incerement by 1 
        HADDR_Full_1 = HADDR[29:0] + 1;  // Full address for 32 bits transfer, incerement by 1
        HADDR_Full_2 = HADDR[29:0] + 2;  // Full address for 32 bits transfer incerement by 2
        HADDR_Full_3 = HADDR[29:0] + 3;  // Full address for 32 bits transfer, incerement by 3
      end
    end
  end
endmodule
