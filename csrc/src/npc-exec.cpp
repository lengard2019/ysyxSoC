#include "verilated.h"
#include "svdpi.h"

#include "VysyxSoCFull.h"
#include "VysyxSoCFull___024root.h"
#include "VysyxSoCFull__Dpi.h"

#include <mrom.h>
#include <cpu/ftrace.h>
#include <npc_counter.h>
#include <common.h>
#include <locale.h>
#include <cpu/cpu.h>
#include <cpu/difftest.h>
#include <cpu/iringbuf.h>
#include "sdb/sdb.h"

#ifdef CONFIG_NVBOARD
#include <nvboard.h>
#endif

#ifdef CONFIG_VCD_TRACE
#include "verilated_vcd_c.h"
#endif

#ifdef CONFIG_FST_TRACE
#include "verilated_fst_c.h"
#endif

#define MAX_INST_TO_PRINT 10
// void init_monitor(int, char *[]);

NPC_state cpu = {};

static bool ebreak = false;
static uint32_t abort_count = 0;

#ifdef CONFIG_WAVE_TRACE_RIGON
static bool fst_trace_start = false;
#endif

uint64_t g_nr_guest_inst = 0;
uint64_t g_nr_cycle = 0;
static uint64_t g_timer = 0; // unit: us
// static uint64_t timer_start = 0;
// static uint64_t timer_end = 0;

static bool g_print_step = false;
// #ifdef CONFIG_DIFFTEST
static bool difftest_skip_first = false;
// #endif

VerilatedContext* contextp = NULL;
#ifdef CONFIG_VCD_TRACE
// VerilatedFstC* tfp = NULL;
VerilatedVcdC* tfp = NULL;
#endif

#ifdef CONFIG_FST_TRACE
VerilatedFstC* tfp = NULL;
// VerilatedVcdC* tfp = NULL;
#endif

// static vluint64_t time = 0;

static VysyxSoCFull* top;

#ifdef CONFIG_NVBOARD
  void nvboard_bind_all_pins(VysyxSoCFull* top);
#endif

const char *regs[] = {
  "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
  "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
  "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
  "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
};

#ifdef CONFIG_DIFFTEST
extern "C" svBit in_mem(int addr){
  uint32_t addr_r = (uint32_t)addr;
  if(((addr >= 0x30000000) && (addr < 0x31000000)) || ((addr >= 0xa0000000) && (addr < 0xa4000000))){
    return 0;
  }
  return 1;
}
#endif

void step_and_dump_wave(){
    top->clock = !top->clock; // 翻转时钟
    top->eval();
    contextp->timeInc(5);
#ifdef CONFIG_VCD_TRACE
  // if(fst_trace_start == true){
    tfp->dump(contextp->time()); // 记录波形
  // }
#endif
#ifdef CONFIG_FST_TRACE
#ifdef CONFIG_WAVE_TRACE_RIGON
  if(fst_trace_start == true){
    tfp->dump(contextp->time()); // 记录波形
  }
#else
    tfp->dump(contextp->time()); // 记录波形
#endif
#endif
}

void init_npc(int argc, char *argv[]){
    contextp = new VerilatedContext;

    Verilated::commandArgs(argc, argv);

    top = new VysyxSoCFull;
    contextp->traceEverOn(true);
    
#ifdef CONFIG_VCD_TRACE
    tfp = new VerilatedVcdC;
    top->trace(tfp, 20);
    tfp->open("soc_test.vcd");
#endif

#ifdef CONFIG_FST_TRACE
    tfp = new VerilatedFstC;
    top->trace(tfp, 20);
    tfp->open("soc_test.fst");
#endif
    // timer_start = get_time();
    // init
#ifdef CONFIG_NVBOARD
    nvboard_bind_all_pins(top);
    nvboard_init();
#endif

    top->clock = 1;
    top->reset = 1;

    cpu.pc = 0x30000000;
    cpu.reg[0] = 0;



    for (int i = 0; i < 20; i++){
        step_and_dump_wave();
    }

    top->reset = 0;
    step_and_dump_wave(); // 下降沿
    // top->eval();
}

