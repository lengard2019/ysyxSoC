// #include <paddr.h>
// #include "svdpi.h"
// #include "VysyxSoCTop__Dpi.h"
// #include <cpu/difftest.h>
// #include <time.h>

// static time_t raw_time;          // time_t 是时间戳类型（通常是 long）
// static struct tm *time_info;     // tm 结构体存储年月日等时间信息

// // 内存数组
// static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {}; // 0x8000000

// uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; } // 0x80000000
// paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }


// static inline word_t host_read(void *addr, int len) {
//     switch (len) {
//       case 1: return *(uint8_t  *)addr;
//       case 2: return *(uint16_t *)addr;
//       case 4: return *(uint32_t *)addr;
//       default: assert(0);
//     }
// }

// static inline void host_write(void *addr, int mask, word_t data) {
//     switch (mask) {
//       case 1:  *(uint8_t  *)addr = data; return;
//       case 3:  *(uint16_t *)addr = data; return;
//       case 15: *(uint32_t *)addr = data; return;
//       default: assert(0);
//     }
// }

// void init_mem() {
// #if   defined(CONFIG_PMEM_MALLOC)
//   pmem = malloc(CONFIG_MSIZE);
//   assert(pmem);
// #endif
//   IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
//   Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
// }

// // void init_mem() {
//   // memset(pmem, 0, CONFIG_MSIZE);
//   // printf("physical memory area [ %08x ,  %08x ]", PMEM_LEFT, PMEM_RIGHT);
// // }
    
// word_t pmem_read(paddr_t addr, int len) {
//   // paddr_t addr_r = (paddr_t)addr;
//   if(addr <= 0x87FFFFFF && addr >= 0x80000000){
//     word_t ret = host_read(guest_to_host(addr), len);
//     return ret;
//   }
//   else{
//     printf("addr = %08x  is out of bound\n", addr);
//     // assert(0);
//   }
//   return 0;
// }

// void pmem_write(paddr_t addr, int mask, word_t data) {
//   if(addr <= 0x87FFFFFF && addr >= 0x80000000){
//     host_write(guest_to_host(addr), mask, data);
//   }
//   else{
//     printf("addr = %08x  is out of bound\n", addr);
//     // assert(0);
//   }
// }

// int pmem_read_v(int addr, int len){
//   paddr_t addr_r = (paddr_t)addr;
//   word_t ret = 0x00000000;
//   uint64_t us = get_time();

//   if(addr_r == CONFIG_RTC_MMIO){
//     ret = (uint32_t)us;
//     // printf("80 mark\n");
//     // difftest_skip_load();
//   }
//   else if(addr_r == CONFIG_RTC_MMIO + 4){
//     ret = us >> 32;
//     // difftest_skip_load();
//   }
//   else if(addr_r == CONFIG_TIME){
//     time(&raw_time);
//     time_info = localtime(&raw_time);
//     ret = (uint32_t)time_info->tm_sec;
//     // difftest_skip_load();
//   }
//   else if(addr_r == CONFIG_TIME + 4){
//     time(&raw_time);
//     time_info = localtime(&raw_time);
//     ret = (uint32_t)time_info->tm_min;
//     // difftest_skip_load();
//   }
//   else if(addr_r == CONFIG_TIME + 8){
//     time(&raw_time);
//     time_info = localtime(&raw_time);
//     ret = (uint32_t)time_info->tm_hour;
//     // difftest_skip_load();
//   }
//   else if(addr_r == CONFIG_TIME + 12){
//     time(&raw_time);
//     time_info = localtime(&raw_time);
//     ret = (uint32_t)time_info->tm_mday;
//     // difftest_skip_load();
//   }
//   else if(addr_r == CONFIG_TIME + 16){
//     time(&raw_time);
//     time_info = localtime(&raw_time);
//     ret = (uint32_t)time_info->tm_mon;
//     // difftest_skip_load();
//   }
//   else if(addr_r == CONFIG_TIME + 20){
//     time(&raw_time);
//     time_info = localtime(&raw_time);
//     ret = (uint32_t)time_info->tm_year;
//     // difftest_skip_load();
//   }
//   else{
//     ret = pmem_read(addr_r, len);
//   }
//   return (int)ret;
// }

// void pmem_write_v(int addr, int mask, int data){
//   paddr_t addr_r = (paddr_t)addr;
//   word_t data_r = (word_t) data;
//   if (addr_r == CONFIG_SERIAL_MMIO){ // uart
//     char ch = (char)(data & 0x000000ff);
//     putc(ch, stderr);
//     difftest_skip_ref();
//   }
//   else if(addr_r == CONFIG_RTC_MMIO || addr_r == CONFIG_RTC_MMIO + 4){
//     // printf("138 mark\n");
//     difftest_skip_ref();
//   }
//   else{
//     pmem_write(addr_r, mask, data_r);
//   } 
// }

// int rand_v(){
//   return rand() % 8 + 1;
// }






