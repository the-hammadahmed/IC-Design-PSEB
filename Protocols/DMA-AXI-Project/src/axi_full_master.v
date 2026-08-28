

module axi_full_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter STRB_WIDTH = DATA_WIDTH / 8
) (
    input wire clk,
    input wire rst_n,

    input wire                  start_write,
    input wire                  start_read,
    input wire [ADDR_WIDTH-1:0] m_addr,
    input wire [           7:0] m_len,

    output reg  write_done,
    output reg  read_done,
    output reg  m_error,
    output wire master_busy,

    input  wire                  wdata_valid,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire [STRB_WIDTH-1:0] wstrb,
    output wire                  wdata_ready,

    output wire                  rdata_valid,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire                  rdata_last,
    input  wire                  rdata_ready,

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

  localparam       S_IDLE     = 3'd0;
  localparam       S_AW       = 3'd1;
  localparam       S_WDATA    = 3'd2;
  localparam       S_BRESP    = 3'd3;
  localparam       S_AR       = 3'd4;
  localparam       S_RDATA    = 3'd5;

  localparam [1:0] BURST_INCR = 2'b01;
  localparam [2:0] SIZE_4B    = 3'b010;

  reg [2:0] state, next_state;

  reg [ADDR_WIDTH-1:0] awaddr_reg, araddr_reg;
  reg [7:0] awlen_reg, arlen_reg;
  reg [7:0] wbeat_cnt;



  always @(posedge clk) begin
    if (!rst_n) state <= S_IDLE;
    else state <= next_state;
  end

  wire aw_hs = m_axi_awvalid && m_axi_awready;
  wire w_hs = m_axi_wvalid && m_axi_wready;
  wire b_hs = m_axi_bvalid && m_axi_bready;
  wire ar_hs = m_axi_arvalid && m_axi_arready;
  wire r_hs = m_axi_rvalid && m_axi_rready;

  always @(*) begin
    next_state = state;
    case (state)
      S_IDLE: begin
        if (start_write) next_state = S_AW;
        else if (start_read) next_state = S_AR;
      end
      S_AW:    if (aw_hs) next_state = S_WDATA;
      S_WDATA: if (w_hs && m_axi_wlast) next_state = S_BRESP;
      S_BRESP: if (b_hs) next_state = S_IDLE;
      S_AR:    if (ar_hs) next_state = S_RDATA;
      S_RDATA: if (r_hs && m_axi_rlast) next_state = S_IDLE;
      default: next_state = S_IDLE;
    endcase
  end

  assign master_busy = (state != S_IDLE);


  always @(posedge clk) begin
    if (!rst_n) begin
      awaddr_reg <= {ADDR_WIDTH{1'b0}};
      awlen_reg  <= 8'd0;
      araddr_reg <= {ADDR_WIDTH{1'b0}};
      arlen_reg  <= 8'd0;
      wbeat_cnt  <= 8'd0;
    end else begin
      if (state == S_IDLE && start_write) begin
        awaddr_reg <= m_addr;
        awlen_reg  <= m_len;
        wbeat_cnt  <= 8'd0;
      end else if (state == S_IDLE && start_read) begin
        araddr_reg <= m_addr;
        arlen_reg  <= m_len;
      end else if (w_hs) begin
        wbeat_cnt <= wbeat_cnt + 1'b1;
      end
    end
  end


  assign m_axi_awaddr  = awaddr_reg;
  assign m_axi_awlen   = awlen_reg;
  assign m_axi_awsize  = SIZE_4B;
  assign m_axi_awburst = BURST_INCR;
  assign m_axi_awid    = {ID_WIDTH{1'b0}};
  assign m_axi_awvalid = (state == S_AW);

  assign m_axi_wdata   = wdata;
  assign m_axi_wstrb   = wstrb;
  assign m_axi_wlast   = (state == S_WDATA) && (wbeat_cnt == awlen_reg);
  assign m_axi_wvalid  = (state == S_WDATA) && wdata_valid;
  assign wdata_ready   = (state == S_WDATA) && m_axi_wready;

  assign m_axi_bready  = (state == S_BRESP);

  assign m_axi_araddr  = araddr_reg;
  assign m_axi_arlen   = arlen_reg;
  assign m_axi_arsize  = SIZE_4B;
  assign m_axi_arburst = BURST_INCR;
  assign m_axi_arid    = {ID_WIDTH{1'b0}};
  assign m_axi_arvalid = (state == S_AR);

  assign m_axi_rready  = (state == S_RDATA) && rdata_ready;
  assign rdata_valid   = (state == S_RDATA) && m_axi_rvalid;
  assign rdata         = m_axi_rdata;
  assign rdata_last    = m_axi_rlast;


  always @(posedge clk) begin
    if (!rst_n) begin
      write_done <= 1'b0;
      read_done  <= 1'b0;
      m_error    <= 1'b0;
    end else begin
      write_done <= 1'b0;
      read_done  <= 1'b0;

      if (state == S_IDLE && (start_write || start_read)) m_error <= 1'b0;

      if (state == S_BRESP && b_hs) begin
        write_done <= 1'b1;
        if (m_axi_bresp != 2'b00) m_error <= 1'b1;
      end

      if (state == S_RDATA && r_hs && m_axi_rlast) begin
        read_done <= 1'b1;
        if (m_axi_rresp != 2'b00) m_error <= 1'b1;
      end
    end
  end

endmodule
