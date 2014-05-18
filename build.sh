#!/bin/bash

PYTHON_NAME="python2";
PYTHON_SRC="${PYTHON_NAME}_src";
PYTHON_URL="https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz";
PYTHON_FILE=`basename $PYTHON_URL`;
PYTHON_VERSION=`basename $PYTHON_FILE .tgz`;

BASE=`pwd`;

rm -rf $PYTHON_SRC 2> /dev/null;
mkdir $PYTHON_SRC;
cd $PYTHON_SRC;
wget $PYTHON_URL;
tar zxfv $PYTHON_FILE;
cd $PYTHON_VERSION;

# Copy required source
cp -R $BASE/extra .
# Patch Python/ceval.c
patch Python/ceval.c < $BASE/patches/ceval.c.patch;
# Patch Modules/python.c
patch Modules/python.c < $BASE/patches/python.c.patch;
# Patch Makefile.pre.in
patch Makefile.pre.in < $BASE/patches/Makefile.pre.in.patch;

# Build
./configure --prefix=`readlink -f .`;
make
make install

# Create a symlink in the base directory
ln -s `readlink -f ./bin/python` $BASE/$PYTHON_NAME;

# Go back to where we started
cd $BASE;
