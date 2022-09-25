#!/bin/bash


($( dirname "${BASH_SOURCE[0]}" )/SoftMC_reset) &
pid=$!

sleep 2

kill -9 $pid