void exit_npc(){
    step_and_dump_wave();
#ifdef CONFIG_VCD_TRACE
    tfp->close();
#endif
#ifdef CONFIG_FST_TRACE
    tfp->close();
#endif
    printf("Simulation completed!\n");
}

/*reg function*/
static inline int check_reg_idx(int idx) {
  IFDEF(CONFIG_RT_CHECK, assert(idx >= 0 && idx < 16));
  return idx;
}

word_t get_reg(int idx){
  // return top->rootp->cpu_top__DOT__u_register__DOT__rf[check_reg_idx(idx)];
  if(idx == 0){
    return 0;
  }
  return top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_register__DOT__rf[check_reg_idx(idx - 1)];
}

void reg_display() {
  for(int i = 1; i < 16 ; i ++){
    printf("reg$%s ---> %08x\n",regs[i], top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_register__DOT__rf[i]);
  }
}
/*end*/

void call_ebreak() {
  ebreak = true;
}

// #ifdef CONFIG_DIFFTEST
static void trace_and_difftest(vaddr_t pc, vaddr_t dnpc, uint32_t inst) {

#ifdef CONFIG_FTRACE
  ftrace_call(pc, dnpc, inst);
  ftrace_ret(inst, pc);
#endif
 
#ifdef CONFIG_ITRACE_COND

  log_write("    %08x %08x\n", pc, top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IDU_ysyx__DOT__instr);
  // if (ITRACE_COND) {
  //   char s[100];
  //   snprintf(s, sizeof(s), "    %08x    %08x", pc, top->rootp->ysyxSoCFull__DOT__dut__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IDU_ysyx__DOT__instr);
  //   ring_write(s); }
#endif
  if (g_print_step) { IFDEF(CONFIG_ITRACE, puts("abc\n")); }
  IFDEF(CONFIG_DIFFTEST, difftest_step(pc, dnpc));

#ifdef CONFIG_WATCHPOINT
  for(int i = 0; i < 32;i++){
    
    if(watchpoint_diff(i) == true)
    {
      npc_state.state = NPC_STOP;
      print_watchpoint(i);
    }
    wp_init(i);
  }
#endif
}
// #endif

static void state_copy(){
  for(int i = 0; i < 16; i++){
    cpu.reg[i] = get_reg(i);
  }
  cpu.pc = cpu_state();
}

static void statistic() {
  IFNDEF(CONFIG_TARGET_AM, setlocale(LC_NUMERIC, ""));
#define NUMBERIC_FMT MUXDEF(CONFIG_TARGET_AM, "%", "%'") PRIu64
  Log("host time spent = " NUMBERIC_FMT " us", g_timer);
  Log("total guest instructions = " NUMBERIC_FMT, g_nr_guest_inst);
  if (g_nr_guest_inst > 0) Log("cycles per instructions = " NUMBERIC_FMT " cycles/inst", g_nr_cycle/g_nr_guest_inst);
  if (g_timer > 0) Log("simulation frequency = " NUMBERIC_FMT " inst/s", g_nr_guest_inst * 1000000 / g_timer);
  else Log("Finish running in less than 1 us and can not calculate the simulation frequency");
}

void assert_fail_msg() {
  reg_display();
  statistic();
}

vaddr_t cpu_state(){
  return top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_LSU_ysyx__DOT__Next_pc_r;
}

