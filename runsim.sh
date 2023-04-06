#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: runsim.sh <test name> <model: rtl/behavioral(default)"
    exit 1
fi

DIR=$(dirname $0)
TEST=$1
MODEL=${2:-behavioral}

DRAMCFG=$DIR/dramsim/DDR4_4Gb_x16_2666_2.ini
HEXFILE=$DIR/tests/$TEST.hex
ELFFILE=$DIR/tests/$TEST.elf
LOGFILE=$DIR/tests/$TEST.log
UARTFILE=$DIR/tests/$TEST.out

make -C $DIR/tests || exit $?
make -C $DIR/$MODEL || exit $?

TIMEOUT=100000

#timeout $TIMEOUT $DIR/$MODEL/build/top +dramcfg=$DRAMCFG +memfile=$HEXFILE +uartfile=$UARTFILE +logfile=$LOGFILE &
timeout $TIMEOUT $DIR/$MODEL/build/top +dramcfg=$DRAMCFG +memfile=$HEXFILE +uartfile=$UARTFILE +dumpon +dumpranges=30000000+500000 &
SIMPID=$!

ERROR=0

wait $SIMPID
if [ $? -eq 124 ]; then
    echo "ERROR: rtl timed out"
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
