#include <flash.h>
#include "svdpi.h"
// #include "TOP_NAME__Dpi.h"
// #include "VysyxSoCTop.h"  // Verilator 生成的模型头文件
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

static uint8_t flash[CONFIG_FLASH_SIZE] PG_ALIGN = {};

uint8_t* guest_to_host_flash(paddr_t paddr) { return flash + paddr; }
// paddr_t host_to_guest_mrom(uint8_t *haddr) { return haddr - mrom + CONFIG_MROM; }


static inline word_t host_read_f(void *addr) {

    return *(uint32_t *)addr;
}

extern "C" void flash_read(int32_t addr, int32_t *data) {

    uint32_t temp;

    if((uint32_t)addr >= CONFIG_FLASH && (uint32_t)addr <= FLASH_RIGHT) {

        temp = host_read_f(guest_to_host_flash(addr));
        // printf("%08x, %08x\n", addr, temp);
        *data = (int32_t)temp;
    }
    else{
        printf("flash out of bound\n");
        assert(0);
    }
    return;
}