static void npc_once(){

#ifdef CONFIG_NVBOARD
  nvboard_update();
#endif
  uint32_t inst_pre = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IDU_ysyx__DOT__instr;

  step_and_dump_wave();  // 上升沿

  uint32_t inst_now = top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IDU_ysyx__DOT__instr;

  IFDEF(CONFIG_DIFFTEST, state_copy());

  // state_copy();
  
  // 下一个时钟上升沿
  if(difftest_skip_first == true){
    trace_and_difftest(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_LSU_ysyx__DOT__Next_pc_r, top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_LSU_ysyx__DOT__Next_pc_r, inst_now);
    difftest_skip_first = false;
  }

  if(top->reset == 0 && top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_LSU_ysyx__DOT__current_state == 6){ // or EXU finish one inst
    // if(difftest_skip_first == true){// 跳过第一次difftest
      // IFDEF(CONFIG_DIFFTEST, state_copy());
      // printf("pc = %08x, Next_pc = %08x\n", top->pc, top->Next_pc);
      // trace_and_difftest(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IFU_ysyx__DOT__pc_r, top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_IFU_ysyx__DOT__pc_r, inst_now);
  //   }
  //   else{
  //     difftest_skip_first = true;
  //   }
  //   g_nr_guest_inst ++;
  //   // printf("262 %d\n", g_nr_guest_inst);
    difftest_skip_first = true;
    g_nr_guest_inst ++;
  }
  

  // if(top->reset == 0 && top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_EXU_ysyx__DOT__current_state == 0){
  //   // if(difftest_skip_first == true){// 跳过第一次difftest
  //     // printf("pc = %08x, Next_pc = %08x\n", top->pc, top->Next_pc);
  //     g_nr_guest_inst ++;
  //     trace_and_difftest(top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_WBU_ysyx__DOT__pc_r, top->rootp->ysyxSoCFull__DOT__asic__DOT__cpu__DOT__cpu__DOT__u_WBU_ysyx__DOT__pc_r, inst_pre);
  // }


  if(inst_pre == inst_now){
    abort_count ++;
  }
  else {
    abort_count = 0;
  }
  
  step_and_dump_wave();  // 下降沿

  g_nr_cycle ++ ;

#ifdef CONFIG_WAVE_TRACE_RIGON
  if(cpu_state() == CONFIG_TRACE_START) {
    fst_trace_start = true;
  }

  if(cpu_state() == CONFIG_TRACE_END) {
    printf("ABORT: CONFIG_TRACE_END\n");
    npc_state.state = NPC_ABORT;
    npc_state.halt_pc = cpu_state();
    npc_state.halt_ret = get_reg(10);
  }
#endif

  if(abort_count >= 20000){ // 保护
    printf("overtime\n");
    npc_state.state = NPC_ABORT;
    npc_state.halt_pc = cpu_state();
    npc_state.halt_ret = get_reg(10);
  }

  if(ebreak == true){
#ifdef CONFIG_COUNTER
    display_counter();
#endif
#ifdef CONFIG_AMAT
    display_amat();
#endif
    npc_state.state = NPC_END;
    npc_state.halt_pc = cpu_state();
    npc_state.halt_ret = get_reg(10);
  }
  
}

void npc_exec(uint64_t n){
  g_print_step = (n < MAX_INST_TO_PRINT); // MAX_INST_TO_PRINT = 10;
  switch (npc_state.state) {
    case NPC_END: case NPC_ABORT: case NPC_QUIT:
      printf("Program execution has ended. To restart the program, exit NEMU and run again.\n");
      return;
    default: npc_state.state = NPC_RUNNING;
  }

  uint64_t timer_start = get_time();

  // 仿真
  for(;n > 0; n --){
    npc_once();
    if (npc_state.state != NPC_RUNNING) break;
    IFDEF(CONFIG_DEVICE, device_update());
  }

  ring_print();

  uint64_t timer_end = get_time();
  g_timer = timer_end - timer_start;

  switch (npc_state.state) {
    case NPC_RUNNING: npc_state.state = NPC_STOP; break;

    case NPC_END: case NPC_ABORT:
      Log("npc: %s at pc = " FMT_WORD,
          (npc_state.state == NPC_ABORT ? ANSI_FMT("ABORT", ANSI_FG_RED) :
           (npc_state.halt_ret == 0 ? ANSI_FMT("HIT GOOD TRAP", ANSI_FG_GREEN) :
            ANSI_FMT("HIT BAD TRAP", ANSI_FG_RED))),
          npc_state.halt_pc); // NEMU_END, halt_ret != 0;
      // printf("148 %d\n", nemu_state.halt_ret);
      // fall through
    case NPC_QUIT: statistic();
  }
}
