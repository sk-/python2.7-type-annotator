#!/bin/bash

# run if user hits control-c
control_c() {
  echo -e "\nCancelled. User hit Ctrl+C.";
  exit 2;
}

check_return_code() {
	if [ "$?" != "0" ]; then
		echo 'Error:' $1 'failed'
		exit 1;
	fi
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

PYTHON_NAME="python2"
VIRTUALENV="${PYTHON_NAME}_env";
PYTHON_EXE=`readlink -f $PYTHON_NAME`;
BASE_INSTALL=`dirname $PYTHON_EXE`;

# Remove previous annotations
rm /tmp/python-types-* 2> /dev/null;

# Setup a virtualenv
rm -rf $VIRTUALENV 2> /dev/null;
mkdir $VIRTUALENV;
virtualenv -p $BASE_INSTALL/python $VIRTUALENV;
source $VIRTUALENV/bin/activate

# Run our own tests
python test_annotations/test_annotations.py;
check_return_code('test_annotations.py');

# Run python unittests.
python $BASE_INSTALL/Lib/test/regrtest.py;
check_return_code('Python test suite');

# Run numpy unittests.
pip install nose
pip install numpy
python -c 'import numpy; numpy.test()'
check_return_code('Numpy');

# Deactivate the virtualenv
deactivate

# Collect type information
sort -u /tmp/python-types-* | python remove_multiple.py > "${PYTHON_NAME}_annotations.tsv"
