#ifndef _SDRAM_H__
#define _SDRAM_H__

#include <common.h>

#define CONFIG_SDRAM  0xa0000000
#define CONFIG_SDRAM_COL 0x200
#define CONFIG_SDRAM_ROW 0x4000
#define CONFIG_BANK 0x4
#define CONFIG_SDRAM_SIZE 0x8000000
#define PG_ALIGN_S __attribute((aligned(1024)))

#define SDRAM_LEFT  ((paddr_t)CONFIG_SDRAM)
#define SDRAM_RIGHT ((paddr_t)CONFIG_SDRAM + CONFIG_SDRAM_SIZE - 1)

// /* convert the guest physical address in the guest program to host virtual address in NEMU */
// uint8_t* guest_to_host_sdram(paddr_t paddr);
// /* convert the host virtual address in NEMU to guest physical address in the guest program */
// paddr_t host_to_guest_sdram(uint8_t *haddr);

uint32_t sdram_read(uint32_t addr);

// void init_mrom(); 



#endif