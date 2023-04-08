#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: runsim.sh <test name> <model: rtl/behavioral(default)"
    exit 1
fi

DIR=$(dirname $0)
DIR=$(realpath $DIR)
TEST=$1
MODEL=${2:-behavioral}

DRAMCFG=$DIR/dramsim/DDR4_4Gb_x16_2666_2.ini
HEXFILE=$DIR/tests/$TEST.hex
TRACEFILE=$DIR/tests/$TEST.trace
ELFFILE=$DIR/tests/$TEST.elf
LOGFILE=$DIR/tests/$TEST.log
UARTFILE=$DIR/tests/$TEST.out

make -C $DIR/tests || exit $?
make -C $DIR/$MODEL || exit $?

$DIR/$MODEL/build/top \
        --testplusarg dramcfg=$DRAMCFG \
        --testplusarg memfile=$HEXFILE \
        --testplusarg tracefile=$TRACEFILE \
        --testplusarg uartfile=$UARTFILE \
        --testplusarg logfile=$LOGFILE &
SIMPID=$!

ERROR=0

wait $SIMPID
if [ $? -ne 0 ]; then
    echo "ERROR: simulation returned non-zero"
    ERROR=1
fi

$DIR/checkmem.py $LOGFILE
if [ $? -ne 0 ]; then
    ERROR=1
fi

if [ $ERROR -ne 0 ]; then
    echo "TEST FAILED"
fi

exit $ERROR
