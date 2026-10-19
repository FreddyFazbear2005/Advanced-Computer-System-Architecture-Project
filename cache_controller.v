
module cache_controller #
(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,

    parameter NUM_SETS    = 8,

    localparam INDEX_WIDTH = $clog2(NUM_SETS),
    localparam TAG_WIDTH   = ADDR_WIDTH - INDEX_WIDTH
)
(
    input clk,
    input rst,

    //=========================================================
    // CPU INTERFACE
    //=========================================================

    input cpu_req,
    input cpu_rw,

    input  [ADDR_WIDTH-1:0] cpu_addr,
    input  [DATA_WIDTH-1:0] cpu_wdata,

    output reg [DATA_WIDTH-1:0] cpu_rdata,
    output reg cpu_ready,

    //=========================================================
    // TAG ARRAY INTERFACE
    //=========================================================

    output reg [INDEX_WIDTH-1:0] tag_rd_index,

    input [TAG_WIDTH-1:0] tag_way0,
    input [TAG_WIDTH-1:0] tag_way1,

    input valid_way0,
    input valid_way1,

    input dirty_way0,
    input dirty_way1,

    output reg tag_write_en,
    output reg tag_write_way,

    output reg [INDEX_WIDTH-1:0] tag_wr_index,

    output reg [TAG_WIDTH-1:0] tag_wr_data,

    output reg tag_wr_valid,
    output reg tag_wr_dirty,

    //=========================================================
    // DATA ARRAY INTERFACE
    //=========================================================

    output reg [INDEX_WIDTH-1:0] data_rd_index,

    input [DATA_WIDTH-1:0] data_way0,
    input [DATA_WIDTH-1:0] data_way1,

    output reg data_write_en,
    output reg data_write_way,

    output reg [INDEX_WIDTH-1:0] data_wr_index,

    output reg [DATA_WIDTH-1:0] data_wr_data,

    //=========================================================
    // LRU CONTROLLER INTERFACE
    //=========================================================

    output reg lru_access_valid,

    output reg lru_access_way,

    output reg [INDEX_WIDTH-1:0] lru_set_index,

    input victim_way,

    //=========================================================
    // MAIN MEMORY INTERFACE
    //=========================================================

    output reg mem_read,
    output reg mem_write,

    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg [DATA_WIDTH-1:0] mem_wdata,

    input [DATA_WIDTH-1:0] mem_rdata,

    input mem_ready,
    
    output reg read_event,
    output reg write_event,

    output reg hit_event,
    output reg miss_event,

    output reg eviction_event,
    output reg writeback_event
);

    //=========================================================
    // FSM STATES
    //=========================================================

    localparam IDLE       = 3'd0;
    localparam LOOKUP     = 3'd1;
    localparam WRITEBACK  = 3'd2;
    localparam ALLOCATE   = 3'd3;
    localparam RESPOND    = 3'd4;

    reg [2:0] state;

    //=========================================================
    // REQUEST REGISTERS
    //=========================================================

    reg req_rw;

    reg [ADDR_WIDTH-1:0] req_addr;
    reg [DATA_WIDTH-1:0] req_wdata;

    reg [INDEX_WIDTH-1:0] req_index;
    reg [TAG_WIDTH-1:0]   req_tag;

    //=========================================================
    // HIT INFORMATION
    //=========================================================

    wire cache_hit;
    wire hit_way;

    //=========================================================
    // VICTIM INFORMATION
    //=========================================================

    reg [TAG_WIDTH-1:0] victim_tag;

    reg [DATA_WIDTH-1:0] victim_data;

    reg victim_dirty;
    reg victim_valid;
    reg alloc_way;

    //=========================================================
    // RESPONSE REGISTER
    //=========================================================

    reg [DATA_WIDTH-1:0] response_data;


    //=========================================================
    // TAG MATCH
    //=========================================================

    wire hit0;
    wire hit1;

    assign hit0 =
            valid_way0 &&
           (tag_way0 == req_tag);

    assign hit1 =
            valid_way1 &&
           (tag_way1 == req_tag);

    assign cache_hit = hit0 | hit1;

    assign hit_way = hit1;


    //=========================================================
    // COMBINATIONAL VICTIM INFORMATION
    //=========================================================

