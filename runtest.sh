#!/usr/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: runtest.sh <test name>"
    exit 1
fi

DIR=$(dirname $0)
DIR=$(realpath $DIR)
TEST=$1

DRAMCFG=$DIR/dramsim/DDR4_4Gb_x16_2666_2.ini
HEXFILE=$DIR/tests/$TEST.hex
ELFFILE=$DIR/tests/$TEST.elf
LOGFILE=$DIR/tests/$TEST.log
UARTFILE=$DIR/tests/$TEST.out

make -C $DIR/tests || exit $?
make -C $DIR/rtl || exit $?

rm -f $DIR/simtrace

mkfifo $DIR/simtrace
#timeout -s9 $TIMEOUT $DIR/$MODEL/build/top +dramcfg=$DRAMCFG +memfile=$HEXFILE +tracefile=simtrace +uartfile=$UARTFILE +logfile=$LOGFILE &
$DIR/rtl/build/top \
    +dramcfg=$DRAMCFG \
    +memfile=$HEXFILE \
    +tracefile=$DIR/simtrace \
    +uartfile=$UARTFILE \
    +logfile=$LOGFILE &
SIMPID=$!

$DIR/runspike.sh --log-commits --cosim=$DIR/simtrace $ELFFILE 2>/dev/null &
SPIKEPID=$!

function fail {
    echo "TEST FAILED"
    rm -f $DIR/simtrace
    exit 1
}

SIMSTATUS=
SPIKESTATUS=
until [ -n "$SIMSTATUS" ] && [ -n "$SPIKESTATUS" ]; do
    wait -n -p PID $SIMPID $SPIKEPID
    STATUS=$?
    case $PID in
        $SIMPID) SIMSTATUS=$STATUS; SIMPID=;;
        $SPIKEPID) SPIKESTATUS=$STATUS; SPIKEPID=;;
        *) echo "ERROR: Unexpected return value from wait: $PID"; fail;;
    esac
    if [ $STATUS -ne 0 ]; then break; fi
done

if [ -n "$SIMSTATUS" ] && [ $SIMSTATUS -ne 0 ]; then
    echo "ERROR: rtl returned non-zero status: $SIMSTATUS"
    fail
fi

if [ -n "$SPIKESTATUS" ] && [ $SPIKESTATUS -ne 0 ]; then
    echo "ERROR: spike exited with non-zero status: $SPIKESTATUS"
    fail
fi

if [ -z "$SIMSTATUS" ] || [ -z "$SPIKESTATUS" ]; then
    echo "ERROR: missing return status from sim or spike"
    fail
fi

$DIR/checkmem.py $LOGFILE
if [ $? -ne 0 ]; then
    fail
fi

rm -f $DIR/simtrace
exit 0
