#!/bin/bash

# Performance related properties
WORKERS=${5-"$(nproc --all)"}
HEAP_MEM=${6-"20g"}
DIRECT_MEM=${7-"198g"}
FPSET_IMPL="tlc2.tool.fp.OffHeapDiskFPSet"

# TLC version
REV=$(git rev-parse HEAD)

# measure.sh's fs path
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# TLC's code location
TLATOOLS_HOME=../../tlatools/

# Trap interrupts and exit instead of continuing the for loop below
trap "echo Exited!; exit;" SIGINT SIGTERM

######################################

# Repeat N times to even out noise...
for i in {3..3}; do
        # For varying worker (core) counts...
        #for ((w=$WORKERS; w > 0;w=w/2)); do
        #for w in 128 120 112 104 96 88 80 72 64 56 48 40 32 24 16 8 4 2 1; do
        for w in 32 28 24 20 16 12 8 4 2 1; do

          ## OffHeap
          JFR_OUTPUT_FILE="Off_"$REV'_w'$(printf "%03d" $w)'_i'$i.jfr
          TIME_OUTPUT_FILE="Off_"$REV-$(printf "%03d" $w).txt
          TLC_OUTPUT_FILE="Off_"$REV-$i-$(printf "%03d" $w)-tlc.txt

          /usr/bin/time --append --output=$TIME_OUTPUT_FILE \
          java \
           -XX:+UnlockCommercialFeatures \
           -XX:+UnlockDiagnosticVMOptions \
           -XX:+DebugNonSafepoints \
           -XX:+FlightRecorder \
           -XX:FlightRecorderOptions=defaultrecording=true,disk=true,repository=/tmp,dumponexit=true,dumponexitpath=$JFR_OUTPUT_FILE,maxage=12h,settings=$TLATOOLS_HOME/jfr/tlc.jfc \
           -javaagent:$TLATOOLS_HOME/jfr/jmx2jfr.jar=$TLATOOLS_HOME/jfr/jmxprobes.xml \
           -XX:MaxDirectMemorySize=$DIRECT_MEM \
           -Djava.util.logging.config.file=$TLATOOLS_HOME/logging.properties \
           -Dtlc2.tool.fp.MultiThreadedFPSetTest.numThreads=$w \
           -Dtlc2.tool.fp.MultiThreadedFPSetTest.excludes=_BatchedFingerPrintGenerator_LongVecFingerPrintGenerator_PartitionedFingerPrintGenerator \
           -Dtlc2.tool.fp.MultiThreadedFPSetTest.insertions=25769803776 \
           -Djava.io.tmpdir=/mnt/markus/tmp/ \
           -cp $TLATOOLS_HOME/class:$TLATOOLS_HOME/lib/* \
           org.junit.runner.JUnitCore tlc2.tool.fp.MultiThreadedOffHeapDiskFPSetTest 2>&1 | tee $TLC_OUTPUT_FILE;

          echo "page_defrag = $(cat /sys/kernel/mm/transparent_hugepage/defrag)" >> $TLC_OUTPUT_FILE
          echo "scaling_governor = $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" >> $TLC_OUTPUT_FILE
          sysctl kernel.numa_balancing >> $TLC_OUTPUT_FILE


          rm -rf /mnt/markus/tmp/FP*/
        done
done

## Honest profiler
#           -agentpath:/mnt/markus/tlaplus/profiler/liblagent.so=interval=7,logPath=/mnt/markus/tlaplus/profiler/$REV-$i-$w.hpl \