always @(*)
begin

    // Default values
    victim_tag   = {TAG_WIDTH{1'b0}};
    victim_data  = {DATA_WIDTH{1'b0}};
    victim_dirty = 1'b0;
    victim_valid = 1'b0;

    // Choose allocation way
    if(!valid_way0)
        alloc_way = 1'b0;
    else if(!valid_way1)
        alloc_way = 1'b1;
    else
        alloc_way = victim_way;

    // Read selected way
    if(alloc_way == 1'b0)
    begin
        victim_tag   = tag_way0;
        victim_data  = data_way0;
        victim_dirty = dirty_way0;
        victim_valid = valid_way0;
    end
    else
    begin
        victim_tag   = tag_way1;
        victim_data  = data_way1;
        victim_dirty = dirty_way1;
        victim_valid = valid_way1;
    end

end


    //=========================================================
    // MAIN FSM
    //=========================================================

    always @(posedge clk)
    begin

        if(rst)
        begin

            //--------------------------------------------------
            // FSM
            //--------------------------------------------------

            state <= IDLE;

            //--------------------------------------------------
            // CPU
            //--------------------------------------------------

            cpu_ready <= 1'b0;
            cpu_rdata <= {DATA_WIDTH{1'b0}};

            //--------------------------------------------------
            // Memory
            //--------------------------------------------------

            mem_read  <= 1'b0;
            mem_write <= 1'b0;

            mem_addr  <= {ADDR_WIDTH{1'b0}};
            mem_wdata <= {DATA_WIDTH{1'b0}};

            //--------------------------------------------------
            // Tag Array
            //--------------------------------------------------

            tag_rd_index  <= {INDEX_WIDTH{1'b0}};

            tag_write_en  <= 1'b0;
            tag_write_way <= 1'b0;
            tag_wr_index  <= {INDEX_WIDTH{1'b0}};
            tag_wr_data   <= {TAG_WIDTH{1'b0}};
            tag_wr_valid  <= 1'b0;
            tag_wr_dirty  <= 1'b0;

            //--------------------------------------------------
            // Data Array
            //--------------------------------------------------

            data_rd_index <= {INDEX_WIDTH{1'b0}};

            data_write_en  <= 1'b0;
            data_write_way <= 1'b0;
            data_wr_index  <= {INDEX_WIDTH{1'b0}};
            data_wr_data   <= {DATA_WIDTH{1'b0}};

            //--------------------------------------------------
            // LRU
            //--------------------------------------------------

            lru_access_valid <= 1'b0;
            lru_access_way   <= 1'b0;
            lru_set_index    <= {INDEX_WIDTH{1'b0}};

            //--------------------------------------------------
            // Internal Registers
            //--------------------------------------------------

            req_rw    <= 1'b0;
            req_addr  <= {ADDR_WIDTH{1'b0}};
            req_wdata <= {DATA_WIDTH{1'b0}};

            req_index <= {INDEX_WIDTH{1'b0}};
            req_tag   <= {TAG_WIDTH{1'b0}};

            response_data <= {DATA_WIDTH{1'b0}};
            
            read_event      <= 1'b0;
            write_event     <= 1'b0;

            hit_event       <= 1'b0;
            miss_event      <= 1'b0;

            eviction_event  <= 1'b0;
            writeback_event <= 1'b0;

        end

        else
        begin

            //--------------------------------------------------
            // Default Outputs
            //--------------------------------------------------

            cpu_ready <= 1'b0;

            mem_read  <= 1'b0;
            mem_write <= 1'b0;

            tag_write_en  <= 1'b0;
            data_write_en <= 1'b0;

            lru_access_valid <= 1'b0;
            

            //--------------------------------------------------
            // FSM
            //--------------------------------------------------
            read_event      <= 1'b0;
            write_event     <= 1'b0;

            hit_event       <= 1'b0;
            miss_event      <= 1'b0;

            eviction_event  <= 1'b0;
            writeback_event <= 1'b0;


            case(state)

            //==================================================
            // IDLE
            //==================================================

            IDLE:
            begin

                if(cpu_req)
                begin
                    if(cpu_rw)
                        write_event <= 1'b1;
                    else
                        read_event <= 1'b1;
                    //------------------------------------------
                    // Latch CPU Request
                    //------------------------------------------

                    req_rw    <= cpu_rw;
                    req_addr  <= cpu_addr;
                    req_wdata <= cpu_wdata;

                    req_index <= cpu_addr[INDEX_WIDTH-1:0];
                    req_tag   <= cpu_addr[ADDR_WIDTH-1:INDEX_WIDTH];

                    //------------------------------------------
                    // Read Cache Arrays
                    //------------------------------------------

                    tag_rd_index  <= cpu_addr[INDEX_WIDTH-1:0];
                    data_rd_index <= cpu_addr[INDEX_WIDTH-1:0];
                    lru_set_index <= cpu_addr[INDEX_WIDTH-1:0];

                    state <= LOOKUP;

                end

            end

            //==================================================
            // LOOKUP
            //==================================================

            LOOKUP:
            begin

                //------------------------------------------------
                // CACHE HIT
                //------------------------------------------------

                if(cache_hit)
                begin

                    //--------------------------------------------
                    // Update LRU
                    //--------------------------------------------
                    hit_event <= 1'b1;
                    lru_access_valid <= 1'b1;
                    lru_access_way   <= hit_way;

                    //--------------------------------------------
                    // READ HIT
                    //--------------------------------------------

                    if(req_rw == 1'b0)
                    begin

                        if(hit_way == 1'b0)
                            response_data <= data_way0;
                        else
                            response_data <= data_way1;

                    end

                    //--------------------------------------------
                    // WRITE HIT
                    //--------------------------------------------

                    else
                    begin

                        data_write_en  <= 1'b1;
                        data_write_way <= hit_way;
                        data_wr_index  <= req_index;
                        data_wr_data   <= req_wdata;

                        tag_write_en   <= 1'b1;
                        tag_write_way  <= hit_way;
                        tag_wr_index   <= req_index;
                        tag_wr_data    <= req_tag;
                        tag_wr_valid   <= 1'b1;
                        tag_wr_dirty   <= 1'b1;

                        response_data  <= req_wdata;

                    end

                    state <= RESPOND;

                end

                //------------------------------------------------
                // CACHE MISS
                //------------------------------------------------

                else
                begin

    miss_event <= 1'b1;

$display("--------------------------------");
$display("MISS at time %0t", $time);
$display("Address      = %h", req_addr);
$display("Set Index    = %0d", req_index);
$display("Alloc Way    = %0d", alloc_way);
$display("Victim Valid = %b", victim_valid);
$display("Victim Dirty = %b", victim_dirty);
$display("Victim Tag   = %h", victim_tag);

    if(victim_valid)
        eviction_event <= 1'b1;

    if(victim_dirty)
    begin

        mem_write <= 1'b1;
        mem_addr  <= {victim_tag, req_index};
        mem_wdata <= victim_data;

        state <= WRITEBACK;

    end
    else
    begin

        mem_read <= 1'b1;
        mem_addr <= req_addr;

        state <= ALLOCATE;

    end

end
                

end
            
            //==================================================
            // WRITEBACK
            //==================================================

            WRITEBACK:
            begin

                if(mem_ready)
                begin
                    
                    writeback_event <= 1'b1;
                    mem_write <= 1'b0;

                    //--------------------------------------------------
                    // Begin Memory Refill
                    //--------------------------------------------------

                    mem_read <= 1'b1;
                    mem_addr <= req_addr;

                    state <= ALLOCATE;

                end

                else
                begin

                    mem_write <= 1'b1;

                    mem_addr  <= {victim_tag, req_index};
                    mem_wdata <= victim_data;

                end

            end

            //==================================================
            // ALLOCATE
            //==================================================

            ALLOCATE:
            begin

                if(mem_ready)
                begin
                    
                  
                    mem_read <= 1'b0;

                    //--------------------------------------------------
                    // Update Tag Array
                    //--------------------------------------------------

                    tag_write_en   <= 1'b1;
                    tag_write_way  <= alloc_way;
                    tag_wr_index   <= req_index;
                    tag_wr_data    <= req_tag;
                    tag_wr_valid   <= 1'b1;
                    tag_wr_dirty   <= req_rw;

                    //--------------------------------------------------
                    // READ MISS
                    //--------------------------------------------------

                    if(req_rw == 1'b0)
                    begin

                        data_write_en  <= 1'b1;
                        data_write_way <= alloc_way;
                        data_wr_index  <= req_index;
                        data_wr_data   <= mem_rdata;

                        response_data  <= mem_rdata;

                    end

                    //--------------------------------------------------
                    // WRITE MISS
                    //--------------------------------------------------

                    else
                    begin

                        data_write_en  <= 1'b1;
                        data_write_way <= alloc_way;
                        data_wr_index  <= req_index;
                        data_wr_data   <= req_wdata;

                        response_data  <= req_wdata;

                    end

                    //--------------------------------------------------
                    // Update LRU
                    //--------------------------------------------------

                    lru_access_valid <= 1'b1;
                    lru_access_way   <= alloc_way;
                    lru_set_index    <= req_index;

                    state <= RESPOND;

                end

                else
                begin

                    mem_read <= 1'b1;
                    mem_addr <= req_addr;

                end

            end

            //==================================================
            // RESPOND
            //==================================================

            RESPOND:
            begin

                cpu_ready <= 1'b1;

                cpu_rdata <= response_data;

                state <= IDLE;

            end

            endcase

        end

    end

endmodule
