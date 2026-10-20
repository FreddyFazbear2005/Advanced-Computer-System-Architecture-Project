class Transaction #(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);
    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    localparam TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH;
    rand logic cpu_rw;
    rand logic  [ADDR_WIDTH-1:0] cpu_addr;
    rand logic  [DATA_WIDTH-1:0] cpu_wdata;

    constraint write_data_constraint {
        cpu_wdata inside {[0:(1 << ADDR_WIDTH-1)]};
    } 

    constraint cpu_address_constraint {
        cpu_addr[ADDR_WIDTH-1:INDEX_WIDTH] inside {[0:20]};
    }
endclass



class SampledOutput #(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);
    
    logic rst;
    logic cpu_req;
    logic cpu_rw;
    logic  [ADDR_WIDTH-1:0] cpu_addr;
    logic  [DATA_WIDTH-1:0] cpu_wdata;
    logic [DATA_WIDTH-1:0] cpu_rdata;
    logic cpu_ready;

endclass
