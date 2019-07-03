#!/usr/bin/env bash

 # Just reading from stdin
while read -r -t 1 foo; do
    if [ "$foo" == "EXIT" ]; then
        echo "Found"
        exit 0
    fi
done
echo "Not found"
exit 1
