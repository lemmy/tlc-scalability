#!/bin/bash

SPEC="Bakery"

# Check Grid5k.tla for semantical meaning
K=${1-"04"}
L=${2-"01"}
N=${3-"10"}
C=${4-"04"}
MODEL='k'$K'_l'$L'_n'$N'_c'$C

# Performance related properties
WORKERS=${5-"$(nproc --all)"}
HEAP_MEM=${6-"32G"}
DIRECT_MEM=${7-"32g"}
FPSET_IMPL="tlc2.tool.fp.OffHeapDiskFPSet"

# TLC version
REV=mku-pagequeue

# measure.sh's fs path
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# TLC's code location
TLATOOLS_HOME=$(pwd)

# Trap interrupts and exit instead of continuing the for loop below
trap "echo Exited!; exit;" SIGINT SIGTERM

######################################

# Generate TLC's config on-the-fly

# Repeat N times to even out noise...
for i in {10..4000}; do
        # For varying worker (core) counts...
        for w in 6 7 8; do

          # Output/log files
          JFR_OUTPUT_FILE=$REV'_w'$w'_i'$i.jfr
          TIME_OUTPUT_FILE=$REV-$w.txt
          TLC_OUTPUT_FILE=$REV-$i-$w-tlc.txt

          /usr/bin/time --append --output=$TIME_OUTPUT_FILE \
          java -XX:StartFlightRecording=filename=tlc-$(date +%s).jfr -XX:+UnlockDiagnosticVMOptions -XX:+DebugNonSafepoints -XX:+UseParallelGC \
           -XX:MaxDirectMemorySize=$DIRECT_MEM \
           -Dtlc2.tool.fp.FPSet.impl=$FPSET_IMPL \
           -cp tla2tools.jar \
           -DspecName=$SPEC \
           -DmodelName=$MODEL \
           -DOFFtlc2.TLC.stopAfter=300 \
           -Dtlc2.TLC.asMilliSeconds=true \
           -DOFFtlc2.tool.queue.PageQueue.PageSize=4096 \
           -DOFFtlc2.tool.queue.PageQueue.InMemoryPages=512 \
           tlc2.TLC -deadlock -checkpoint 99999 -workers $w MC 2>&1 | tee $TLC_OUTPUT_FILE;
          # newer TLC versions support "-checkpoint 0", but 99999 suffices.

          # cleanup left-over states/ directory to free disk space
          rm -rf states/

        done
done
