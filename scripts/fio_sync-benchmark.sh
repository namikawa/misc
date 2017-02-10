#!/bin/bash

# conf
FILENAME=/data/testfile
SIZE=20G
RUNTIME=60
SLEEPTIME=10

# exec
echo -e "===== IOPS =====\n"
for NUMJOB in 1 2 4 8 16 32 64 128 256; do
  echo "----- numjobs=$NUMJOB -----"
  for TYPE in read write randread randwrite; do
  #for TYPE in read write randread randwrite rw randrw; do
    fio -direct=1 -readwrite=$TYPE -group_reporting \
        -filename=$FILENAME -size=$SIZE -runtime=$RUNTIME \
        -bs=4k -numjobs=$NUMJOB -name=file1 | grep "iops="
    #echo 3 > /proc/sys/vm/drop_caches
    sleep $SLEEPTIME
  done
done

echo -e "\n===== Throughput =====\n"
for TYPE in read write; do
  fio -direct=1 -readwrite=$TYPE -group_reporting \
      -filename=$FILENAME -size=$SIZE -runtime=$RUNTIME \
      -bs=32m -numjobs=16 -name=file1 | egrep "READ:|WRITE:"
  echo 3 > /proc/sys/vm/drop_caches
  sleep $SLEEPTIME
done

