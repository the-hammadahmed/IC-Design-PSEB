

module dma_engine #(
    parameter MEM_WORDS = 1024
) (
    input wire clk,
    input wire rst_n,

    input wire        start,
    input wire [31:0] src_addr,
    input wire [31:0] dst_addr,
    input wire [31:0] length_words,
    input wire [ 7:0] burst_size,


    output wire dma_busy,
    output reg  dma_done,
    output reg  dma_error,
    output reg  irq
);

  wire [31:0] cur_src_addr;
  wire [31:0] cur_dst_addr;
  wire        bus_read_req;
  wire        bus_write_req;
  wire        fsm_transfer_done;
  wire        fsm_transfer_active;

  reg         bus_op_done;
  reg  [31:0] read_data_buffer;

  wire        fsm_rst_n = rst_n && !dma_error;

  dma_fsm u_dma_fsm (
      .clk             (clk),
      .rst             (fsm_rst_n),
      .start_transfer  (start),
      .src_addr_init   (src_addr),
      .dst_addr_init   (dst_addr),
      .length_init     (length_words),
      .bus_op_done     (bus_op_done),
      .current_src_addr(cur_src_addr),
      .current_dst_addr(cur_dst_addr),
      .bus_read_req    (bus_read_req),
      .bus_write_req   (bus_write_req),
      .transfer_done   (fsm_transfer_done),
      .transfer_active (fsm_transfer_active),
      .read_data_buffer(read_data_buffer)
  );

  reg         mem_req;
  reg         mem_we;
  reg  [31:0] mem_addr;
  reg  [31:0] mem_wdata;
  wire [31:0] mem_rdata;
  wire        mem_ack;
  wire        mem_error_flag;

  simple_memory #(
      .MEM_WORDS(MEM_WORDS),
      .LATENCY  (1)
  ) s_mem (
      .clk      (clk),
      .rst_n    (rst_n),
      .req      (mem_req),
      .we       (mem_we),
      .addr     (mem_addr),
      .wdata    (mem_wdata),
      .rdata    (mem_rdata),
      .ack      (mem_ack),
      .mem_error(mem_error_flag)
  );

  wire        fifo_wr_en;
  wire        fifo_rd_en;
  wire [31:0] fifo_rd_data;
  wire [ 4:0] fifo_count;
  wire fifo_full, fifo_empty;

  reg req_launched;
  reg mem_req_was_read;

  assign fifo_wr_en = mem_ack && mem_req_was_read && !mem_error_flag;
  assign fifo_rd_en = bus_write_req && !fifo_empty && !req_launched;

  sync_fifo #(
      .DEPTH(16),
      .WIDTH(32)
  ) u_fifo (
      .clk    (clk),
      .rst_n  (rst_n),
      .wr_en  (fifo_wr_en),
      .wr_data(mem_rdata),
      .rd_en  (fifo_rd_en),
      .rd_data(fifo_rd_data),
      .count  (fifo_count),
      .full   (fifo_full),
      .empty  (fifo_empty)
  );


  always @(posedge clk) begin
    if (!rst_n) begin
      mem_req          <= 1'b0;
      mem_we           <= 1'b0;
      mem_addr         <= 32'd0;
      mem_wdata        <= 32'd0;
      bus_op_done      <= 1'b0;
      req_launched     <= 1'b0;
      mem_req_was_read <= 1'b0;
    end else begin
      mem_req     <= 1'b0;
      bus_op_done <= 1'b0;


      if (bus_read_req && !req_launched) begin
        mem_req          <= 1'b1;
        mem_we           <= 1'b0;
        mem_addr         <= cur_src_addr;
        mem_req_was_read <= 1'b1;
        req_launched     <= 1'b1;
      end

      if (bus_write_req && !fifo_empty && !req_launched) begin
        mem_req          <= 1'b1;
        mem_we           <= 1'b1;
        mem_addr         <= cur_dst_addr;
        mem_wdata        <= fifo_rd_data;
        mem_req_was_read <= 1'b0;
        req_launched     <= 1'b1;
      end

      if (mem_ack) begin
        bus_op_done  <= 1'b1;
        req_launched <= 1'b0;
      end
    end
  end


  always @(posedge clk) begin
    if (!rst_n) read_data_buffer <= 32'd0;
    else if (mem_ack && mem_req_was_read) read_data_buffer <= mem_rdata;
  end

  reg  [7:0] burst_word_cnt;
  reg  [2:0] burst_stall_cnt;
  wire       in_burst_stall = (burst_stall_cnt != 0);

  always @(posedge clk) begin
    if (!rst_n) begin
      burst_word_cnt  <= 8'd0;
      burst_stall_cnt <= 3'd0;
    end else begin
      if (start) begin
        burst_word_cnt  <= 8'd0;
        burst_stall_cnt <= 3'd0;
      end else if (fsm_transfer_done) begin
        burst_word_cnt <= 8'd0;
      end else if (mem_ack && !mem_req_was_read) begin

        if (burst_word_cnt + 1 >= burst_size && burst_size != 0) begin
          burst_word_cnt  <= 8'd0;
          burst_stall_cnt <= 3'd2;
        end else begin
          burst_word_cnt <= burst_word_cnt + 1'b1;
        end
      end else if (in_burst_stall) begin
        burst_stall_cnt <= burst_stall_cnt - 1'b1;
      end
    end
  end

  assign dma_busy = fsm_transfer_active;

  always @(posedge clk) begin
    if (!rst_n) begin
      dma_done  <= 1'b0;
      dma_error <= 1'b0;
      irq       <= 1'b0;
    end else begin
      irq <= 1'b0;

      if (start) begin
        dma_done  <= 1'b0;
        dma_error <= 1'b0;
      end

      if (mem_ack && mem_error_flag) begin
        dma_error <= 1'b1;
      end

      if (fsm_transfer_done) begin
        dma_done <= 1'b1;
        irq      <= 1'b1;
      end
    end
  end

endmodule
