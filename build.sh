#!/bin/bash

PYTHON_NAME="python2";
PYTHON_SRC="${PYTHON_NAME}_src";
PYTHON_URL="https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz";
PYTHON_FILE=`basename $PYTHON_URL`;
PYTHON_VERSION=`basename $PYTHON_FILE .tgz`;

BASE=`pwd`;

mkdir $PYTHON_SRC 2> /dev/null;
cd $PYTHON_SRC;
# Download only if it does not exist
if [ ! -f `basename $PYTHON_URL` ]; then
	wget $PYTHON_URL;
	tar zxf $PYTHON_FILE;
fi
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
./configure --quiet --prefix=`readlink -f .`;
make --quiet
make --quiet install

# Create a symlink in the base directory
rm $BASE/$PYTHON_NAME 2> /dev/null;
ln -s `readlink -f ./bin/python` $BASE/$PYTHON_NAME;

# Go back to where we started
cd $BASE;
