#!/bin/bash
set -e
make clean
make
rm -f answer/*
name=(badbool badop comment reserve_op baddouble badpre define string badident badreserve ident badint badstring number)

for i in ${name[*]}
do
echo "RUNNING samples/${i}.frag"
./dcc < samples/${i}.frag 2>&1 | tee answer/${i}.frag 
done

for i in ${name[*]}
do
echo "DIFFERING samples/${i}.frag and samples/${i}.out"
diff -w -B answer/${i}.frag samples/${i}.out
done
