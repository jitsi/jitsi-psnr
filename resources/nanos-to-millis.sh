#!/bin/bash
while read nanos
do
  echo `expr $nanos / 1000000`
done < "${1:-/dev/stdin}"
