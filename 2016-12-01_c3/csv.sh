#!/bin/bash

echo "Implementation,Processors,Insertions,Duration,Memory,LoadFactor,Locks,TblCnt,JunitTime,NUMABalancing,PageDefrag,Govenor,Inst,Reprobe"

for file in $1/*-tlc.txt; do
   PROCESSORS=$(echo $file | cut -d "-" -f3)
   IMPL=$(basename $file | cut -d "_" -f1)
   ITERATION=$(echo $file|cut -d"-" -f2)

   FILE=$(cat $file)
   INSERTIONS=$(echo $FILE | grep -Po 'Total puts: \K[0-9]+')
   DURATION=$(echo $FILE | grep -Po 'duration: \K[^ ]+')
   LOADFACTOR=$(echo $FILE | grep -Po 'total load factor: \K[0-9.]+')
   LOCKS=$(echo $FILE | grep -Po 'FPSet lock count is: \K[0-9]+')
   MEM=$(echo $FILE | grep -Po 'FPSet table count is: \K[^ ]+')
   TBLCNT=$(echo $FILE | grep -Po 'FPSet bucket count is: \K[0-9]+')
   JUNITTIME=$(echo $FILE | grep -Po 'Time: \K[0-9,.]*')
   NUMA=$(echo $FILE | grep -Po 'kernel.numa_balancing = \K[0-9,.]*')
   DEFRAG=$(echo $FILE | grep 'page_defrag = ' | grep -Po '\[.*\]')
   GOVENOR=$(echo $FILE | grep -Po 'scaling_governor = \K[a-z]*')
   TEST=$(echo $FILE | grep -Po 'Running test: \K[a-zA-Z]*')
   INST=$(echo $FILE | grep -Po 'Insertions: \K[0-9,]+' | uniq | sed 's/,//g')

#   REPROBE=0
   REPROBE=$(java oracle.jrockit.jfr.parser.Parser -xml 'Off_511c21600e13141fbb759d048bc90d555f95e74f_w032-'$INST'_i'$ITERATION.jfr | xmlstarlet sel -N jfr=http://www.oracle.com/hotspot/jvm/ -N jvm=http://www.oracle.com/hotspot/jvm/ -N p4108=http://www.hirt.se/jfr/jmx2jfr/ -t -v "//p4108:MBeans_tlc2_tool_fp_DiskFPSet0/p4108:BucketCapacity" | tail -1)

   echo $IMPL,$PROCESSORS,$INSERTIONS,$DURATION,$(echo $MEM | sed s/,//g),$LOADFACTOR,$LOCKS,$TBLCNT,$(echo $JUNITTIME | sed s/,//g),$NUMA,$DEFRAG,$GOVENOR,$INST,$REPROBE
#,$REPROBE
done
