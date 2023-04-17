# Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# Original Author: Shay Gal-on

TARGET = riscv64-unknown-elf
AS = $(TARGET)-as
CC = $(TARGET)-gcc
CXX = $(TARGET)-g++
OBJCOPY = $(TARGET)-objcopy
OBJDUMP = $(TARGET)-objdump
STRIP = $(TARGET)-strip

CORE_FILES = core_list_join core_main core_matrix core_state core_util core_portme
HEADERS = coremark.h
SRCS = $(addsuffix .c,$(CORE_FILES)) ../startup.S ../stdlib.c
OBJS = $(addsuffix .o,$(CORE_FILES)) ../startup.o ../stdlib.o

PORT_CFLAGS = -march=rv32im -mabi=ilp32 -mcmodel=medany --static --specs=nano.specs -Wall -O2 -ffunction-sections -fdata-sections -fno-common
FLAGS_STR = "$(PORT_CFLAGS) $(XCFLAGS) $(XLFLAGS)"
CFLAGS = $(PORT_CFLAGS) -I. -DFLAGS_STR=\"$(FLAGS_STR)\"

ifndef ITERATIONS
ITERATIONS=3
endif
CFLAGS += -DITERATIONS=$(ITERATIONS)

LFLAGS := -n -nostartfiles -T../link.ld -Wl,--gc-sections

.PHONY: all compile link clean
all: coremark.elf

ifdef SEPARATE_COMPILE
compile: $(OBJS) $(HEADERS)
link: compile ../startup.o ../stdlib.o ../link.ld
	$(LD) $(LFLAGS) $(XLFLAGS) $(OBJS) -o coremark.elf
else
compile: $(SRCS) $(HEADERS)
	$(CC) $(CFLAGS) $(LFLAGS) $(XCFLAGS) $(XLFLAGS) $(SRCS) -o coremark.elf
link: compile ../startup.o ../stdlib.o ../link.ld
	@echo "Link performed along with compile"
endif

coremark.elf: $(SRCS) $(HEADERS) Makefile
	$(MAKE) link

../startup.o: ../startup.S
	$(MAKE) -C .. startup.o
../stdlib.o: ../stdlib.c
	$(MAKE) -C .. stdlib.o

clean:
	@rm -f *.elf *.hex *.xxd *.o *.bin
