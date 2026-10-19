class Transaction #(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);

    rand logic cpu_rw;
    rand logic  [ADDR_WIDTH-1:0] cpu_addr;
    rand logic  [DATA_WIDTH-1:0] cpu_wdata;
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
