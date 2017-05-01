#!/bin/bash
#
# Setup RBDyn
#

cd "$build_dir"
git clone "https://github.com/jrl-umi3218/RBDyn.git" "$build_dir/rbdyn"
cd "$build_dir/rbdyn"
mkdir "$build_dir/build"
cd "$build_dir/build"
cmake .. -DCMAKE_INSTALL_PREFIX:STRING="$install_dir"
make
make install
