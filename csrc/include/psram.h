#ifndef _PSRAM_H__
#define _PSRAM_H__

#include <common.h>

#define CONFIG_PSRAM  0x00000000
#define CONFIG_PSRAM_SIZE 0x400000
#define PG_ALIGN __attribute((aligned(4096)))


#define PSRAM_LEFT  ((paddr_t)CONFIG_PSRAM)
#define PSRAM_RIGHT ((paddr_t)CONFIG_PSRAM + CONFIG_PSRAM_SIZE - 1)

/* convert the guest physical address in the guest program to host virtual address in NEMU */
uint8_t* guest_to_host_psram(paddr_t paddr);
/* convert the host virtual address in NEMU to guest physical address in the guest program */
paddr_t host_to_guest_psram(uint8_t *haddr);


// void init_mrom(); 



#endif