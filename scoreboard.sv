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
          foreach(main_memory[i]) 
              main_memory[i] = i;
          pending_transaction = 1'b0;
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
    int hit_latency = 3;
    int miss_latency_allocate_only = LATENCY + 6;
    int miss_latency_allocate_and_write_back = 2*LATENCY + 9;
    int latency_counter = 0;

    task run();
        SampledOutput #(.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH),.NUM_SETS(NUM_SETS),.LATENCY(LATENCY)) so;
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
            rst_seen = 1'b1;
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
        logic [TAG_WIDTH-1:0] current_tag;
        logic [INDEX_WIDTH-1:0] current_index;
        logic access_way0;
        logic access_way1;
        begin 
            if(latency_counter > 0) begin 
                latency_counter--;
                expected_cpu_ready = 1'b0;
                return;
            end
            else begin 
                latency_counter = 0;
                expected_cpu_ready = pending_transaction;
                if(pending_transaction) 
                    expected_rdata = new_expected_rdata;
                pending_transaction = 1'b0;
            end

            if(so.cpu_req === 1'b0) begin 
                return;
            end
            
            current_tag = so.cpu_addr[ADDR_WIDTH-1:INDEX_WIDTH];
            current_index = so.cpu_addr[INDEX_WIDTH-1:0];
            access_way0 = (tag_array[current_index][0] == current_tag) & (valid_mem[current_index][0]);
            access_way1 = (tag_array[current_index][1] == current_tag) & (valid_mem[current_index][1]);
            pending_transaction = 1'b1;
            if(access_way0 || access_way1) begin 
                logic access_way = access_way0 ? 1'b0 : 1'b1;
                update_scoreboard_hit(current_tag,current_index,access_way, so.cpu_rw, so.cpu_wdata);
                latency_counter = hit_latency;
            end
            else begin 
                logic evicted_way;
                if(valid_mem[current_index][0] == 1'b0) begin 
                    evicted_way = 1'b0;
                end
                else if(valid_mem[current_index][1] == 1'b0) begin 
                    evicted_way = 1'b1;
                end
                else begin 
                    evicted_way = lru_mem[current_index];
                end
                if(dirty_mem[current_index][evicted_way]) begin 
                    update_scoreboard_write_back(current_index, evicted_way, data_array[current_index][evicted_way]);
                    update_scoreboard_allocate(current_tag, current_index, evicted_way, so.cpu_rw, so.cpu_wdata);
                    latency_counter = miss_latency_allocate_and_write_back;
                end
                else begin 
                    update_scoreboard_allocate(current_tag, current_index, evicted_way, so.cpu_rw, so.cpu_wdata);
                    latency_counter = miss_latency_allocate_only;
                end
            end
        end
    endtask

    task update_scoreboard_hit(logic [TAG_WIDTH-1:0] current_tag, logic [INDEX_WIDTH-1:0] current_index, 
        logic access_way, logic read_write, logic [DATA_WIDTH-1:0] write_data);
        begin 
            if(read_write) begin //write
                data_array[current_index][access_way] = write_data;
                dirty_mem[current_index][access_way] = 1'b1;
                new_expected_rdata = data_array[current_index][access_way];
            end
            else begin //read
                new_expected_rdata = data_array[current_index][access_way];
            end
            lru_mem[current_index] = ~access_way;
        end
    endtask

    task update_scoreboard_write_back(logic [INDEX_WIDTH-1:0] current_index, logic evicted_way, logic [DATA_WIDTH-1:0] write_data);
        begin 
            main_memory[{tag_array[current_index][evicted_way],current_index}] = write_data;
        end
    endtask

    task update_scoreboard_allocate(logic [TAG_WIDTH-1:0] current_tag, logic [INDEX_WIDTH-1:0] current_index, 
        logic evicted_way, logic read_write, logic [DATA_WIDTH-1:0] write_data);
        begin 
            data_array[current_index][evicted_way] = main_memory[{current_tag,current_index}];
            tag_array[current_index][evicted_way] = current_tag;
            valid_mem[current_index][evicted_way] = 1'b1;
            dirty_mem[current_index][evicted_way] = 1'b0;
            if(read_write) begin //write
                data_array[current_index][evicted_way] = write_data;
                dirty_mem[current_index][evicted_way] = 1'b1;
                new_expected_rdata = data_array[current_index][evicted_way];
            end
            else begin //read
                new_expected_rdata = data_array[current_index][evicted_way];
            end
            lru_mem[current_index] = ~evicted_way;
        end
    endtask

endclass
