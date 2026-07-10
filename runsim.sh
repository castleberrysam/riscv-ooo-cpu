#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: runsim.sh <test name> [additional args]"
    exit 1
fi

DIR=$(dirname $0)
DIR=$(realpath $DIR)
TEST=$1; shift

DRAMCFG=$DIR/dramsim/DDR4_4Gb_x16_2666_2.ini
HEXFILE=$DIR/tests/$TEST.hex
TRACEFILE=$DIR/tests/$TEST.trace
ELFFILE=$DIR/tests/$TEST.elf
LOGFILE=$DIR/tests/$TEST.log
UARTFILE=$DIR/tests/$TEST.out

make -C $DIR/tests || exit $?
make -C $DIR/rtl || exit $?

$DIR/rtl/build/top \
    +dramcfg=$DRAMCFG \
    +memfile=$HEXFILE \
    +tracefile=$TRACEFILE \
    +uartfile=$UARTFILE \
    +logfile=$LOGFILE \
    $@ &
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
