#include <mrom.h>
#include "svdpi.h"
#include "verilated.h"

// #ifdef CONFIG_NVBOARD
#include "VysyxSoCFull.h"
// #include "VysyxSoCFull___024root.h"
#include "VysyxSoCFull__Dpi.h"
// #else
// #include "VysyxSoCTop.h"
// // #include "VysyxSoCTop___024root.h"
// #include "VysyxSoCTop__Dpi.h"
// #endif

// static const uint32_t img [] = {
//     0x100007b7,
//     0x04100713,
//     0x00e78023,
//     0x100007b7,
//     0x00a00713,
//     0x00e78023,
//     0x00100073,
// };
  

// void init_mrom() {
//     /* Load built-in image. */
//     memcpy(guest_to_host_mrom(CONFIG_MROM), img, sizeof(img));
// }

static uint8_t mrom[CONFIG_MROM_SIZE] PG_ALIGN = {};

uint8_t* guest_to_host_mrom(paddr_t paddr) { return mrom + paddr - CONFIG_MROM; }//0x80000000
paddr_t host_to_guest_mrom(uint8_t *haddr) { return haddr - mrom + CONFIG_MROM; }


static inline word_t host_read_m(void *addr) {

    return *(uint32_t *)addr;
}

extern "C" void mrom_read(int32_t addr, int32_t *data) {

    uint32_t temp;

    if((uint32_t)addr >= CONFIG_MROM && (uint32_t)addr <= MROM_RIGHT) {

        temp = host_read_m(guest_to_host_mrom(addr));
        // printf("%08x, %08x\n", addr, temp);
        *data = (int32_t)temp;
    }
    else{
        printf("mrom out of bound\n");
        assert(0);
    }
    return;
}



