#!/usr/bin/bash

dir=$(dirname $0)
dir=$(realpath $dir)

function usage {
    cat <<EOF
Usage: runtest.sh [options] <test name>

Options:
  --list (-l)
    List the available tests.

  --dump (-d)
    Enable waveform dumping (output file is named top.fst).

  --dumpranges (-r) <N+N,N+N,...>
    Specify one or more time ranges to dump using 'base+len' notation.

  --stopat (-s) <N>
    Stop the simulation at the specified time.

  --disable-cosim
    Do not run spike or perform any instruction trace checking.
EOF
}

function list_tests {
    find $dir/tests/ -maxdepth 1 -name \*.hex -printf "%P\n" | xargs basename -as .hex
}

# Note that we use "$@" to let each command-line parameter expand to a
# separate word. The quotes around "$@" are essential!
# We need TEMP as the 'eval set --' would nuke the return value of getopt.
temp=$(getopt -o 'ldr:s:' --long 'list,dump,dumpranges:,stopat:,disable-cosim' -n 'runtest.sh' -- "$@")
if [ $? -ne 0 ]; then
    usage
    exit 1
fi
eval set -- "$temp"
unset temp

plusargs=
cosim=1
while true; do
    case "$1" in
        '-l'|'--list')
            list_tests
            exit 0;;
	'-d'|'--dump')
	    plusargs="$plusargs +dumpon"
	    shift;;
	'-r'|'--dumpranges')
            plusargs="$plusargs +dumpranges=$2"
	    shift 2;;
	'-s'|'--stopat')
            plusargs="$plusargs +stopat=$2"
	    shift 2;;
        '--disable-cosim')
            cosim=0
            shift;;
	'--')
	    shift
	    break;;
	*)
	    echo 'ERROR: unexpected value returned from getopt' >&2
	    exit 1;;
    esac
done

if [ $# -ne 1 ]; then
    usage
    exit 1
fi
test=$1

make -C $dir/tests || exit $?
make -C $dir/rtl || exit $?

rm -f $dir/simtrace
mkfifo $dir/simtrace

plusargs="$plusargs +dramcfg=$dir/dramsim/DDR4_4Gb_x16_2666_2.ini"
plusargs="$plusargs +memfile=$dir/tests/$test.hex"
plusargs="$plusargs +uartfile=$dir/tests/$test.out"
plusargs="$plusargs +logfile=$dir/tests/$test.log"

if [ $cosim -ne 0 ]; then
    tracefile=$dir/simtrace
else
    tracefile=$dir/tests/$test.trace
fi
plusargs="$plusargs +tracefile=$tracefile"

$dir/rtl/build/top $plusargs &
simpid=$!

spikepid=
spikestatus=
if [ $cosim -ne 0 ]; then
    $dir/runspike.sh \
        --log-commits \
        --cosim=$dir/simtrace \
        $dir/tests/$test.elf \
        2>/dev/null &
    spikepid=$!
else
    spikestatus=0
fi

function fail {
    echo "TEST FAILED"
    rm -f $dir/simtrace
    exit 1
}

simstatus=
until [ -n "$simstatus" ] && [ -n "$spikestatus" ]; do
    wait -n -p pid $simpid $spikepid
    status=$?
    case $pid in
        $simpid) simstatus=$status; simpid=;;
        $spikepid) spikestatus=$status; spikepid=;;
        *) echo "error: unexpected return value from wait: $pid"; fail;;
    esac
    if [ $status -ne 0 ]; then break; fi
done

if [ -n "$simstatus" ] && [ $simstatus -ne 0 ]; then
    echo "ERROR: rtl returned non-zero status: $simstatus"
    fail
fi

if [ -n "$spikestatus" ] && [ $spikestatus -ne 0 ]; then
    echo "ERROR: spike returned non-zero status: $spikestatus"
    fail
fi

if [ -z "$simstatus" ] || [ -z "$spikestatus" ]; then
    echo "ERROR: missing return status from rtl or spike"
    fail
fi

$dir/checkmem.py $dir/tests/$test.log
if [ $? -ne 0 ]; then
    fail
fi

rm -f $dir/simtrace
exit 0
