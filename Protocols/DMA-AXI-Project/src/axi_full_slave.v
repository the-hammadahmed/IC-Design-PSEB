
module axi_full_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter STRB_WIDTH = DATA_WIDTH / 8,
    parameter MEM_WORDS  = 4096
) (
    input wire clk,
    input wire rst_n,


    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [           7:0] s_axi_awlen,
    input  wire [           2:0] s_axi_awsize,
    input  wire [           1:0] s_axi_awburst,
    input  wire [  ID_WIDTH-1:0] s_axi_awid,
    input  wire                  s_axi_awvalid,
    output wire                  s_axi_awready,


    input  wire [DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [STRB_WIDTH-1:0] s_axi_wstrb,
    input  wire                  s_axi_wlast,
    input  wire                  s_axi_wvalid,
    output wire                  s_axi_wready,


    output wire [         1:0] s_axi_bresp,
    output wire [ID_WIDTH-1:0] s_axi_bid,
    output wire                s_axi_bvalid,
    input  wire                s_axi_bready,


    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [           7:0] s_axi_arlen,
    input  wire [           2:0] s_axi_arsize,
    input  wire [           1:0] s_axi_arburst,
    input  wire [  ID_WIDTH-1:0] s_axi_arid,
    input  wire                  s_axi_arvalid,
    output wire                  s_axi_arready,


    output wire [DATA_WIDTH-1:0] s_axi_rdata,
    output wire [           1:0] s_axi_rresp,
    output wire [  ID_WIDTH-1:0] s_axi_rid,
    output wire                  s_axi_rlast,
    output wire                  s_axi_rvalid,
    input  wire                  s_axi_rready
);

  localparam S_IDLE = 2'd0;
  localparam S_WDATA = 2'd1;
  localparam S_WRESP = 2'd2;
  localparam S_RDATA = 2'd3;

  localparam [1:0] RESP_OKAY = 2'b00;
  localparam [1:0] RESP_SLVERR = 2'b10;

  reg [1:0] state, next_state;

  reg [ADDR_WIDTH-1:0] cur_waddr, cur_raddr;
  reg [7:0] awlen_reg, arlen_reg;
  reg [7:0] wbeat_cnt, rbeat_cnt;
  reg [ID_WIDTH-1:0] awid_reg, arid_reg;
  reg                  werror_reg;

  reg [DATA_WIDTH-1:0] mem        [0:MEM_WORDS-1];


  assign s_axi_awready = (state == S_IDLE);
  assign s_axi_arready = (state == S_IDLE) && !s_axi_awvalid;

  wire aw_hs = s_axi_awvalid && s_axi_awready;
  wire ar_hs = s_axi_arvalid && s_axi_arready;
  wire w_hs = s_axi_wvalid && s_axi_wready;
  wire b_hs = s_axi_bvalid && s_axi_bready;
  wire r_hs = s_axi_rvalid && s_axi_rready;

  always @(posedge clk) begin
    if (!rst_n) state <= S_IDLE;
    else state <= next_state;
  end

  always @(*) begin
    next_state = state;
    case (state)
      S_IDLE: begin
        if (aw_hs) next_state = S_WDATA;
        else if (ar_hs) next_state = S_RDATA;
      end
      S_WDATA: if (w_hs && s_axi_wlast) next_state = S_WRESP;
      S_WRESP: if (b_hs) next_state = S_IDLE;
      S_RDATA: if (r_hs && (rbeat_cnt == arlen_reg)) next_state = S_IDLE;
      default: next_state = S_IDLE;
    endcase
  end


  integer bi;
  reg [DATA_WIDTH-1:0] wmask_data;
  always @(*) begin
    wmask_data = mem[cur_waddr>>2];
    for (bi = 0; bi < STRB_WIDTH; bi = bi + 1) begin
      if (s_axi_wstrb[bi]) wmask_data[bi*8+:8] = s_axi_wdata[bi*8+:8];
    end
  end


  always @(posedge clk) begin
    if (!rst_n) begin
      cur_waddr  <= {ADDR_WIDTH{1'b0}};
      cur_raddr  <= {ADDR_WIDTH{1'b0}};
      awlen_reg  <= 8'd0;
      arlen_reg  <= 8'd0;
      wbeat_cnt  <= 8'd0;
      rbeat_cnt  <= 8'd0;
      awid_reg   <= {ID_WIDTH{1'b0}};
      arid_reg   <= {ID_WIDTH{1'b0}};
      werror_reg <= 1'b0;
    end else begin
      if (aw_hs) begin
        cur_waddr  <= s_axi_awaddr;
        awlen_reg  <= s_axi_awlen;
        awid_reg   <= s_axi_awid;
        wbeat_cnt  <= 8'd0;
        werror_reg <= 1'b0;
      end else if (ar_hs) begin
        cur_raddr <= s_axi_araddr;
        arlen_reg <= s_axi_arlen;
        arid_reg  <= s_axi_arid;
        rbeat_cnt <= 8'd0;
      end else if (w_hs) begin
        if ((cur_waddr >> 2) < MEM_WORDS) begin
          mem[cur_waddr>>2] <= wmask_data;
        end else begin
          werror_reg <= 1'b1;
        end
        cur_waddr <= cur_waddr + 4;
        wbeat_cnt <= wbeat_cnt + 1'b1;
      end else if (r_hs) begin
        cur_raddr <= cur_raddr + 4;
        rbeat_cnt <= rbeat_cnt + 1'b1;
      end
    end
  end


  assign s_axi_wready = (state == S_WDATA);
  assign s_axi_bvalid = (state == S_WRESP);
  assign s_axi_bresp  = werror_reg ? RESP_SLVERR : RESP_OKAY;
  assign s_axi_bid    = awid_reg;


  wire raddr_in_range = ((cur_raddr >> 2) < MEM_WORDS);
  assign s_axi_rvalid = (state == S_RDATA);
  assign s_axi_rdata  = raddr_in_range ? mem[cur_raddr >> 2] : {DATA_WIDTH{1'b0}};
  assign s_axi_rresp  = raddr_in_range ? RESP_OKAY : RESP_SLVERR;
  assign s_axi_rlast  = (state == S_RDATA) && (rbeat_cnt == arlen_reg);
  assign s_axi_rid    = arid_reg;

endmodule
