SIM := xsim

DRAMSIM := $(shell realpath $(CURDIR)/../dramsim)
MICRON := $(shell realpath $(CURDIR)/../micron)
MIG := $(shell realpath $(CURDIR)/../impl/ip/dram_mig/dram_mig/user_design/rtl)

SRCS := $(shell realpath $(CURDIR)/../sim/timescale)
SRCS += $(wildcard $(CURDIR)/*.v) $(wildcard $(CURDIR)/*.vh)
SRCS += $(shell realpath $(wildcard $(CURDIR)/../rtl/lib/*.v))
SRCS += $(CURDIR)/bfs/bfs_core.v $(CURDIR)/bfs/bfs_queue.v $(CURDIR)/bfs/queue_main.v $(CURDIR)/bfs/queue_out.v
SRCS += $(shell realpath $(CURDIR)/../sim/tb_top.v)
SRCS += $(MICRON)/ddr3.v

AUTO_SRCS := $(wildcard *.v.in)
SRCS += $(patsubst %,$(CURDIR)/%,$(AUTO_SRCS:%.v.in=build/%.v))

INCLUDES := $(CURDIR)
INCLUDES += $(shell find $(MIG) -type d)
INCLUDES += $(MICRON)

DEFINES := den2048Mb sg125 x16 BFS_UNIT

ifeq ($(SIM),vcs)
SRCS += $(DRAMSIM)/dramsim_vpi.cc
SIMOPTS := -full64 +v2k +warn=all +race=all -top tb_top
SIMOPTS += +vpi -CFLAGS "-I$(DRAMSIM)/DRAMsim3/src"
SIMOPTS += -LDLFLAGS "-L$(DRAMSIM)/DRAMsim3 -Wl,--push-state,--no-as-needed,--whole-archive -l:libdramsim3.a -Wl,--pop-state"
SIMOPTS += -P $(DRAMSIM)/pli.tab
SIMOPTS += -o build/top

INCLUDES := $(patsubst %,-y %,$(INCLUDES))
DEFINES := $(patsubst %,-D %,$(DEFINES))

build/top: $(SRCS) $(DRAMSIM)/DRAMsim3/libdramsim3.a
	$(SIM) $(SIMOPTS) $(INCLUDES) $(DEFINES) $(SRCS)
else ifeq ($(SIM),verilator)
SRCS += $(shell realpath $(CURDIR)/../sim/tb_top.cc) $(DRAMSIM)/dramsim_verilator.cc
SIMOPTS := --cc --exe --Mdir build --top tb_top
SIMOPTS += -CFLAGS "-I$(DRAMSIM) -I$(DRAMSIM)/DRAMsim3/src -march=native"
SIMOPTS += -LDFLAGS "-L$(DRAMSIM)/DRAMsim3 -Wl,--push-state,--no-as-needed,--whole-archive -l:libdramsim3.a -Wl,--pop-state"
SIMOPTS += --trace-fst --trace-threads 1 --trace-max-array 128
SIMOPTS += -o top

INCLUDES := $(patsubst %,-y %,$(INCLUDES))
DEFINES := $(patsubst %,-D %,$(DEFINES))

build/top: $(SRCS) $(DRAMSIM)/DRAMsim3/libdramsim3.a
	$(SIM) $(SIMOPTS) $(INCLUDES) $(DEFINES) $(SRCS)
	$(MAKE) -C build -f Vtb_top.mk OPT_SLOW=-O2 OPT_FAST=-O3 OPT_GLOBAL=-O3
else ifeq ($(SIM),iverilog)
SIMOPTS := -g2012 -s tb_top
SIMOPTS += -m$(DRAMSIM)/DRAMsim3/dramsim3.vpi
SIMOPTS += -o build/top

INCLUDES := $(patsubst %,-y %,$(INCLUDES)) $(patsubst %,-I %,$(INCLUDES))
DEFINES := $(patsubst %,-D %,$(DEFINES))

build/top: $(SRCS) $(DRAMSIM)/DRAMsim3/dramsim3.vpi
	$(SIM) $(SIMOPTS) $(INCLUDES) $(DEFINES) $(SRCS)

$(DRAMSIM)/DRAMsim3/dramsim3.vpi: $(DRAMSIM)/DRAMsim3/libdramsim3.a
	cd $(DRAMSIM)/DRAMsim3/ && iverilog-vpi --name=dramsim3 -Isrc/ -DICARUS_VERILOG src/*.o $(DRAMSIM)/dramsim_vpi.cc
else ifeq ($(SIM),xsim)
LIBS := -L unimacro_ver -L unisims_ver -L secureip
DEFINES += XILINX

INCLUDES := $(patsubst %,--include %,$(INCLUDES))
DEFINES  := $(patsubst %,-d %,$(DEFINES))

build/top: build/xsim.dir/work/work.rlx build/xsim.dir/dram_mig/dram_mig.rlx build/xsim.dir/glbl/glbl.rlx | build
	cd build && xelab --relax -a $(DEFINES) $(LIBS) -L dram_mig tb_top glbl.glbl
	mv build/axsim.sh build/top
	sed -i -e '5i cd "$${BASH_SOURCE%/*}"' build/top

build/xsim.dir/work/work.rlx: $(SRCS) $(HDRS) | build
	cd build && xvlog --relax --sv $(INCLUDES) $(DEFINES) $(SRCS)

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

$(DRAMSIM)/DRAMsim3/libdramsim3.a:
	$(MAKE) -C $(DRAMSIM)/DRAMsim3

build:
	mkdir build

clean:
	@rm -rf csrc build *.vcd
