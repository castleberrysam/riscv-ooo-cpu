TOOL_PREFIX := riscv64-unknown-elf
AS := $(TOOL_PREFIX)-as
CC := $(TOOL_PREFIX)-gcc
CXX := $(TOOL_PREFIX)-g++
LD := $(TOOL_PREFIX)-ld
OBJCOPY := $(TOOL_PREFIX)-objcopy
OBJDUMP := $(TOOL_PREFIX)-objdump

# TARGET_ARCH is used by make's implicit rules (yet not documented...)
TARGET_ARC := rv32im
TARGET_ABI := ilp32
TARGET_FLAGS := -march=$(TARGET_ARC)zicsr -mabi=$(TARGET_ABI)

# some prebuilt toolchains do not bundle a C library, so we must use a local build of newlib
NEWLIB_ROOT ?= /opt/newlib/$(TOOL_PREFIX)
NEWLIB_INCLUDE := $(NEWLIB_ROOT)/include
NEWLIB_LIB := $(NEWLIB_ROOT)/lib

ASFLAGS := $(TARGET_FLAGS) -I$(NEWLIB_INCLUDE)
CFLAGS := $(TARGET_FLAGS) -isystem $(NEWLIB_INCLUDE) -Wall -O2 -ffunction-sections -fdata-sections
CXXFLAGS := $(CFLAGS)
LFLAGS := -n $(TARGET_FLAGS) -L$(NEWLIB_LIB) -nostdlib -nostartfiles -Wl,--gc-sections

SRCS_S := $(filter-out startup.s, $(wildcard *.s))
SRCS_C := $(filter-out stdlib.c, $(wildcard *.c))
SRCS_CXX := $(wildcard *.cpp)
# newlib only provides a C library, not C++, for now C++ must be disabled
OUTS_O := $(SRCS_S:.s=.o) $(SRCS_C:.c=.o) #$(SRCS_CXX:.cpp=.o)
OUTS_ELF := $(OUTS_O:.o=.elf) coremark.elf
OUTS_HEX := $(OUTS_O:.o=.hex) coremark.hex
OUTS_DIS := $(OUTS_O:.o=.dis) coremark.dis

.PHONY: all clean

all: $(OUTS_O) $(OUTS_ELF) $(OUTS_HEX) $(OUTS_DIS) startup.o stdlib.o

%.elf: %.o startup.o stdlib.o link.ld
	$(CC) $(LFLAGS) -Tlink.ld -o $*.elf startup.o $< stdlib.o -lc -lm -lnosys -lgcc
coremark.elf: coremark
	$(MAKE) -C coremark $@
	rm -f $@
	ln coremark/$@ $@

zlib/build/libz.a:
	./build-zlib.sh
zlib.o: zlib.c
	$(CC) -c $(CFLAGS) -Izlib -o zlib.o zlib.c
pg1342.o: pg1342.txt
	$(LD) -m elf32lriscv -r -b binary -o pg1342.o pg1342.txt
zlib.elf: zlib.o pg1342.o startup.o stdlib.o link.ld zlib/build/libz.a
	$(CC) $(LFLAGS) -Tlink.ld -o zlib.elf zlib.o pg1342.o startup.o stdlib.o -Lzlib/build -lc -lz

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.xxd: %.bin
	xxd -e -c4 -g4 -R never $< $@

%.hex: %.xxd
	cut -d' ' -f2 $< > $@

%.dis: %.elf
	$(OBJDUMP) -d -Mnumeric -Mno-aliases $< > $@

clean:
	@rm -f *.elf *.hex *.xxd *.o *.bin *.diff *.dis *.log *.stdout *.out
