
module sync_fifo #(
    parameter DEPTH = 16,
    parameter WIDTH = 32
) (
    input wire clk,
    input wire rst_n,

    input wire             wr_en,
    input wire [WIDTH-1:0] wr_data,

    input  wire             rd_en,
    output wire [WIDTH-1:0] rd_data,

    output wire [$clog2(DEPTH):0] count,
    output wire                   full,
    output wire                   empty
);

  localparam PTR_W = $clog2(DEPTH);

  reg [WIDTH-1:0] mem[0:DEPTH-1];

  reg [PTR_W-1:0] wr_ptr;
  reg [PTR_W-1:0] rd_ptr;
  reg [PTR_W:0] fifo_count;

  assign count = fifo_count;
  assign full = (fifo_count == DEPTH);
  assign empty = (fifo_count == 0);

  assign rd_data = mem[rd_ptr];

  wire do_write = wr_en && !full;
  wire do_read = rd_en && !empty;

  always @(posedge clk) begin
    if (!rst_n) begin
      wr_ptr     <= {PTR_W{1'b0}};
      rd_ptr     <= {PTR_W{1'b0}};
      fifo_count <= {(PTR_W + 1) {1'b0}};
    end else begin

      if (do_write) begin
        mem[wr_ptr] <= wr_data;
        wr_ptr      <= wr_ptr + 1'b1;
      end

      if (do_read) begin
        rd_ptr <= rd_ptr + 1'b1;
      end

      case ({
        do_write, do_read
      })
        2'b10:   fifo_count <= fifo_count + 1'b1;
        2'b01:   fifo_count <= fifo_count - 1'b1;
        default: fifo_count <= fifo_count;
      endcase
    end
  end

endmodule
