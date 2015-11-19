# -*- sh-mode -*
# This should be sourced, not called.
set -e

# Directories.
root_dir=`pwd`

# Check which CI tool we are using
if `test x${CI_TOOL} = x`; then
  export CI_TOOL=travis
fi

# Since our gitlab-ci builder relies on docker we do not need sudo
if `test x${CI_TOOL} = xgitlab-ci`; then
  export SUDO_CMD=''
else
  if `test x${CI_REQUIRE_SUDO} != x`; then
    if `test x${CI_REQUIRE_SUDO} = xtrue`; then
      export SUDO_CMD='sudo'
    else
      export SUDO_CMD=''
    fi
  else
    export SUDO_CMD='sudo'
  fi
fi

# Check whether this is a PR build or not
# TODO Get this under gitlab-ci?
if `test x${TRAVIS_PULL_REQUEST} != x`; then
  export CI_PULL_REQUEST=${TRAVIS_PULL_REQUEST}
else
  export CI_PULL_REQUEST=false
fi

# Set the repo slug
if `test x${CI_TOOL} = gitlab-ci`; then
  export CI_REPO_SLUG=`echo ${CI_PROJECT_DIR}|sed -e's@/builds/@@'`
else
  export CI_REPO_SLUG=${TRAVIS_REPO_SLUG}
fi

# Get the branch
if `test x${CI_TOOL} = gitlab-ci`; then
  export CI_BRANCH=${CI_BUILD_REF_NAME}
else
  export CI_BRANCH=${TRAVIS_BRANCH}
fi

build_dir="/tmp/_ci/build"
install_dir="/tmp/_ci/install"

echo "root_dir: " $root_dir
echo "build_dir: " $build_dir
echo "install_dir: " $install_dir

# Check for CI_OS_NAME
if `test x${CI_OS_NAME} = x`; then
  if `test x${TRAVIS_OS_NAME} != x`; then
    export CI_OS_NAME=${TRAVIS_OS_NAME}
  else
    export CI_OS_NAME=linux
  fi
fi

# Shortcuts.
git_clone="git clone --quiet --recursive"

# Setup environment variables.
if [ -d /opt/ros ]; then
  . /opt/ros/${ROS_DISTRO}/setup.sh
fi

export LD_LIBRARY_PATH="$install_dir/lib:$LD_LIBRARY_PATH"
export LTDL_LIBRARY_PATH="$install_dir/lib:$LTDL_LIBRARY_PATH"
export PKG_CONFIG_PATH="$install_dir/lib/pkgconfig:$PKG_CONFIG_PATH"

if [[ ${CI_OS_NAME} = linux ]]; then
    export LD_LIBRARY_PATH="$install_dir/lib/`dpkg-architecture -qDEB_BUILD_MULTIARCH`:$LD_LIBRARY_PATH"
    export LTDL_LIBRARY_PATH="$install_dir/lib/`dpkg-architecture -qDEB_BUILD_MULTIARCH`:$LTDL_LIBRARY_PATH"
    export PKG_CONFIG_PATH="$install_dir/lib/`dpkg-architecture -qDEB_BUILD_MULTIARCH`/pkgconfig:$PKG_CONFIG_PATH"
fi

if type "python" > /dev/null; then
    pythonsite_dir=`python -c "import sys, os; print(os.sep.join(['lib', 'python' + sys.version[:3], 'site-packages']))"`
    export PYTHONPATH="$install_dir/$pythonsite_dir:$PYTHONPATH"
fi

if [[ ${CI_OS_NAME} = osx ]]; then
    # Since default gcc on osx is just a front-end for LLVM...
    if [[ ${CC} = gcc ]]; then
      export CXX=g++-4.8
      export CC=gcc-4.8
    fi
fi

# Make cmake verbose.
export CMAKE_VERBOSE_MAKEFILE=1
export CTEST_OUTPUT_ON_FAILURE=1

# Create layout.
mkdir -p "$build_dir"
mkdir -p "$install_dir"

# Add verbose handling
# More verbose handling for 'set -e'.
#
# Show a traceback if we're using bash, otherwise just a message.
# Downloaded from: https://gist.github.com/kergoth/3885825

on_exit () {
    ret=$?
    case $ret in
        0)
            ;;
        *)
            echo >&2 "Exiting with $ret from a shell command"
            ;;
    esac
}

on_error () {
    local ret=$?
    local FRAMES=${#BASH_SOURCE[@]}

    echo >&2 "Traceback (most recent call last):"
    for ((frame=FRAMES-2; frame >= 0; frame--)); do
        local lineno=${BASH_LINENO[frame]}

        printf >&2 '  File "%s", line %d, in %s\n' "${BASH_SOURCE[frame+1]}" "$lineno" "${FUNCNAME[frame+1]}"
        sed >&2 -n "${lineno}s/^[ 	]*/    /p" "${BASH_SOURCE[frame+1]}" || true
    done
    printf >&2 "Exiting with %d\n" "$ret"
    exit $ret
}

case "$BASH_VERSION" in
    '')
        trap on_exit EXIT
        ;;
    *)
        set -o errtrace
        trap on_error ERR
        ;;
esac
