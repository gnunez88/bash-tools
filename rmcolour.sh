#!/bin/bash

# Remove colour and other font style codes from a file or output.
# Useful when copying fancy coloured output to non-tty environments.
# It can be used in two ways:
# 1. prompt$ command | rmcolour
# 2. prompt$ rmcolour file

RMCOLOUR='s/\x1B\[[0-9;]*[mK]//g'

if [ $# -eq 1 ]; then   # Reading from a file
    FILE="$1"
    sed -r ${RMCOLOUR} ${FILE}
else    # Reading from STDIN
    while read INPUT; do
        echo ${INPUT} | sed -r ${RMCOLOUR}
    done
fi
