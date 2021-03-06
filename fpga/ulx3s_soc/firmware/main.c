// This file is Copyright (c) 2020 Florent Kermarrec <florent@enjoy-digital.fr>
// License: BSD

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <libbase/uart.h>
#include <libbase/console.h>
#include <generated/csr.h>
#include <generated/mem.h>

/*-----------------------------------------------------------------------*/
/* Uart                                                                  */
/*-----------------------------------------------------------------------*/

static char *readstr(void)
{
    char c[2];
    static char s[64];
    static int ptr = 0;

    if(readchar_nonblock()) {
        c[0] = getchar();
        c[1] = 0;
        switch(c[0]) {
            case 0x7f:
            case 0x08:
                if(ptr > 0) {
                    ptr--;
                    fputs("\x08 \x08", stdout);
                }
                break;
            case 0x07:
                break;
            case '\r':
            case '\n':
                s[ptr] = 0x00;
                fputs("\n", stdout);
                ptr = 0;
                return s;
            default:
                if(ptr >= (sizeof(s) - 1))
                    break;
                fputs(c, stdout);
                s[ptr] = c[0];
                ptr++;
                break;
        }
    }

    return NULL;
}

static char *get_token(char **str)
{
    char *c, *d;

    c = (char *)strchr(*str, ' ');
    if(c == NULL) {
        d = *str;
        *str = *str+strlen(*str);
        return d;
    }
    *c = 0;
    d = *str;
    *str = c+1;
    return d;
}

static void prompt(void)
{
    printf("\e[92;1msemify\e[0m> ");
}

/*-----------------------------------------------------------------------*/
/* Help                                                                  */
/*-----------------------------------------------------------------------*/

static void help(void)
{
    puts("\nMy first LiteX SoC built "__DATE__" "__TIME__"\n");
    puts("Available commands:");
    puts("help               - Show this command");
    puts("reboot             - Reboot CPU");
    puts("donut              - Spinning Donut demo");
    puts("mem_list           - List available memory regions");
    puts("wfg_init           - Initialize the waveform generator");
    #ifdef CSR_SIM_TRACE_BASE
    puts("trace              - Toggle simulation tracing");
    #endif
    #ifdef CSR_SIM_FINISH_BASE
    puts("finish             - Finish simulation");
    #endif
    #ifdef CSR_SIM_MARKER_BASE
    puts("mark               - Set a debug simulation marker");
    #endif
}

/*-----------------------------------------------------------------------*/
/* Commands                                                              */
/*-----------------------------------------------------------------------*/

static void reboot_cmd(void)
{
    ctrl_reset_write(1);
}

extern void donut(void);

static void donut_cmd(void)
{
    printf("Donut demo...\n");
    donut();
}

static void mem_regions_cmd(void)
{
    printf("Available memory regions:\n");
    puts(MEM_REGIONS);
}

#ifdef WFG_BASE

extern void wfg_init(void);
extern void wfg_inc_cnt(void);
extern void wfg_dec_cnt(void);

static void wfg_init_cmd(void)
{
    printf("Initializing wfg...\n");
    wfg_init();
}

#endif

#ifdef CSR_SIM_TRACE_BASE
extern void cmd_sim_trace_handler(int nb_params, char **params);
#endif
#ifdef CSR_SIM_FINISH_BASE
extern void cmd_sim_finish_handler(int nb_params, char **params);
#endif
#ifdef CSR_SIM_MARKER_BASE
extern void cmd_sim_mark_handler(int nb_params, char **params);
#endif

/*-----------------------------------------------------------------------*/
/* Console service / Main                                                */
/*-----------------------------------------------------------------------*/

static void console_service(void)
{
    char *str;
    char *token;

    str = readstr();
    if(str == NULL) return;
    token = get_token(&str);
    if(strcmp(token, "help") == 0)
        help();
    else if(strcmp(token, "reboot") == 0)
        reboot_cmd();
    else if(strcmp(token, "donut") == 0)
        donut_cmd();
    else if(strcmp(token, "mem_list") == 0)
        mem_regions_cmd();
    #ifdef CSR_SIM_TRACE_BASE
    else if(strcmp(token, "trace") == 0)
        cmd_sim_trace_handler(0, 0);
    #endif
    #ifdef CSR_SIM_FINISH_BASE
    else if(strcmp(token, "finish") == 0)
        cmd_sim_finish_handler(0, 0);
    #endif
    #ifdef CSR_SIM_MARKER_BASE
    else if(strcmp(token, "mark") == 0)
        cmd_sim_mark_handler(0, 0);
    #endif
    #ifdef WFG_BASE
    else if(strcmp(token, "wfg_init") == 0)
        wfg_init_cmd();
    else if(strcmp(token, "wfg_inc_cnt") == 0)
        wfg_inc_cnt();
    else if(strcmp(token, "wfg_dec_cnt") == 0)
        wfg_dec_cnt();
    #endif
    else
        printf("Unknown command. Type 'help' for help.\n");
    prompt();
}

int main(void)
{
#ifdef CONFIG_CPU_HAS_INTERRUPT
    irq_setmask(0);
    irq_setie(1);
#endif
    uart_init();

    help();
    prompt();

    while(1) {
        console_service();
    }

    return 0;
}
