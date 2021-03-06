#include <stdio.h>

#include "lwip/ip_addr.h"
#include "lwip/init.h"
#include "lwip/inet.h"
#include "lwip/priv/tcp_priv.h"
#include "netif/xadapter.h"
#include "lwip/err.h"
#include "lwip/udp.h"

#include "xil_cache.h"
#include "xil_printf.h"

#include "platform.h"
#include "udp_client.h"
#include "si5324.h"

extern volatile int fast_transmit_flag;
extern volatile int slow_transmit_flag;

int main(void)
{
    int32_t status = XST_FAILURE;

    struct netif netif;
    memset(&netif, 0, sizeof(struct netif));

    xil_printf("\r\n\r\n");
    xil_printf("-----UDP Client Application-----\r\n");

    status = program_si5324();
   // M_prnt_if(XST_SUCCESS, "Udp client: si5324 configuring failed\r\n",
	//		               "Udp client: status: ", status, XST_FAILURE);

    init_platform();

    status = init_udp(&netif);
    M_prnt_if(ERR_OK, NULL, "Udp client: status: ", status, XST_FAILURE);

    status = init_udp_transfer();
    M_prnt_if(ERR_OK, "Udp client: udp transfer initialization failed\r\n",
    		          "Udp client: status: ", status, XST_FAILURE);

    while (TRUE) {
       if (TRUE == fast_transmit_flag) {
            tcp_fasttmr();
            fast_transmit_flag = 0;
        }

        if (TRUE == slow_transmit_flag) {
            tcp_slowtmr();
            slow_transmit_flag = 0;
        }

        xemacif_input(&netif);
        transfer_udp_packet();
    }

    return XST_SUCCESS;
}
