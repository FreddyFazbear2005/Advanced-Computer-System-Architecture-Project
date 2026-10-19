
module lru_controller #
(
    parameter NUM_SETS    = 8,
    parameter INDEX_WIDTH = 3
)
(
    input clk,
    input rst,

    //=========================================================
    // CACHE ACCESS INFORMATION
    //=========================================================

    input access_valid,              // Cache access completed

    input [INDEX_WIDTH-1:0] set_index,

    input accessed_way,              // 0 or 1

    //=========================================================
    // VICTIM SELECTION
    //=========================================================

    output victim_way
);

    //=========================================================
    // LRU STORAGE
    //=========================================================

    reg lru_mem [0:NUM_SETS-1];

    integer i;

    //=========================================================
    // RESET + LRU UPDATE
    //=========================================================

    always @(posedge clk)
    begin

        if(rst)
        begin

            for(i = 0; i < NUM_SETS; i = i + 1)
            begin
                lru_mem[i] <= 1'b0;
            end

        end

        else
        begin

            if(access_valid)
            begin

                //--------------------------------------------------
                // Accessed way becomes MRU
                // Other way becomes LRU
                //--------------------------------------------------

                lru_mem[set_index] <= ~accessed_way;

            end

        end

    end

    //=========================================================
    // VICTIM WAY
    //=========================================================

    assign victim_way = lru_mem[set_index];

endmodule
