#!/bin/sh

if [ $# -lt 1 ]; then
    echo "Usage: runtest.sh <test name> <model: rtl/behavioral(default)"
    exit 1
fi

DIR=$(dirname $0)
DIR=$(realpath $DIR)
TEST=$1
MODEL=${2:-behavioral}

DRAMCFG=$DIR/dramsim/DDR4_4Gb_x16_2666_2.ini
HEXFILE=$DIR/tests/$TEST.hex
ELFFILE=$DIR/tests/$TEST.elf
LOGFILE=$DIR/tests/$TEST.log
UARTFILE=$DIR/tests/$TEST.out

make -C $DIR/tests || exit $?
make -C $DIR/$MODEL || exit $?

rm -f $DIR/simtrace

mkfifo $DIR/simtrace
#timeout -s9 $TIMEOUT $DIR/$MODEL/build/top +dramcfg=$DRAMCFG +memfile=$HEXFILE +tracefile=simtrace +uartfile=$UARTFILE +logfile=$LOGFILE &
$DIR/$MODEL/build/top \
    --testplusarg dramcfg=$DRAMCFG \
    --testplusarg memfile=$HEXFILE \
    --testplusarg tracefile=$DIR/simtrace \
    --testplusarg uartfile=$UARTFILE \
    --testplusarg logfile=$LOGFILE &
SIMPID=$!

$DIR/runspike.sh --log-commits --cosim=$DIR/simtrace $ELFFILE 2>/dev/null &
SPIKEPID=$!

ERROR=0

wait $SIMPID
if [ $? -ne 0 ]; then
    echo "ERROR: rtl returned non-zero"
    ERROR=1
fi

wait $SPIKEPID; SPIKESTATUS=$?
if [ $SPIKESTATUS -eq 124 ]; then
    echo "ERROR: spike timed out"
    ERROR=1
elif [ $SPIKESTATUS -ne 0 ]; then
    echo "ERROR: spike exited with non-zero status"
    ERROR=1
fi

rm -f $DIR/simtrace
$DIR/checkmem.py $LOGFILE
if [ $? -ne 0 ]; then
    ERROR=1
fi

if [ $ERROR -ne 0 ]; then
    echo "TEST FAILED"
fi

exit $ERROR
