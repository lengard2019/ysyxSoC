#ifndef _FLASH_H__
#define _FLASH_H__

#include <common.h>

#define CONFIG_FLASH  0x00000000
#define CONFIG_FLASH_SIZE 0x1000000
#define PG_ALIGN __attribute((aligned(4096)))


#define FLASH_LEFT  ((paddr_t)CONFIG_FLASH)
#define FLASH_RIGHT ((paddr_t)CONFIG_FLASH + CONFIG_FLASH_SIZE - 1)

/* convert the guest physical address in the guest program to host virtual address in NEMU */
uint8_t* guest_to_host_flash(paddr_t paddr);
/* convert the host virtual address in NEMU to guest physical address in the guest program */
// paddr_t host_to_guest_mrom(uint8_t *haddr);


// void init_mrom(); 



#endif