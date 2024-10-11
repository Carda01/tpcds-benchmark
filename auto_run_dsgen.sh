#!/bin/bash

if [ -n "$SCALE_FACTOR" ]; then
    SF=$SCALE_FACTOR
else
    echo "Insert the scale factor"
    read SF
    echo "Scale factor: $SF"
fi

TMP="data/tmp_$SF"
mkdir $TMP
echo $SF

# Start background processes
./dsdgen -scale $SF -dir $TMP -suffix .csv -delimiter "^" -parallel 4 -child 1 -quiet n -terminate n &
pid1=$!            # Capture the process ID of process 1

./dsdgen -scale $SF -dir $TMP -suffix .csv -delimiter "^" -parallel 4 -child 2 -quiet n -terminate n &
pid2=$!            # Capture the process ID of process 2

./dsdgen -scale $SF -dir $TMP -suffix .csv -delimiter "^" -parallel 4 -child 3 -quiet n -terminate n &
pid3=$!            # Capture the process ID of process 3

./dsdgen -scale $SF -dir $TMP -suffix .csv -delimiter "^" -parallel 4 -child 4 -quiet n -terminate n &
pid4=$!            # Capture the process ID of process 4

# Log while waiting for processes to finish
while kill -0 $pid1 2>/dev/null || kill -0 $pid2 2>/dev/null || kill -0 $pid3 2>/dev/null || kill -0 $pid4 2>/dev/null ; do
    du -sh $TMP
    sleep 5   # Log every 5 seconds
done
wait
