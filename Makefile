TOPNAME = ysyxSoCFull
V_FILE_GEN   = build/ysyxSoCTop.sv
V_FILE_FINAL = build/ysyxSoCFull.v
SCALA_FILES = $(shell find src/ -name "*.scala")
NXDC_FILES = constr/top.nxdc
INC_PATH ?=

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc -I./vsrc/ \
				-O3 --x-assign fast --x-initial fast --noassert

VERILATOR_CFLAGS += --trace-fst --timescale "1ns/1ns" --autoflush --no-timing  \
					+incdir+./perip/uart16550/rtl +incdir+./perip/spi/rtl

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)
YSYXC_PATH = /home/dengzibin/ysyx-workbench/ysyxSoC/csrc/include

STA_HOME = /home/dengzibin/yosys-sta

default: $(BIN)
 
$(shell mkdir -p $(BUILD_DIR))
 
# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# Firtool version
FIRTOOL_VERSION = 1.105.0
FIRTOOL_PATCH_DIR = $(shell pwd)/patch/firtool

VSRCS = $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.vh")
VSRCS += $(shell find $(abspath ./perip) -name "*.v")
VSRCS += $(shell find $(abspath ./build) -name "*.v")
RTL_FILE = "$(shell find $(abspath ./vsrc) -name "*.v")"
CSRCS = $(shell find $(abspath ./csrc/src) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCSS = $(shell find $(abspath ./csrc/src) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
CSRCSS += $(SRC_AUTO_BIND)

SDC_FILE = /home/dengzibin/ysyx-workbench/ysyxSoC/sdc/cpu_top.sdc
RESULT_DIR = /home/dengzibin/ysyx-workbench/ysyxSoC/sta_result
DESIGN = cpu_top

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk
 
# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
YSYXCFLAGS = $(addprefix -I, $(YSYXC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOPNAME)\""

# HEADER := $(wildcard *.h) $(wildcard /home/dengzibin/ysyx-workbench/ysyxSoC/csrc/include/*.h)

LDFLAGS += -lreadline

$(V_FILE_FINAL): $(SCALA_FILES)
# Replace firtool with a newer version
# TODO: This can be removed after chisel publishes a new version
	@./patch/update-firtool.sh $(FIRTOOL_VERSION) $(FIRTOOL_PATCH_DIR)
	CHISEL_FIRTOOL_PATH=$(FIRTOOL_PATCH_DIR)/firtool-$(FIRTOOL_VERSION)/bin \
	mill -i ysyxsoc.runMain ysyx.Elaborate --target-dir $(@D)
	mv $(V_FILE_GEN) $@
	sed -i -e 's/_\(aw\|ar\|w\|r\|b\)_\(\|bits_\)/_\1/g' $@
	sed -i '/firrtl_black_box_resource_files.f/, $$d' $@

$(BIN): $(VSRCS) $(CSRCSS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -CFLAGS , $(YSYXCFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

verilog: $(V_FILE_FINAL)

clean:
	-rm -rf build/

dev-init:
	git submodule update --init --recursive
	cd rocket-chip && git apply ../patch/rocket-chip.patch

run:
	verilator -Wno-fatal --cc $(VSRCS) -I./vsrc/ --exe $(CSRCS) -LDFLAGS -lreadline -CFLAGS "-I/home/dengzibin/ysyx-workbench/ysyxSoC/csrc/include" \
		--top-module ysyxSoCFull --trace-fst --timescale "1ns/1ns" --autoflush --no-timing +incdir+./perip/uart16550/rtl +incdir+./perip/spi/rtl
	make -C obj_dir -f VysyxSoCFull.mk VysyxSoCFull
	./obj_dir/VysyxSoCFull $(ARGS) $(IMG)

nvboard: $(BIN)
	@$^ $(ARGS) $(IMG)

sta: 
	make -C $(STA_HOME) sta DESIGN=$(DESIGN) SDC_FILE=$(SDC_FILE) CLK_FREQ_MHZ=800 CLK_PORT_NAME=clock \
		O=$(RESULT_DIR) RTL_FILES=$(RTL_FILE)

.PHONY: verilog clean dev-init
