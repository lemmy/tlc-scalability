#!/bin/bash

# Performance related properties
WORKERS=${5-"$(nproc --all)"}
HEAP_MEM=${6-"8g"}
DIRECT_MEM=${7-"512g"}
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
for i in {1..3}; do
        # For varying worker (core) counts...
        #for ((w=$WORKERS; w > 0;w=w/2)); do
        #for w in 128 120 112 104 96 88 80 72 64 56 48 40 32 24 16 8 4 2 1; do
        w=3
        for locks in 15; do

          ## MSB Output/log files
          MSB_JFR_OUTPUT_FILE="MSB_"$REV'_w'$(printf "%03d" $w)-$locks'_i'$i.jfr
          MSB_TIME_OUTPUT_FILE="MSB_"$REV-$(printf "%03d" $w)-$locks.txt
          MSB_TLC_OUTPUT_FILE="MSB_"$REV-$i-$(printf "%03d" $w)-$locks-tlc.txt

          /usr/bin/time --append --output=$MSB_TIME_OUTPUT_FILE \
          perf stat -e cache-misses \
          java \
           -XX:+UnlockCommercialFeatures \
           -XX:+UnlockDiagnosticVMOptions \
           -XX:+DebugNonSafepoints \
           -XX:+FlightRecorder \
           -XX:FlightRecorderOptions=defaultrecording=true,disk=true,repository=/tmp,dumponexit=true,dumponexitpath=$MSB_JFR_OUTPUT_FILE,maxage=12h,settings=$TLATOOLS_HOME/jfr/tlc.jfc \
           -javaagent:$TLATOOLS_HOME/jfr/jmx2jfr.jar=$TLATOOLS_HOME/jfr/jmxprobes.xml \
           -Xmx$HEAP_MEM -Xms$HEAP_MEM \
           -Dtlc2.tool.fp.DiskFPSet.logLockCnt=$locks \
           -Dtlc2.tool.fp.MultiThreadedFPSetTest.numThreads=$w \
           -Dtlc2.tool.fp.MultiThreadedFPSetTest.excludes=_BatchedFingerPrintGenerator_LongVecFingerPrintGenerator_PartitionedFingerPrintGenerator \
           -Dtlc2.tool.fp.MultiThreadedFPSetTest.insertions=201326592 \
           -Djava.io.tmpdir=/tmp/ \
           -cp $TLATOOLS_HOME/class:$TLATOOLS_HOME/lib/* \
           org.junit.runner.JUnitCore tlc2.tool.fp.MultiThreadedMSBDiskFPSetTest 2>&1 | tee $MSB_TLC_OUTPUT_FILE;

          echo "page_defrag = $(cat /sys/kernel/mm/transparent_hugepage/defrag)" >> $MSB_TLC_OUTPUT_FILE
          echo "scaling_governor = $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)" >> $MSB_TLC_OUTPUT_FILE
          sysctl kernel.numa_balancing >> $MSB_TLC_OUTPUT_FILE
        done
done

## Honest profiler
#           -agentpath:/mnt/markus/tlaplus/profiler/liblagent.so=interval=7,logPath=/mnt/markus/tlaplus/profiler/$REV-$i-$w.hpl \
