#include <npc_counter.h>
#include "svdpi.h"
#include "VysyxSoCFull__Dpi.h"

// static _Float32 ATMT;
// static float amat;

static float p_hit;

static uint64_t icache_total = 0;
static uint64_t icache_hit = 0;

// static int access_time = 3;
// static int miss_penalty = 37;

enum {LUI, AUIPC, ALU, LSU, JAL, BRANCH, CSR, NO_TYPE};

static int inst_type = NO_TYPE;

static struct counter {
    const char *regex;
    uint64_t inst_count;
    uint64_t cycle_count;
} counters[] = {
    {"lui_inst", 0, 0},
    {"auipc_inst", 0, 0},
    {"alu_inst", 0, 0},       
    {"lsu_inst", 0, 0},
    {"jal_inst", 0, 0},
    {"branch_inst", 0, 0},
    {"csr_inst", 0, 0},
    {"notype", 0, 0},
};

#ifdef CONFIG_COUNTER
extern "C" void inst_add(int no){
    counters[no].inst_count ++;
    inst_type = no;
    return;
}
void display_counter(){

    printf("           type |   num    | cycles/inst\n");

    for(int i = 0; i < 6; i++){
        if(counters[i].inst_count != 0){
            printf("%15s | %8ld | %ld\n", counters[i].regex, counters[i].inst_count, counters[i].cycle_count/counters[i].inst_count);
        }
    }
}
#else
extern "C" void inst_add(int no){ }
void display_counter(){ }
#endif

void cycle_add(int type, uint32_t num){
    counters[type].cycle_count += num;
}

int type_of_inst(){
    return inst_type;
}

#ifdef CONFIG_AMAT
extern "C" void icache_add(int no){
    if(no == 0){
        icache_total ++;
    }
    else if(no == 1) {
        icache_hit ++;
    }
}
void display_amat(){
    if(icache_total !=0 ){ p_hit = (float)icache_hit / (float)icache_total; }
    // amat = (float)access_time + (1 - p_hit) * (float)miss_penalty;
    printf("AMAT: total = %ld, hit = %ld, p_hit = %.2f\n", icache_total, icache_hit, p_hit);
}
#else 
extern "C" void icache_add(int no){ }
void display_amat(){ }
#endif
