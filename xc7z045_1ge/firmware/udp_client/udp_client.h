#ifndef UDP_CLIENT_H
#define UDP_CLIENT_H

#include "platform.h"

#define UDP_PORT                  "8080"
#define UDP_SERVER_IP_ADDRESS     "10.10.1.1"//"192.168.18.1"
#define UDP_CLIENT_IP_ADDRESS	  "10.10.30.10"//"192.168.18.2"
#define UDP_CLIENT_GW_IP_ADDRESS  "10.10.30.11"//"192.168.18.10"
#define UDP_IP_MASK		          "255.255.255.0"

int32_t init_udp(struct netif *server_netif);
err_t transfer_udp_packet(void);
err_t init_udp_transfer(void);

#endif //UDP_CLIENT_H
