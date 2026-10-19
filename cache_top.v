
module cache_top #
(
    parameter ADDR_WIDTH  = 32,
    parameter DATA_WIDTH  = 32,

    parameter NUM_SETS    = 8,
    parameter NUM_WAYS    = 2,

    parameter INDEX_WIDTH = 3,
    parameter TAG_WIDTH   = 27
)
(
    input clk,
    input rst,

    //=========================================================
    // CPU Interface
    //=========================================================

    input cpu_req,
    input cpu_rw,

    input  [ADDR_WIDTH-1:0] cpu_addr,
    input  [DATA_WIDTH-1:0] cpu_wdata,

    output [DATA_WIDTH-1:0] cpu_rdata,
    output cpu_ready
);

    //---------------------------------------------------------
    // TAG ARRAY SIGNALS
    //---------------------------------------------------------

    wire [INDEX_WIDTH-1:0] tag_rd_index;

    wire [TAG_WIDTH-1:0] tag_way0;
    wire [TAG_WIDTH-1:0] tag_way1;

    wire valid_way0;
    wire valid_way1;

    wire dirty_way0;
    wire dirty_way1;

    wire tag_write_en;
    wire tag_write_way;

    wire [INDEX_WIDTH-1:0] tag_wr_index;

    wire [TAG_WIDTH-1:0] tag_wr_data;

    wire tag_wr_valid;
    wire tag_wr_dirty;

    //---------------------------------------------------------
    // DATA ARRAY SIGNALS
    //---------------------------------------------------------

    wire [INDEX_WIDTH-1:0] data_rd_index;

    wire [DATA_WIDTH-1:0] data_way0;
    wire [DATA_WIDTH-1:0] data_way1;

    wire data_write_en;
    wire data_write_way;

    wire [INDEX_WIDTH-1:0] data_wr_index;

    wire [DATA_WIDTH-1:0] data_wr_data;

    //---------------------------------------------------------
    // LRU SIGNALS
    //---------------------------------------------------------

    wire lru_access_valid;
    wire lru_access_way;

    wire [INDEX_WIDTH-1:0] lru_set_index;

    wire victim_way;

    //---------------------------------------------------------
    // MEMORY SIGNALS
    //---------------------------------------------------------

    wire mem_read;
    wire mem_write;

    wire [ADDR_WIDTH-1:0] mem_addr;
    wire [DATA_WIDTH-1:0] mem_wdata;

    wire [DATA_WIDTH-1:0] mem_rdata;

    wire mem_ready;


//---------------------------------------------------------
// PERFORMANCE MONITOR SIGNALS
//---------------------------------------------------------

wire read_event;
wire write_event;

wire hit_event;
wire miss_event;

wire eviction_event;
wire writeback_event;

    //---------------------------------------------------------
    // CACHE CONTROLLER
    //---------------------------------------------------------

    cache_controller
    #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),

        .NUM_SETS(NUM_SETS),
        .NUM_WAYS(NUM_WAYS),

        .INDEX_WIDTH(INDEX_WIDTH),
        .TAG_WIDTH(TAG_WIDTH)
    )
    CONTROLLER
    (
        .clk(clk),
        .rst(rst),

        .cpu_req(cpu_req),
        .cpu_rw(cpu_rw),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),

        .cpu_rdata(cpu_rdata),
        .cpu_ready(cpu_ready),

        .tag_rd_index(tag_rd_index),

        .tag_way0(tag_way0),
        .tag_way1(tag_way1),

        .valid_way0(valid_way0),
        .valid_way1(valid_way1),

        .dirty_way0(dirty_way0),
        .dirty_way1(dirty_way1),

        .tag_write_en(tag_write_en),
        .tag_write_way(tag_write_way),
        .tag_wr_index(tag_wr_index),
        .tag_wr_data(tag_wr_data),
        .tag_wr_valid(tag_wr_valid),
        .tag_wr_dirty(tag_wr_dirty),

        .data_rd_index(data_rd_index),

        .data_way0(data_way0),
        .data_way1(data_way1),

        .data_write_en(data_write_en),
        .data_write_way(data_write_way),
        .data_wr_index(data_wr_index),
        .data_wr_data(data_wr_data),

        .lru_access_valid(lru_access_valid),
        .lru_access_way(lru_access_way),
        .lru_set_index(lru_set_index),

        .victim_way(victim_way),

        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),

        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),

        .read_event(read_event),
        .write_event(write_event),

        .hit_event(hit_event),
        .miss_event(miss_event),

        .eviction_event(eviction_event),
        .writeback_event(writeback_event)
    );

    //---------------------------------------------------------
    // TAG ARRAY
    //---------------------------------------------------------

    tag_array
    #(
        .NUM_SETS(NUM_SETS),
        .NUM_WAYS(NUM_WAYS),
        .TAG_WIDTH(TAG_WIDTH)
    )
    TAG_RAM
    (
        .clk(clk),
        .rst(rst),

        .rd_index(tag_rd_index),

        .tag_way0(tag_way0),
        .tag_way1(tag_way1),

        .valid_way0(valid_way0),
        .valid_way1(valid_way1),

        .dirty_way0(dirty_way0),
        .dirty_way1(dirty_way1),

        .write_en(tag_write_en),
        .write_way(tag_write_way),

        .wr_index(tag_wr_index),

        .wr_tag(tag_wr_data),

        .wr_valid(tag_wr_valid),
        .wr_dirty(tag_wr_dirty)
    );

    //---------------------------------------------------------
    // DATA ARRAY
    //---------------------------------------------------------

    data_array
    #(
        .NUM_SETS(NUM_SETS),
        .NUM_WAYS(NUM_WAYS),
        .DATA_WIDTH(DATA_WIDTH)
    )
    DATA_RAM
    (
        .clk(clk),
        .rst(rst),

        .rd_index(data_rd_index),

        .data_way0(data_way0),
        .data_way1(data_way1),

        .write_en(data_write_en),
        .write_way(data_write_way),

        .wr_index(data_wr_index),

        .wr_data(data_wr_data)
    );

    //---------------------------------------------------------
    // LRU CONTROLLER
    //---------------------------------------------------------

    lru_controller
    #(
        .NUM_SETS(NUM_SETS),
        .INDEX_WIDTH(INDEX_WIDTH)
    )
    LRU
    (
        .clk(clk),
        .rst(rst),

        .access_valid(lru_access_valid),
        .set_index(lru_set_index),
        .accessed_way(lru_access_way),

        .victim_way(victim_way)
    );

    //---------------------------------------------------------
    // MAIN MEMORY
    //---------------------------------------------------------

    main_memory
#(
    .MEM_DEPTH(1024),
    .LATENCY(5)
)
MEMORY (
        .clk(clk),
        .rst(rst),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),

        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );


//---------------------------------------------------------
// PERFORMANCE MONITOR
//---------------------------------------------------------

performance_monitor MONITOR
(
    .clk(clk),
    .rst(rst),

    .read_event(read_event),
    .write_event(write_event),

    .hit_event(hit_event),
    .miss_event(miss_event),

    .eviction_event(eviction_event),
    .writeback_event(writeback_event),

    .read_count(),
    .write_count(),

    .hit_count(),
    .miss_count(),

    .eviction_count(),
    .writeback_count(),

    .transaction_count()
);


endmodule
