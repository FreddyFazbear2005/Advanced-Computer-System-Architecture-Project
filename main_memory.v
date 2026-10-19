
module main_memory #
(
    parameter MEM_DEPTH = 1024,
    parameter LATENCY   = 5
)
(
    input clk,
    input rst,

    // Memory Request Interface
    input mem_read,
    input mem_write,

    input [31:0] mem_addr,
    input [31:0] mem_wdata,

    output reg [31:0] mem_rdata,
    output reg mem_ready
);

    // Memory Array
 

    reg [31:0] memory [0:MEM_DEPTH-1];


    // Internal Registers


    reg [31:0] addr_reg;
    reg [31:0] wdata_reg;

    reg pending_read;
    reg pending_write;

    reg [3:0] latency_counter;

    integer i;



    initial
    begin
        for(i = 0; i < MEM_DEPTH; i = i + 1)
        begin
            memory[i] = i;
        end
    end



    always @(posedge clk)
    begin

        if(rst)
        begin

            mem_ready       <= 0;

            pending_read    <= 0;
            pending_write   <= 0;

            latency_counter <= 0;

            mem_rdata       <= 0;

        end

        else
        begin



            mem_ready <= 0;


            if((mem_read || mem_write) &&
               !pending_read &&
               !pending_write)
            begin

                addr_reg  <= mem_addr;
                wdata_reg <= mem_wdata;

                pending_read  <= mem_read;
                pending_write <= mem_write;

                latency_counter <= LATENCY;

            end



            else if(pending_read || pending_write)
            begin

                if(latency_counter > 0)
                begin
                    latency_counter <= latency_counter - 1;
                end

                else
                begin

                    //--------------------------------------------------
                    // READ
                    //--------------------------------------------------

                    if(pending_read)
                    begin

                        mem_rdata <= memory[addr_reg[31:2]];

                    end

                    //--------------------------------------------------
                    // WRITE
                    //--------------------------------------------------

                    if(pending_write)
                    begin

                        memory[addr_reg[31:2]] <= wdata_reg;

                    end

                    mem_ready <= 1'b1;

                    pending_read  <= 0;
                    pending_write <= 0;

                end

            end

        end

    end

endmodule
