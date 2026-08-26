

module simple_memory #(
    parameter MEM_WORDS = 1024,
    parameter LATENCY   = 1
) (
    input wire clk,
    input wire rst_n,

    input wire        req,
    input wire        we,
    input wire [31:0] addr,
    input wire [31:0] wdata,

    output reg [31:0] rdata,
    output reg        ack,
    output reg        mem_error  //when out of range
);

  reg  [31:0] memory [0:MEM_WORDS-1];

  reg  [ 3:0] wait_cnt;
  reg         busy;

  wire [31:0] word_addr = addr >> 2;
  wire        in_range = (word_addr < MEM_WORDS) && (addr[1:0] == 2'b00);

  always @(posedge clk) begin
    if (!rst_n) begin
      ack       <= 1'b0;
      mem_error <= 1'b0;
      busy      <= 1'b0;
      wait_cnt  <= 4'd0;
      rdata     <= 32'd0;
    end else begin
      ack <= 1'b0;

      if (req && !busy) begin
        if (!in_range) begin
          mem_error <= 1'b1;
          ack       <= 1'b1;
        end else begin
          busy     <= 1'b1;
          wait_cnt <= LATENCY[3:0];
        end
      end else if (busy) begin
        if (wait_cnt == 0) begin
          if (we) begin
            memory[word_addr] <= wdata;
          end else begin
            rdata <= memory[word_addr];
          end
          ack  <= 1'b1;
          busy <= 1'b0;
        end else begin
          wait_cnt <= wait_cnt - 1'b1;
        end
      end
    end
  end

endmodule
