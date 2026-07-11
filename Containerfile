FROM debian:trixie-20260623

RUN apt update && \
    apt install -qy \
        vim git make tmux curl texinfo \
        emacs-nox=1:30.1+1-6 \
        g++=4:14.2.0-1 \
        autoconf=2.72-3.1 \
        python3=3.13.5-1 \
        flex=2.6.4-8.2+b4 \
        bison=2:3.8.2+dfsg-1+b2 \
        help2man \
        liblz4-dev=1.10.0-4 \
        zlib1g-dev=1:1.3.dfsg+really1.3.1-1+b1 \
        gcc-riscv64-unknown-elf=14.2.0+19 \
        device-tree-compiler && \
    apt clean && \
    apt distclean

WORKDIR /root

RUN git clone https://github.com/verilator/verilator && \
    cd verilator && \
    git checkout v5.050 && \
    autoconf && \
    ./configure && \
    make -j`nproc` && \
    make install && \
    cd .. && \
    rm -rf verilator

RUN curl -LO ftp://sourceware.org/pub/newlib/newlib-4.6.0.20260123.tar.gz && \
    tar xfa newlib-4.6.0.20260123.tar.gz && \
    mkdir newlib-4.6.0.20260123/build && \
    cd newlib-4.6.0.20260123/build && \
    ../configure --prefix=/opt/newlib --target=riscv64-unknown-elf --disable-multilib CFLAGS_FOR_TARGET='-march=rv32im -mabi=ilp32' && \
    make -j`nproc` && \
    make install && \
    cd .. && \
    rm -rf newlib-4.6.0.20260123*

COPY . riscv-ooo-cpu
WORKDIR riscv-ooo-cpu

RUN git submodule update --init

RUN cd dramsim/DRAMsim3 && make -j`nproc`

RUN mkdir spike/build && \
    cd spike/build && \
    ../configure --enable-commitlog && \
    make -j`nproc` && \
    make install && \
    cd ../.. && \
    rm -rf spike/build
