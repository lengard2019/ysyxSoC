#include <sdram.h>
#include "svdpi.h"
// #include "VysyxSoCTop__Dpi.h"
// #include <cpu/difftest.h>
// #include <time.h>

#include "VysyxSoCFull.h"
// #include "VysyxSoCFull___024root.h"
#include "VysyxSoCFull__Dpi.h"

// 内存数组
static uint32_t sdram[CONFIG_BANK][CONFIG_SDRAM_COL][CONFIG_SDRAM_ROW] PG_ALIGN_S = {};
// static uint32_t sdram_1[CONFIG_BANK][CONFIG_SDRAM_COL][CONFIG_SDRAM_ROW] PG_ALIGN_S = {};
// static uint16_t sdram_2[CONFIG_BANK][CONFIG_SDRAM_COL][CONFIG_SDRAM_ROW] PG_ALIGN_S = {};
// static uint16_t sdram_3[CONFIG_BANK][CONFIG_SDRAM_COL][CONFIG_SDRAM_ROW] PG_ALIGN_S = {};

uint32_t sdram_read(uint32_t addr){
  uint16_t row = (addr & 0x000007FB) >> 2;
  uint16_t bank = (addr & 0x00001800) >> 11;
  uint16_t col = (addr & 0x03FFE) >> 13;

  return sdram[bank][col][row];
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(sdram, rand(), CONFIG_SDRAM_SIZE));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", SDRAM_LEFT, SDRAM_RIGHT);
}


extern "C" void sdram0_read(char bank, short row, short col, int *data){
  // paddr_t addr_r = (paddr_t)addr;
  uint8_t temp_bank = (uint8_t) bank;
  uint16_t temp_col = (uint16_t) col;
  uint16_t temp_row = (uint16_t) row;
  uint32_t temp;

    if(temp_bank < CONFIG_BANK && temp_col < CONFIG_SDRAM_COL && temp_row < CONFIG_SDRAM_ROW){
        // printf("read %08x, %08x\n", addr, temp);
        temp = sdram[temp_bank][temp_col][temp_row];
        *data = (int)temp;
        // printf("read %04x, %04x, %08x\n", temp_col, temp_row, temp);
    }
    else{
      printf("%04x, %04x, %04x\n", temp_bank, temp_col, temp_row);
      printf("sdram out of bound\n");
      assert(0);
    }
    return;
}

extern "C" void sdram0_write(char bank, short row, short col, char mask, int data) {
  
  uint8_t temp_bank = (uint8_t) bank;
  uint8_t temp_mask = (uint8_t) mask;
  uint16_t temp_col = (uint16_t) col;
  uint16_t temp_row = (uint16_t) row;
  uint32_t temp_data = (uint32_t) data;

  if(temp_bank < CONFIG_BANK && temp_col < CONFIG_SDRAM_COL && temp_row < CONFIG_SDRAM_ROW){
    if(mask == 0x00){

      sdram[temp_bank][temp_col][temp_row] = temp_data;
      // printf("write %04x, %04x, %04x, %08x\n", temp_bank, temp_col, temp_row, (uint32_t)temp_data);
    }
    else if(mask == 0x0E){ // 1110
      sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0xFFFFFF00) | (temp_data & 0x000000FF);
    }
    else if(mask == 0x0D){ // 1101
      sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0xFFFF00FF) | (temp_data & 0x0000FF00);
    }
    else if(mask == 0x0B){ // 1011
      sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0xFF00FFFF) | (temp_data & 0x00FF0000);
    }
    else if(mask == 0x07){ // 0111
      sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0x00FFFFFF) | (temp_data & 0xFF000000);
    }
    else if(mask == 0x03){ // 0011
      sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0x0000FFFF) | (temp_data & 0xFFFF0000);
    }
    else if(mask == 0x0C){ // 1100
      sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0xFFFF0000) | (temp_data & 0x0000FFFF);
    }
    else {
    }
    // printf("write %08x, %08x\n", temp, (uint8_t)data);
  }
  else{
    printf("%04x, %04x, %04x\n", temp_bank, temp_col, temp_row);
    printf("sdram is out of bound\n");
    assert(0);
  }
}

// extern "C" void sdram1_read(char bank, short row, short col, short *data){
//   // paddr_t addr_r = (paddr_t)addr;
//   uint8_t temp_bank = (uint8_t) bank;
//   uint16_t temp_col = (uint16_t) col;
//   uint16_t temp_row = (uint16_t) row;
//   uint16_t temp;

//     if(temp_bank < CONFIG_BANK && temp_col < CONFIG_SDRAM_COL && temp_row < CONFIG_SDRAM_ROW){
//         // printf("read %08x, %08x\n", addr, temp);
//         temp = sdram[temp_bank][temp_col][temp_row];
//         *data = (short)temp;
//         // printf("read %04x, %04x, %04x\n", temp_col, temp_row, temp);
//     }
//     else{
//         printf("sdram out of bound\n");
//         assert(0);
//     }
//     return;
// }

// extern "C" void sdram1_write(char bank, short row, short col, char mask, short data) {
  
//   uint8_t temp_bank = (uint8_t) bank;
//   uint8_t temp_mask = (uint8_t) mask;
//   uint16_t temp_col = (uint16_t) col;
//   uint16_t temp_row = (uint16_t) row;
//   uint16_t temp_data = (uint16_t) data;

//   if(temp_bank < CONFIG_BANK && temp_col < CONFIG_SDRAM_COL && temp_row < CONFIG_SDRAM_ROW){
//     if(mask == 0x00){
//       sdram[temp_bank][temp_col][temp_row] = temp_data;
//       // printf("write %08x, %08x\n", temp, (uint8_t)data);
//     }
//     else if(mask == 0x01){
//       // printf("%04x\n", sdram[temp_bank][temp_col][temp_row]);
//       sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0x00FF) | (temp_data & 0xFF00);
//       // printf("%04x, %04x\n", sdram[temp_bank][temp_col][temp_row], temp_data);
//     }
//     else if(mask == 0x02){
//       // printf("%04x\n", sdram[temp_bank][temp_col][temp_row]);
//       sdram[temp_bank][temp_col][temp_row] = (sdram[temp_bank][temp_col][temp_row] & 0xFF00) | (temp_data & 0x00FF);
//       // printf("%04x, %04x\n", sdram[temp_bank][temp_col][temp_row], temp_data);
//     }
//     else {
//     }
//     // printf("write %08x, %08x\n", temp, (uint8_t)data);
//   }
//   else{
//     printf("sdram is out of bound\n");
//     // assert(0);
//   }
// }