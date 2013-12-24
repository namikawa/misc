#!/bin/bash

# conf
FILENAME=/data/testfile
SIZE=20G
RUNTIME=16
SLEEPTIME=10

# exec
for IODEPTH in 1 2 4 8 16 32 64 128 256; do
  echo "----- iodepth=$IODEPTH -----"
  for TYPE in read write randread randwrite; do
    fio -direct=1 -ioengine=libaio -readwrite=$TYPE \
        -filename=$FILENAME -size=$SIZE -runtime=$RUNTIME \
        -bs=4k -iodepth=$IODEPTH -name=file1 | grep "iops="
    sleep $SLEEPTIME
  done
done

