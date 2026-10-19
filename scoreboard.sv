class Scoreboard #(
    parameter ADDR_WIDTH  = 10,
    parameter DATA_WIDTH  = 32,
    parameter NUM_SETS    = 8,
    parameter LATENCY = 5
);

    mailbox #(SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
    monitor_to_scoreboard_mailbox;
    int number_of_transactions;

    function new(mailbox #(SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY))) 
          monitor_to_scoreboard_mailbox, int number_of_transactions);
          this.monitor_to_scoreboard_mailbox = monitor_to_scoreboard_mailbox;
          this.number_of_transactions = number_of_transactions;
    endfunction

    int current_number_of_transactions = 0;
    localparam MEM_DEPTH = (1 << ADDR_WIDTH);
    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    localparam TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH;
    localparam NUM_WAYS = 2;
    logic [DATA_WIDTH-1:0] main_memory[MEM_DEPTH];
    logic [DATA_WIDTH-1:0] data_array[NUM_SETS][NUM_WAYS];
    logic [TAG_WIDTH-1:0] tag_array[NUM_SETS][NUM_WAYS];
    logic valid_mem[NUM_SETS][NUM_WAYS];
    logic dirty_mem[NUM_SETS][NUM_WAYS];
    logic lru_mem[NUM_SETS];
    logic [DATA_WIDTH-1:0] expected_rdata;
    logic [DATA_WIDTH-1:0] new_expected_rdata;
    logic expected_cpu_ready;
    

    bit rst_seen = 1'b0;
    int error_count = 0;
    int write_hit_latency;
    int read_hit_latency;
    int write_miss_latency;
    int read_miss_latency;
    int latency_counter = 0;

    foreach(main_memory[i]) 
        main_memory[i] = i;
    task run();
        SampledOutput so;
        forever begin 
            monitor_to_scoreboard_mailbox.get(so);
            if(rst_seen) 
                check_output(so);
            if(so.rst) 
                reset_scoreboard();
            else 
                update_scoreboard(so);
        end
    endtask


    task check_output(SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) so);
        begin 
            if(so.cpu_ready === expected_cpu_ready) begin 
                $display("[PASS], the expected cpu ready is %0h",expected_cpu_ready);
            end
            else begin 
                $display("[FAIL], at time %t, expected cpu ready is %0h, actual cpu ready is %0h",$time,expected_cpu_ready,so.cpu_ready);
                error_count++;
            end
            if(so.cpu_rdata === expected_rdata) begin 
                $display("[PASS], the expected cpu rdata is %0h",expected_rdata);
            end
            else begin 
                $display("[FAIL], at time %t, expected cpu rdata is %0h, actual cpu rdata is %0h",$time,expected_rdata,so.cpu_rdata);
                error_count++;
            end
            if(so.cpu_ready) begin 
                current_number_of_transactions++;
                if(current_number_of_transactions >= number_of_transactions) begin 
                    $display("Simulation ended at time %t, %d pass transactions, %d fail transactions",$time,
                        number_of_transactions-error_count,error_count);
                    if(error_count == 0) 
                        $display("SEXY BITCHES, LESS GOOOOOO, ORGASMIC SUCCESS");
                    $finish;
                end
            end
        end
    endtask


    task reset_scoreboard();
        begin 
            expected_rdata = '0;
            expected_cpu_ready = '0;
            foreach(data_array[i,j]) 
                data_array[i][j] = '0;
            foreach(tag_array[i,j]) 
                tag_array[i][j] = '0;
            foreach(lru_mem[i]) 
                lru_mem[i] = '0;
            foreach(valid_mem[i,j]) 
                valid_mem[i][j] = '0;
            foreach(dirty_mem[i,j]) 
                dirty_mem[i][j] = '0;
        end
    endtask


    task update_scoreboard(SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) so);
        begin 
            if(so.cpu_req === 1'b0) begin 
                return;
            end
            if(latency_counter > 0) begin 
                latency_counter--;
                expected_cpu_ready = 1'b0
                return;
            end
            else begin 
                latency_counter = 0;
                expected_rdata = new_expected_rdata;
                expected_cpu_ready = 1'b1;
            end
            
            logic [TAG_WIDTH-1:0] current_tag = so.cpu_addr[ADDR_WIDTH-1:INDEX_WIDTH];
            logic [INDEX_WIDTH-1:0] current_index = so.cpu_addr[INDEX_WIDTH-1:0];
            logic access_way0 = (tag_array[current_index][0] == current_tag) & (valid_mem[current_index][0]);
            logic access_way1 = (tag_array[current_index][1] == current_tag) & (valid_mem[current_index][1]);

            if(so.cpu_rw === 1'b0) begin //read cases
                if(access_way0 || access_way1) begin //hit
                    logic current_access_way = access_way0 ? access_way0 : access_way1;
                    latency_counter = read_hit_latency;
                    new_expected_rdata = data_array[current_index][current_access_way];
                    lru_mem[current_index] = ~current_access_way;
                end
                else begin //miss
                    logic evicted_access_way;
                    if(valid_mem[current_index][0] == 1'b0)
                        evicted_access_way = 1'b0;
                    else if(valid_mem[current_index][1] == 1'b0)
                        evicted_access_way = 1'b1;
                    else
                        evicted_access_way = lru_mem[current_index];


                end
            end
        end
    endtask

endclass
