class cache_coverage #(parameter NUM_SETS = 8);

    localparam INDEX_WIDTH = $clog2(NUM_SETS);
    typedef enum int {OUT_HIT, OUT_MISS_INVALID, OUT_MISS_CLEAN, OUT_MISS_DIRTY} outcome_e;

    bit read_write;
    outcome_e outcome;
    bit way;
    bit [INDEX_WIDTH-1:0] index;
    bit lru_way;
    bit same_set;

    covergroup cg;
        cp_read_write: coverpoint read_write {
            bins read = {0};
            bins write = {1};
        }
        cp_outcome: coverpoint outcome;

        cp_way: coverpoint way;

        cp_index: coverpoint index;

        cp_lru: coverpoint lru_way iff (outcome == OUT_MISS_CLEAN || outcome == OUT_MISS_DIRTY);

    endgroup
endclass
