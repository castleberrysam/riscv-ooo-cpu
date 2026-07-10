SIM := verilator
USE_DRAMSIM := 1

all: build/top

SRCS := $(shell realpath $(CURDIR)/../sim/timescale)
SRCS += $(filter-out $(CURDIR)/src/dram_ctl%.v,$(wildcard $(CURDIR)/src/*.v))
SRCS += $(wildcard $(CURDIR)/lib/*.v)
SRCS += $(CURDIR)/src/bfs/bfs_core.v $(CURDIR)/src/bfs/bfs_queue.v $(CURDIR)/src/bfs/queue_main.v $(CURDIR)/src/bfs/queue_out.v
SRCS += $(shell realpath $(CURDIR)/../sim/tb_top.v)

AUTO_SRCS := $(wildcard *.v.in)
AUTO_OUT := $(patsubst %,$(CURDIR)/%,$(AUTO_SRCS:%.v.in=build/%.v))

INCLUDES := $(CURDIR)/src
INCLUDES += $(CURDIR)/val

DEFINES := BFS_UNIT

ifeq ($(USE_DRAMSIM),1)
DRAMSIM := $(shell realpath $(CURDIR)/../dramsim)

SRCS += $(shell realpath $(wildcard $(CURDIR)/../sim/dram_ctl*.v))
SRCS += $(shell realpath $(CURDIR)/../sim/ddr3.v)

$(DRAMSIM)/DRAMsim3/libdramsim3.a:
	$(MAKE) -C $(DRAMSIM)/DRAMsim3
else
MICRON := $(shell realpath $(CURDIR)/../micron)

SRCS += $(CURDIR)/src/dram_ctl.v
SRCS += $(MICRON)/ddr3.v

INCLUDES += $(MICRON)

DEFINES += den2048Mb sg125 x16
endif

ifeq ($(SIM),vcs)
VCS ?= vcs

SIMOPTS := -full64 +v2k +warn=all +race=all -top tb_top
SIMOPTS += -o build/top

ifeq ($(USE_DRAMSIM),1)
SIMOPTS += +vpi -CFLAGS "-I$(DRAMSIM)/DRAMsim3/src"
SIMOPTS += -LDLFLAGS "-L$(DRAMSIM)/DRAMsim3 -Wl,--push-state,--no-as-needed,--whole-archive -l:libdramsim3.a -Wl,--pop-state"
SIMOPTS += -P $(DRAMSIM)/pli.tab

SRCS += $(DRAMSIM)/dramsim_vpi.cc

EXTRA_DEPS += $(DRAMSIM)/DRAMsim3/libdramsim3.a
else
$(error Only dramsim is supported with simulator $(SIM))
endif

INCLUDES_ARG := $(patsubst %,-y %,$(INCLUDES))
DEFINES := $(patsubst %,-D %,$(DEFINES))

build/top: $(SRCS) $(INCLUDES) $(AUTO_OUT) $(EXTRA_DEPS)
	$(VCS) $(SIMOPTS) $(INCLUDES_ARG) $(DEFINES) $(SRCS) $(AUTO_OUT)
else ifeq ($(SIM),verilator)
VERILATOR ?= verilator

SRCS += $(shell realpath $(CURDIR)/../sim/tb_top.cc)
SIMOPTS := --cc --exe --Mdir build --top tb_top
SIMOPTS += --trace-fst --trace-max-array 128
SIMOPTS += -o top

ifeq ($(USE_DRAMSIM),1)
SIMOPTS += -CFLAGS "-I$(DRAMSIM) -I$(DRAMSIM)/DRAMsim3/src -march=native"
SIMOPTS += -LDFLAGS "-L$(DRAMSIM)/DRAMsim3 -Wl,--push-state,--no-as-needed,--whole-archive -l:libdramsim3.a -Wl,--pop-state"

SRCS += $(DRAMSIM)/dramsim_verilator.cc

EXTRA_DEPS += $(DRAMSIM)/DRAMsim3/libdramsim3.a
else
$(error Only dramsim is supported with simulator $(SIM))
endif

INCLUDES_ARG := $(patsubst %,-y %,$(INCLUDES))
DEFINES := $(patsubst %,+define+%,$(DEFINES))

build/top: $(SRCS) $(INCLUDES) $(AUTO_OUT) $(EXTRA_DEPS)
	$(VERILATOR) $(SIMOPTS) $(INCLUDES_ARG) $(DEFINES) $(SRCS) $(AUTO_OUT)
	$(MAKE) -C build -f Vtb_top.mk OPT_SLOW=-O2 OPT_FAST=-O3 OPT_GLOBAL=-O3
else ifeq ($(SIM),iverilog)
IVERILOG ?= iverilog

SIMOPTS := -g2012 -s tb_top
SIMOPTS += -o build/top

ifeq ($(USE_DRAMSIM),1)
SIMOPTS += -m$(DRAMSIM)/DRAMsim3/dramsim3.vpi

EXTRA_DEPS += $(DRAMSIM)/DRAMsim3/dramsim3.vpi

$(DRAMSIM)/DRAMsim3/dramsim3.vpi: $(DRAMSIM)/DRAMsim3/libdramsim3.a
	cd $(DRAMSIM)/DRAMsim3/ && iverilog-vpi --name=dramsim3 -Isrc/ -DICARUS_VERILOG src/*.o $(DRAMSIM)/dramsim_vpi.cc
else
$(error Only dramsim is supported with simulator $(SIM))
endif

INCLUDES_ARG := $(patsubst %,-y %,$(INCLUDES)) $(patsubst %,-I %,$(INCLUDES))
DEFINES := $(patsubst %,-D %,$(DEFINES))

build/top: $(SRCS) $(INCLUDES) $(AUTO_OUT) $(EXTRA_DEPS)
	$(IVERILOG) $(SIMOPTS) $(INCLUDES_ARG) $(DEFINES) $(SRCS) $(AUTO_OUT)
else ifeq ($(SIM),xsim)
XSIM ?= xsim

LIBS := -L unimacro_ver -L unisims_ver -L secureip
LIBS += --sv_lib fstdumper
DEFINES += XILINX

ifneq ($(USE_DRAMSIM),1)
MIG := $(shell realpath $(CURDIR)/../impl/ip/dram_mig/dram_mig/user_design/rtl)
INCLUDES += $(shell find $(MIG) -type d)
else
$(error Only Xilinx MIG is supported with simulator $(SIM))
endif

INCLUDES_ARG := $(patsubst %,--include %,$(INCLUDES))
DEFINES := $(patsubst %,-d %,$(DEFINES))

build/top: build/xsim.dir/work/work.rlx build/xsim.dir/dram_mig/dram_mig.rlx build/xsim.dir/glbl/glbl.rlx | build
	cd build && xelab --relax -a $(DEFINES) $(LIBS) -L dram_mig tb_top glbl.glbl
	mv build/axsim.sh build/top
	sed -i -e '5i cd "$${BASH_SOURCE%/*}"' build/top

build/xsim.dir/work/work.rlx: $(SRCS) $(INCLUDES) $(AUTO_OUT) $(HDRS) | build
	cd build && xvlog --relax --sv $(INCLUDES_ARG) $(DEFINES) $(SRCS) $(AUTO_OUT)

$(MIG):
	make -C ../impl dram_mig

build/xsim.dir/dram_mig/dram_mig.rlx: $(MIG) | build
	cd build && xvlog --relax --work dram_mig $(shell find $(MIG) -mindepth 2 -type f -name \*.v)

build/xsim.dir/glbl/glbl.rlx: $(XILINX_VIVADO)/data/verilog/src/glbl.v | build
	cd build && xvlog --relax --work glbl $(XILINX_VIVADO)/data/verilog/src/glbl.v
else
$(error Unknown simulator $(SIM))
endif

.PHONY: all clean

all: build/top

$(CURDIR)/build/%.v: $(CURDIR)/%.v.in $(SRCS) | build
	./auto.sh $<
$(CURDIR)/build/top.v: $(CURDIR)/build/cpu.v

build:
	mkdir build

clean:
	@rm -rf csrc build *.vcd
