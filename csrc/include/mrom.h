#ifndef _MROM_H__
#define _MROM_H__

#include <common.h>

#define CONFIG_MROM  0x20000000
#define CONFIG_MROM_SIZE 0x1000
#define PG_ALIGN __attribute((aligned(4096)))


#define MROM_LEFT  ((paddr_t)CONFIG_MROM)
#define MROM_RIGHT ((paddr_t)CONFIG_MROM + CONFIG_MROM_SIZE - 1)

/* convert the guest physical address in the guest program to host virtual address in NEMU */
uint8_t* guest_to_host_mrom(paddr_t paddr);
/* convert the host virtual address in NEMU to guest physical address in the guest program */
paddr_t host_to_guest_mrom(uint8_t *haddr);


// void init_mrom(); 



#endif