

module dma_controller #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter STRB_WIDTH = DATA_WIDTH / 8,
    parameter FIFO_DEPTH = 32
) (
    input wire clk,
    input wire rst_n,


    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [ 7:0] paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready,

    output wire irq,


    output wire [ADDR_WIDTH-1:0] m_axi_awaddr,
    output wire [           7:0] m_axi_awlen,
    output wire [           2:0] m_axi_awsize,
    output wire [           1:0] m_axi_awburst,
    output wire [  ID_WIDTH-1:0] m_axi_awid,
    output wire                  m_axi_awvalid,
    input  wire                  m_axi_awready,

    output wire [DATA_WIDTH-1:0] m_axi_wdata,
    output wire [STRB_WIDTH-1:0] m_axi_wstrb,
    output wire                  m_axi_wlast,
    output wire                  m_axi_wvalid,
    input  wire                  m_axi_wready,

    input  wire [1:0] m_axi_bresp,
    input  wire       m_axi_bvalid,
    output wire       m_axi_bready,

    output wire [ADDR_WIDTH-1:0] m_axi_araddr,
    output wire [           7:0] m_axi_arlen,
    output wire [           2:0] m_axi_arsize,
    output wire [           1:0] m_axi_arburst,
    output wire [  ID_WIDTH-1:0] m_axi_arid,
    output wire                  m_axi_arvalid,
    input  wire                  m_axi_arready,

    input  wire [DATA_WIDTH-1:0] m_axi_rdata,
    input  wire [           1:0] m_axi_rresp,
    input  wire                  m_axi_rlast,
    input  wire                  m_axi_rvalid,
    output wire                  m_axi_rready
);


  reg [31:0] reg_src_addr, reg_dst_addr, reg_length, reg_burst_size;
  reg reg_start_pulse;
  reg status_busy, status_done, status_error;

  assign pready = 1'b1;

  wire apb_write = psel && penable && pwrite;
  wire apb_read = psel && !pwrite;

  always @(posedge clk) begin
    if (!rst_n) begin
      reg_src_addr    <= 32'd0;
      reg_dst_addr    <= 32'd0;
      reg_length      <= 32'd0;
      reg_burst_size  <= 32'd4;
      reg_start_pulse <= 1'b0;
    end else begin
      reg_start_pulse <= 1'b0;
      if (apb_write) begin
        case (paddr[7:2])
          6'h0:    reg_src_addr <= pwdata;
          6'h1:    reg_dst_addr <= pwdata;
          6'h2:    reg_length <= pwdata;
          6'h3:    reg_burst_size <= pwdata;
          6'h4:    reg_start_pulse <= pwdata[0];
          default: ;
        endcase
      end
    end
  end

  always @(*) begin
    case (paddr[7:2])
      6'h0: prdata = reg_src_addr;
      6'h1: prdata = reg_dst_addr;
      6'h2: prdata = reg_length;
      6'h3: prdata = reg_burst_size;
      6'h4: prdata = 32'd0;
      6'h5: prdata = {29'd0, status_error, status_done, status_busy};
      default: prdata = 32'd0;
    endcase
  end


  wire start_write, start_read;
  wire [31:0] m_addr;
  wire [ 7:0] m_len;
  wire write_done, read_done, m_error, master_busy;

  wire wdata_valid, wdata_ready;
  wire [31:0] wdata;

  wire rdata_valid, rdata_ready, rdata_last;
  wire [31:0] rdata;

  reg [31:0] cur_src, cur_dst;
  reg [31:0] words_remaining;
  reg [ 7:0] chunk_beats;
  reg dma_start_write, dma_start_read;
  reg [31:0] dma_addr;
  reg [ 7:0] dma_len;

  assign start_write = dma_start_write;
  assign start_read  = dma_start_read;
  assign m_addr      = dma_addr;
  assign m_len       = dma_len;

  axi_full_master #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .DATA_WIDTH(DATA_WIDTH),
      .ID_WIDTH  (ID_WIDTH)
  ) u_axi_master (
      .clk(clk),
      .rst_n(rst_n),
      .start_write(start_write),
      .start_read(start_read),
      .m_addr(m_addr),
      .m_len(m_len),
      .write_done(write_done),
      .read_done(read_done),
      .m_error(m_error),
      .master_busy(master_busy),
      .wdata_valid(wdata_valid),
      .wdata(wdata),
      .wstrb(4'hF),
      .wdata_ready(wdata_ready),
      .rdata_valid(rdata_valid),
      .rdata(rdata),
      .rdata_last(rdata_last),
      .rdata_ready(rdata_ready),
      .m_axi_awaddr(m_axi_awaddr),
      .m_axi_awlen(m_axi_awlen),
      .m_axi_awsize(m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awid(m_axi_awid),
      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awready(m_axi_awready),
      .m_axi_wdata(m_axi_wdata),
      .m_axi_wstrb(m_axi_wstrb),
      .m_axi_wlast(m_axi_wlast),
      .m_axi_wvalid(m_axi_wvalid),
      .m_axi_wready(m_axi_wready),
      .m_axi_bresp(m_axi_bresp),
      .m_axi_bvalid(m_axi_bvalid),
      .m_axi_bready(m_axi_bready),
      .m_axi_araddr(m_axi_araddr),
      .m_axi_arlen(m_axi_arlen),
      .m_axi_arsize(m_axi_arsize),
      .m_axi_arburst(m_axi_arburst),
      .m_axi_arid(m_axi_arid),
      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arready(m_axi_arready),
      .m_axi_rdata(m_axi_rdata),
      .m_axi_rresp(m_axi_rresp),
      .m_axi_rlast(m_axi_rlast),
      .m_axi_rvalid(m_axi_rvalid),
      .m_axi_rready(m_axi_rready)
  );

  wire fifo_wr_en, fifo_rd_en;
  wire [31:0] fifo_rd_data;
  wire [$clog2(FIFO_DEPTH):0] fifo_count;
  wire fifo_full, fifo_empty;


  assign fifo_wr_en  = rdata_valid && !fifo_full;
  assign rdata_ready = !fifo_full;


  assign wdata_valid = !fifo_empty;
  assign wdata       = fifo_rd_data;
  assign fifo_rd_en  = wdata_valid && wdata_ready;

  sync_fifo #(
      .DEPTH(FIFO_DEPTH),
      .WIDTH(32)
  ) u_fifo (
      .clk(clk),
      .rst_n(rst_n),
      .wr_en(fifo_wr_en),
      .wr_data(rdata),
      .rd_en(fifo_rd_en),
      .rd_data(fifo_rd_data),
      .count(fifo_count),
      .full(fifo_full),
      .empty(fifo_empty)
  );


  localparam D_IDLE        = 3'd0;
  localparam D_ISSUE_READ  = 3'd1;
  localparam D_WAIT_READ   = 3'd2;
  localparam D_ISSUE_WRITE = 3'd3;
  localparam D_WAIT_WRITE  = 3'd4;
  localparam D_NEXT        = 3'd5;
  localparam D_DONE        = 3'd6;

  reg [2:0] dstate, dnext;

  always @(posedge clk) begin
    if (!rst_n) dstate <= D_IDLE;
    else dstate <= dnext;
  end

  always @(*) begin
    dnext = dstate;
    case (dstate)
      D_IDLE:        if (reg_start_pulse && reg_length != 0) dnext = D_ISSUE_READ;
      D_ISSUE_READ:  dnext = D_WAIT_READ;
      D_WAIT_READ:   if (read_done) dnext = D_ISSUE_WRITE;
      D_ISSUE_WRITE: dnext = D_WAIT_WRITE;
      D_WAIT_WRITE:  if (write_done) dnext = D_NEXT;
      D_NEXT:        dnext = (words_remaining <= chunk_beats) ? D_DONE : D_ISSUE_READ;
      D_DONE:        dnext = D_IDLE;
      default:       dnext = D_IDLE;
    endcase
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      cur_src         <= 32'd0;
      cur_dst         <= 32'd0;
      words_remaining <= 32'd0;
      chunk_beats     <= 8'd0;
      dma_start_write <= 1'b0;
      dma_start_read  <= 1'b0;
      dma_addr        <= 32'd0;
      dma_len         <= 8'd0;
    end else begin
      dma_start_write <= 1'b0;
      dma_start_read  <= 1'b0;

      case (dstate)
        D_IDLE: begin
          if (reg_start_pulse && reg_length != 0) begin
            cur_src         <= reg_src_addr;
            cur_dst         <= reg_dst_addr;
            words_remaining <= reg_length;
          end
        end

        D_ISSUE_READ: begin
          chunk_beats <= (words_remaining >= reg_burst_size[7:0])
                                      ? reg_burst_size[7:0]
                                      : words_remaining[7:0];
          dma_addr <= cur_src;

          dma_len         <= (words_remaining >= reg_burst_size[7:0])
                                          ? (reg_burst_size[7:0] - 8'd1)
                                          : (words_remaining[7:0] - 8'd1);
          dma_start_read <= 1'b1;
        end

        D_ISSUE_WRITE: begin
          dma_addr        <= cur_dst;
          dma_len         <= chunk_beats - 8'd1;
          dma_start_write <= 1'b1;
        end

        D_NEXT: begin
          cur_src         <= cur_src + (chunk_beats << 2);
          cur_dst         <= cur_dst + (chunk_beats << 2);
          words_remaining <= words_remaining - chunk_beats;
        end

        default: ;
      endcase
    end
  end




  assign irq = (dstate == D_DONE);

  always @(posedge clk) begin
    if (!rst_n) begin
      status_busy  <= 1'b0;
      status_done  <= 1'b0;
      status_error <= 1'b0;
    end else begin
      if (dstate == D_IDLE && reg_start_pulse && reg_length != 0) begin
        status_busy  <= 1'b1;
        status_done  <= 1'b0;
        status_error <= 1'b0;
      end
      if (m_error) status_error <= 1'b1;
      if (dstate == D_DONE) begin
        status_busy <= 1'b0;
        status_done <= 1'b1;
      end
    end
  end

endmodule
