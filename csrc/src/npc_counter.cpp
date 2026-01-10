#include <npc_counter.h>
#include "svdpi.h"
#include "VysyxSoCFull__Dpi.h"

static uint64_t lui_count = 0;
static uint64_t auipc_count = 0;
static uint64_t alu_count = 0;
static uint64_t lsu_count = 0;
static uint32_t jal_count = 0;
static uint64_t branch_count = 0;

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

extern "C" void inst_add(int no){
    counters[no].inst_count ++;
    inst_type = no;
    return;
}

void cycle_add(int type, uint32_t num){
    counters[type].cycle_count += num;
}

int type_of_inst(){
    return inst_type;
}

void display_counter(){

    printf("           type |   num    | cycles/inst\n");

    for(int i = 0; i < 6; i++){
        if(counters[i].inst_count != 0){
            printf("%15s | %8ld | %ld\n", counters[i].regex, counters[i].inst_count, counters[i].cycle_count/counters[i].inst_count);
        }
    }
}
