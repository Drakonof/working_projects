#ifndef __PLATFORM_H_
#define __PLATFORM_H_

#include "xstatus.h"

#define PLATFORM_ZYNQ

#define M_prnt_if(stat, msg_1, msg_2, exp, ret)         \
    do {                                                \
        if ((stat) != (exp)) {                          \
            if (NULL != (msg_1)) {                      \
                xil_printf("%s", (msg_1));              \
            }                                           \
                                                        \
            if (NULL != (msg_2)) {                      \
                xil_printf("%s%d\n\r", (msg_2), (exp)); \
            }                                           \
            return ret;                                 \
        }                                               \
    } while(0)

#define M_prnt_if_tw_exp(stat, msg_1, exp_1, msg_2, exp_2, ret) \
    do {                                                        \
        if ((stat) != (exp_2)) {                                \
            if ((NULL != (msg_1)) && (NULL != (msg_2))) {       \
                xil_printf("%s%d\n\r", (msg_1),(exp_1));        \
                xil_printf("%s%d\n\r", (msg_2),(exp_2));        \
            }                                                   \
            return ret;                                         \
        }                                                       \
    } while(0)

void init_platform();
void cleanup_platform();
void platform_setup_timer();
void platform_enable_interrupts();
#endif
