#!/bin/bash

# Store the output of the qstat-gpu command
OUTPUT=$(qstat-gpu -lfu $USER)

# Extract the location value using grep and awk
LOCATION=$(echo "$OUTPUT" | grep -E '^    Location' | awk -F': ' '{print $2}')

# Append .pub.alcf.anl.gov to the location and print
echo "${LOCATION}.pub.alcf.anl.gov"
