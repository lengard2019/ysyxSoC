#include <psram.h>
#include "svdpi.h"
// #include "VysyxSoCTop__Dpi.h"
// #include <cpu/difftest.h>
// #include <time.h>

#include "VysyxSoCFull.h"
#include "VysyxSoCFull__Dpi.h"

// 内存数组
static uint8_t psram[CONFIG_PSRAM_SIZE] PG_ALIGN = { }; 

uint8_t* guest_to_host_psram(paddr_t paddr) { return psram + paddr; }
paddr_t host_to_guest_psram(uint8_t *haddr) { return haddr - psram; }

static inline word_t host_read(void *addr) {
    return *(uint32_t *)addr;
}

static inline void host_write(void *addr, uint8_t data) {

    *(uint8_t *)addr = data; 
    return;
  
}
    
extern "C" void psram_read(int32_t addr, int32_t *data) {
  // paddr_t addr_r = (paddr_t)addr;
  uint32_t temp;

    if((uint32_t)addr <= PSRAM_RIGHT) {

        temp = host_read(guest_to_host_psram(addr));
        // printf("read %08x, %08x\n", addr, temp);
        *data = (int32_t)temp;
    }
    else{
        printf("psram out of bound\n");
        assert(0);
    }
    return;
}

extern "C" void psram_write(int32_t addr, char data) {
  uint32_t temp;
  temp = (uint32_t)addr;
  if(temp <= PSRAM_RIGHT){
    host_write(guest_to_host_psram(temp), (uint8_t)data);
    // printf("write %08x, %08x\n", temp, (uint8_t)data);
  }
  else{
    printf("psram is out of bound\n");
    // assert(0);
  }
}