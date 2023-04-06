SIM := vcs
DRAMSIM := $(shell pwd)/../dramsim

SRCS := $(shell pwd)/../sim/tb_top.v $(wildcard *.v) bfs/bfs_core.v bfs/bfs_queue.v bfs/queue_main.v bfs/queue_out.v

AUTO_SRCS := $(wildcard *.v.in)
SRCS += $(AUTO_SRCS:%.v.in=build/%.v)

ifeq ($(SIM),vcs)
SRCS += $(DRAMSIM)/dramsim_vpi.cc
SIMOPTS := -full64 +v2k +warn=all +race=all -timescale=1ns/1ps -top tb_top
SIMOPTS += +vpi -CFLAGS "-I$(DRAMSIM)/DRAMsim3/src"
SIMOPTS += -LDLFLAGS "-L$(DRAMSIM)/DRAMsim3 -Wl,--push-state,--no-as-needed,--whole-archive -l:libdramsim3.a -Wl,--pop-state"
SIMOPTS += -P $(DRAMSIM)/pli.tab
SIMOPTS += -o build/top

build/top: $(SRCS) $(DRAMSIM)/DRAMsim3/libdramsim3.a
	$(SIM) $(SIMOPTS) $(SRCS)
else ifeq ($(SIM),verilator)
SRCS += $(shell pwd)/../sim/tb_top.cc $(DRAMSIM)/dramsim_verilator.cc
SIMOPTS := --cc --exe --Mdir build --top tb_top
SIMOPTS += -CFLAGS "-I$(DRAMSIM) -I$(DRAMSIM)/DRAMsim3/src -march=native"
SIMOPTS += -LDFLAGS "-L$(DRAMSIM)/DRAMsim3 -Wl,--push-state,--no-as-needed,--whole-archive -l:libdramsim3.a -Wl,--pop-state"
SIMOPTS += --trace-fst --trace-threads 1 --trace-max-array 128
SIMOPTS += -o top

build/top: $(SRCS) $(DRAMSIM)/DRAMsim3/libdramsim3.a
	$(SIM) $(SIMOPTS) $(SRCS)
	$(MAKE) -C build -f Vtb_top.mk OPT_SLOW=-O2 OPT_FAST=-O3 OPT_GLOBAL=-O3
else ifeq ($(SIM),iverilog)
SRCS := $(shell pwd)/../sim/timescale $(SRCS)
SIMOPTS := -g2012 -s tb_top
SIMOPTS += -m$(DRAMSIM)/DRAMsim3/dramsim3.vpi
SIMOPTS += -o build/top

build/top: $(SRCS) $(DRAMSIM)/DRAMsim3/dramsim3.vpi
	$(SIM) $(SIMOPTS) $(SRCS)
else
$(error Unknown simulator $(SIM))
endif

.PHONY: all clean

all: build/top

build/%.v: $(SRCS) %.v.in | build
	./auto.sh $*.v

$(DRAMSIM)/DRAMsim3/libdramsim3.a:
	$(MAKE) -C $(DRAMSIM)/DRAMsim3
$(DRAMSIM)/DRAMsim3/dramsim3.vpi: $(DRAMSIM)/DRAMsim3/libdramsim3.a
	cd $(DRAMSIM)/DRAMsim3/ && iverilog-vpi --name=dramsim3 -Isrc/ -DICARUS_VERILOG src/*.o $(DRAMSIM)/dramsim_vpi.cc

build:
	mkdir build

clean:
	@rm -rf csrc build *.vcd
