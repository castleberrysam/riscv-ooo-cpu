TARGET := riscv64-elf

SRCDIR := $(shell realpath $(CURDIR)/../rtl)

SRCS := $(wildcard $(SRCDIR)/src/*.v) $(wildcard $(SRCDIR)/src/*.vh) $(wildcard $(SRCDIR)/build/*.v) $(wildcard $(SRCDIR)/lib/*.v)

VIVADO_ARGS := -nojou -log $(SRCDIR)/build/vivado.log

.PHONY: all ip dram_mig elab timing prog flash clean

all: top.bit
ip: dram_mig
dram_mig: ip/dram_mig
elab: elab.dcp
timing: timing.dcp

top.bit: $(SRCS) ip rom.mif constraints.xdc synth_full.tcl
	vivado $(VIVADO_ARGS) -mode batch -source synth_full.tcl

elab.dcp: $(SRCS) ip elab.tcl
	vivado $(VIVADO_ARGS) -mode tcl -source elab.tcl

timing.dcp: $(SRCS) ip rom.mif constraints.xdc synth_timing.tcl
	vivado $(VIVADO_ARGS) -mode batch -source synth_timing.tcl

ip/dram_mig: gen_dram_mig.tcl
	vivado $(VIVADO_ARGS) -mode batch -source gen_dram_mig.tcl

%.mif: %.bin bin2mif.py
	./bin2mif.py $< 16384 > $@

%.bin: %.o
	$(TARGET)-objcopy -O binary $< $@

%.o: %.s
	$(TARGET)-as -march=rv32imzicsr -o $@ $<

prog: top.bit prog_fpga.tcl
	vivado $(VIVADO_ARGS) -mode batch -source prog_fpga.tcl

flash: top.mcs top.prm prog_flash.tcl
	vivado $(VIVADO_ARGS) -mode batch -source prog_flash.tcl

top.mcs top.prm &: top.bit gen_mcs.tcl
	vivado $(VIVADO_ARGS) -mode batch -source gen_mcs.tcl

clean:
	-rm -r *.o *.bin *.mif *.bit *.edif *.mcs *.prm *.jou *.log *.html *.xml *.str *.dcp .hbs/ .Xil/
