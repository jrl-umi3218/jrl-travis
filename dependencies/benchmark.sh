#!/bin/bash
#
# Setup Google Micro Benchmark Framework
#
. `dirname $0`/../common.sh

cd "$build_dir"
git clone "https://github.com/google/benchmark.git" "$build_dir/benchmark"
cd "$build_dir/benchmark"
mkdir -p "$build_dir/benchmark/_build"
cd "$build_dir/benchmark/_build"

cmake .. -DCMAKE_INSTALL_PREFIX:STRING="$install_dir"
make
make install
