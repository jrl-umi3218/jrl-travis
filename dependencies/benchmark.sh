#!/bin/bash
#
# Setup Google Micro Benchmark Framework
#

cd "$build_dir"
git clone "https://github.com/google/benchmark.git" "$build_dir/benchmark"
cd "$build_dir/benchmark"
mkdir "$build_dir/build"
cd "$build_dir/build"
cmake .. -DCMAKE_INSTALL_PREFIX:STRING="$install_dir"
make
make install
