#!/bin/bash
BASE=../public/release/models/
INC=
for i in $(find $BASE -type d); do
    INC+="-P $i "
done
for i in $(find $BASE -type d); do
    MM=$i/openconfig-$(basename $i).yang;
    if [[ -e $MM ]]; then
        echo "---------- Trying compile : $MM ----------";
        ./lyang $INC $MM
    fi
done
