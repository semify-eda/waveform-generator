#include <stdio.h>
#include <generated/csr.h>
#include "sim_debug.h"

/**
 * Command "trace"
 *
 * Start/stop simulation trace dump.
 *
 */
#ifdef CSR_SIM_TRACE_BASE
void cmd_sim_trace_handler(int nb_params, char **params)
{
  sim_trace(!sim_trace_enable_read());
}
#endif

/**
 * Command "finish"
 *
 * Finish simulation.
 *
 */
#ifdef CSR_SIM_FINISH_BASE
void cmd_sim_finish_handler(int nb_params, char **params)
{
  sim_finish();
}
#endif

/**
 * Command "mark"
 *
 * Set a debug marker value
 *
 */
#ifdef CSR_SIM_MARKER_BASE
void cmd_sim_mark_handler(int nb_params, char **params)
{
  // cannot use param[1] as it is not a const string
  sim_mark(NULL);
}
#endif
