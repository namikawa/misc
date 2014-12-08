#!/bin/bash

# conf
FILENAME=/data/testfile
SIZE=20G
RUNTIME=60
SLEEPTIME=10

# exec
for NUMJOB in 1 2 4 8 16 32 64 128; do
  echo "----- numjobs=$NUMJOB -----"
  for TYPE in read write randread randwrite; do
  #for TYPE in read write randread randwrite rw randrw; do
    fio -direct=1 -readwrite=$TYPE -group_reporting \
        -filename=$FILENAME -size=$SIZE -runtime=$RUNTIME \
        -bs=4k -numjobs=$NUMJOB -name=file1 | grep "iops="
    sleep $SLEEPTIME
  done
done

