#!/bin/bash

set -e

[ -d "build/" ] && rm -r build 
mkdir build

echo "Building CPU implementations.."
for file in  cpu/*.cpp; do
    g++ $file -o "build/$(basename $file .cpp)_CPU"
    echo "Built $file "
done
echo "Done!"

echo "Building GPU implementations.."
for file in gpu/*.cu; do
   nvcc $file -o "build/$(basename $file .cu)_GPU"
   echo "Built $file "
done
echo "Done!"

echo "Building Testcase Generators ..."
for file in  test-generators/*.cpp; do
   g++ $file -o "build/$(basename $file .cpp)"
   echo "Built $file"
done
echo "Done!"
