#!/bin/bash
#
# Setup SpaceVecAlg
#

cd "$build_dir"
git clone "https://github.com/jrl-umi3218/SpaceVecAlg.git" "$build_dir/sva"
cd "$build_dir/sva"
mkdir "$build_dir/build"
cd "$build_dir/build"
cmake .. -DCMAKE_INSTALL_PREFIX:STRING="$install_dir"
make
make install
