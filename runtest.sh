#!/usr/bin/bash

dir=$(dirname $0)
dir=$(realpath $dir)

function usage {
    cat <<EOF
Usage: runtest.sh [options] <test name>...
       runtest.sh [options] --all

Options:
  --list (-l)
    List the available tests.

  --all (-a)
    Run all tests and print a summary table showing which tests passed/failed.

  --dump (-d)
    Enable waveform dumping (output file is named top.fst).

  --dumpranges (-r) <N+N,N+N,...>
    Specify one or more time ranges to dump using 'base+len' notation.

  --stopat (-s) <N>
    Stop the simulation at the specified time.

  --only-rtl
    Only run RTL simulation and disable instruction trace checking.

  --only-spike
    Only run spike simulation and disable instruction trace checking.
EOF
}

function list_tests {
    find $dir/tests/ -maxdepth 1 -name \*.hex -printf "%P\n" | xargs basename -as .hex
}

# Note that we use "$@" to let each command-line parameter expand to a
# separate word. The quotes around "$@" are essential!
# We need TEMP as the 'eval set --' would nuke the return value of getopt.
temp=$(getopt -o 'ladr:s:' --long 'list,all,dump,dumpranges:,stopat:,only-rtl,only-spike' -n 'runtest.sh' -- "$@")
if [ $? -ne 0 ]; then
    usage
    exit 1
fi
eval set -- "$temp"
unset temp

plusargs=
run_rtl=1
run_spike=1
run_all_tests=0
while true; do
    case "$1" in
        '-l'|'--list')
            list_tests
            exit 0;;
        '-a'|'--all')
            run_all_tests=1
            shift;;
	'-d'|'--dump')
	    plusargs="$plusargs +dumpon"
	    shift;;
	'-r'|'--dumpranges')
            plusargs="$plusargs +dumpranges=$2"
	    shift 2;;
	'-s'|'--stopat')
            plusargs="$plusargs +stopat=$2"
	    shift 2;;
        '--only-rtl')
            run_spike=0
            shift;;
        '--only-spike')
            run_rtl=0
            shift;;
	'--')
	    shift
	    break;;
	*)
	    echo 'ERROR: unexpected value returned from getopt' >&2
	    exit 1;;
    esac
done

if [ $run_rtl -eq 0 ] && [ $run_spike -eq 0 ]; then
    echo "ERROR: nothing left to do"
    exit 1
fi

if [ $# -eq 0 ]; then
    if [ $run_all_tests -eq 0 ]; then
        echo "ERROR: no tests specified"
        usage
        exit 1
    fi
    tests=$(list_tests)
else
    if [ $run_all_tests -ne 0 ]; then
        echo "ERROR: cannot specify test names with --all option"
        usage
        exit 1
    fi
    tests=$@
fi

function runspike {
    spike --isa=RV32IM \
          -m0x10000000:0x1000000,0x20000000:0x8000000,0x30000000:0x1000 \
          --extension=hashset \
          --csrmask=cycle,cycleh,instret,instreth,mbfsstat,mbfsroot,mbfstarg,mbfsqbase,mbfsqsize,mbfsresult,mcycle,minstret,mcycleh,minstreth,ml2stat \
          "$@"
}

function run_test {
    test=$1
    plusargs=$2

    if [ $run_spike -ne 0 ]; then
        make -C $dir/tests $test.elf || return 1
    fi
    if [ $run_rtl -ne 0 ]; then
        make -C $dir/tests $test.hex || return 1
        make -C $dir/rtl || return 1
    fi

    rm -f $dir/simtrace

    simpid=
    simstatus=
    if [ $run_rtl -ne 0 ]; then
        plusargs="$plusargs +dramcfg=$dir/dramsim/DDR4_4Gb_x16_2666_2.ini"
        plusargs="$plusargs +memfile=$dir/tests/$test.hex"
        plusargs="$plusargs +uartfile=$dir/tests/$test.out"
        plusargs="$plusargs +logfile=$dir/tests/$test.log"

        if [ $run_spike -ne 0 ]; then
            mkfifo $dir/simtrace
            tracefile=$dir/simtrace
        else
            tracefile=$dir/tests/$test.trace
        fi
        plusargs="$plusargs +tracefile=$tracefile"

        $dir/rtl/build/top $plusargs &
        simpid=$!
    else
        simstatus=0
    fi

    spikepid=
    spikestatus=
    if [ $run_spike -ne 0 ]; then
        spike_args=$dir/tests/$test.elf
        if [ $run_rtl -ne 0 ]; then
            spike_args="--cosim=$dir/simtrace $spike_args"
        fi

        runspike $spike_args &
        spikepid=$!
    else
        spikestatus=0
    fi

    until [ -n "$simstatus" ] && [ -n "$spikestatus" ]; do
        wait -n -p pid $simpid $spikepid
        status=$?
        case $pid in
            $simpid) simstatus=$status; simpid=;;
            $spikepid) spikestatus=$status; spikepid=;;
            *) echo "ERROR: unexpected return value from wait: $pid"; return 1;;
        esac
        if [ $status -ne 0 ]; then break; fi
    done

    if [ -n "$simstatus" ] && [ $simstatus -ne 0 ]; then
        echo "ERROR: rtl returned non-zero status: $simstatus"
        return 1
    fi

    if [ -n "$spikestatus" ] && [ $spikestatus -ne 0 ]; then
        echo "ERROR: spike returned non-zero status: $spikestatus"
        return 1
    fi

    if [ -z "$simstatus" ] || [ -z "$spikestatus" ]; then
        echo "ERROR: missing return status from rtl or spike"
        return 1
    fi

    if [ $run_rtl -ne 0 ]; then
        $dir/checkmem.py $dir/tests/$test.log
        if [ $? -ne 0 ]; then return 1; fi
    fi

    rm -f $dir/simtrace
    return 0
}

eval set -- $tests
if [ $# -eq 1 ]; then
    # Single test mode
    run_test $1 $plusargs
else
    # Summary table mode
    for test; do
        printf "%-16s" $test
        run_test $test $plusargs >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "passed"
        else
            echo "failed"
        fi
    done
fi
