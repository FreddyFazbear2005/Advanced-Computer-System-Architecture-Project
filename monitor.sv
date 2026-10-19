class monitor#(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);
    mailbox #(SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
    monitor_to_scoreboard_mailbox;
    virtual cache_interface #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) vif;


    function new(input mailbox #(SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
       monitor_to_scoreboard_mailbox, 
    input virtual cache_interface #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))
        vif);
        this.monitor_to_scoreboard_mailbox = monitor_to_scoreboard_mailbox;
        this.vif = vif;
    endfunction

    task run();
        SampledOutput so;
        forever begin 
            so = new();
            @(vif.monitor_cb);
            so.rst = vif.monitor_cb.rst;
            so.cpu_req = vif.monitor_cb.cpu_req;
            so.cpu_rw = vif.monitor_cb.cpu_rw;
            so.cpu_addr = vif.monitor_cb.cpu_addr;
            so.cpu_wdata = vif.monitor_cb.cpu_wdata;
            so.cpu_rdata = vif.monitor_cb.cpu_rdata;
            so.cpu_ready = vif.monitor_cb.cpu_ready;
            monitor_to_scoreboard_mailbox.put(so);
        end
    endtask

endclass
