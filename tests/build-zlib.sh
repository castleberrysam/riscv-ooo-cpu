#!/usr/bin/bash

export CHOST=riscv64-unknown-elf
export ASFLAGS='-march=rv32imzicsr -mabi=ilp32 -I/opt/newlib/riscv64-unknown-elf/include'
export CFLAGS='-march=rv32imzicsr -mabi=ilp32 -isystem /opt/newlib/riscv64-unknown-elf/include -ffunction-sections -fdata-sections -O3 -nostdlib -nostartfiles'
export LDFLAGS='-n -march=rv32imzicsr -mabi=ilp32 -L/opt/newlib/riscv64-unknown-elf/lib -nostartfiles -Wl,--gc-sections -nostdlib -nostartfiles'

rm -rf zlib/build && mkdir zlib/build && cd zlib/build
../configure --insecure
make -j`nproc` libz.a
