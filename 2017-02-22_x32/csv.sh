#!/bin/bash

echo "Processes,Insertions,Duration"

for file in $1/spin-*.txt; do

   FILE=$(cat $file)
   PROCESSORS=$(echo $FILE | grep -Po 'pan: using \K[0-9]+')
   PROCESS_ALIGNED=$(printf "%03d" $PROCESSORS)
   INSERTIONS=$(echo $FILE | grep -Po '[0-9+e.]+(?= states, stored)')
   DURATION=$(echo $FILE | grep -Po 'pan: elapsed time \K[^ ]+')

   echo $PROCESS_ALIGNED,$INSERTIONS,$DURATION
done


