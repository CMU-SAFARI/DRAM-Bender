#!/bin/bash
mkdir -p results

for i in {1..10}
do
  sudo ./TEST 1 "results/AND-log$i.csv" > /dev/null
done

for i in {1..10}
do
  sudo ./TEST 0 "results/OR-log$i.csv" > /dev/null
done
