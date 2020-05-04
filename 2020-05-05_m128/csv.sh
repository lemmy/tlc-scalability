#!/bin/bash

echo "Processes,Insertions,Duration"

for file in $1/*-tlc.txt; do
   PROCESSORS=$(echo $file | cut -d "-" -f4)
   PROC_ALIGNED=$(printf "%03d" $PROCESSORS)
   FILE=$(cat $file)
   INSERTIONS=$(echo $FILE | grep -Po '[0-9]+(?= distinct states found,)')
   DURATION=$(echo $FILE | grep -Po 'Finished in \K[^ ]+')

   echo $PROC_ALIGNED,$INSERTIONS,$DURATION
done
