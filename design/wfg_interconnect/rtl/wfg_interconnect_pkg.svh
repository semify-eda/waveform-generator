`ifndef WFG_INTERCONNECT_PKG
`define WFG_INTERCONNECT_PKG

//package wfg_interconnect_pkg;

    /*interface stimulus_if (input test);
        logic wfg_axis_tready;
        logic wfg_axis_tvalid;
        logic [31:0] wfg_axis_tdata;
    endinterface

    interface driver_if (input test);
        logic wfg_axis_tready;
        logic wfg_axis_tvalid;
        logic [31:0] wfg_axis_tdata;
    endinterface*/
    
    typedef struct packed
    {
        logic wfg_axis_tvalid;
        logic [31:0] wfg_axis_tdata;
    } stimulus_t;
    
    typedef struct packed
    {
        logic wfg_pat_sync;
        logic wfg_pat_subcycle;
        logic [7:0] wfg_pat_subcycle_cnt;

        logic [31:0] wfg_axis_tdata;
        logic wfg_axis_tvalid;
    } driver_t;

//endpackage

`endif
